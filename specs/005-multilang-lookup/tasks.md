---
description: "Task list for multi-language transcript lookup & translation"
---

# Tasks: Multi-language transcript lookup & translation

**Input**: Design documents from `/specs/005-multilang-lookup/`
- [spec.md](./spec.md) — User Story 1 (P1), User Story 2 (P2), User Story 3 (P3)
- [plan.md](./plan.md) — Technical Context, Constitution Check, change surface
- [research.md](./research.md) — 8 resolved unknowns (catalog separation, first-wave tags, default fallback, worker payload, cache invalidation, picker UI, testing, docs)
- [data-model.md](./data-model.md) — `LookupLanguageTag`, `LookupLanguagePair`, `LookupSourceOverride`, `LookupTargetOverride`, `LookupSheetResultCache.evictForPair`, `resolveLookupSourceOverride`, `sortLookupLanguages`
- [contracts/lookup-language-catalog.md](./contracts/lookup-language-catalog.md), [contracts/lookup-picker-ui.md](./contracts/lookup-picker-ui.md) — Catalog invariants + picker UI contract
- [quickstart.md](./quickstart.md) — 9 validation scenarios (manual + automated)

**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: Automated tests are required for changed behavior (Constitution Principle II). All catalog / resolver / cache / picker changes have unit + widget tests; subjective visual polish is documented as manual verification per quickstart.md § 8.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Feature code**: `lib/features/lookup/{application,data,domain,presentation}/`
- **Shared catalog**: `lib/core/application/app_language_catalog.dart`
- **Tests**: `test/features/lookup/`, `test/core/application/`
- **Feature docs**: `docs/features/dictionary-lookup.md`
- **ADRs**: `docs/decisions/0021-multi-language-lookup-catalog.md`
- **Localization**: `lib/l10n/app_en.arb`, `lib/l10n/app_zh.arb`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, ADR skeleton, localization placeholder keys

- [x] T001 Confirm feature-first paths and change surface per [plan.md § Project Structure](./plan.md#project-structure): `lib/features/lookup/`, `lib/core/application/app_language_catalog.dart`, `lib/l10n/`, `docs/decisions/`, `docs/features/dictionary-lookup.md`, `AGENTS.md`. Verify each path exists before implementation.
- [x] T002 [P] Draft ADR `docs/decisions/0021-multi-language-lookup-catalog.md` (Status: Draft) covering: catalog separation rationale, first-wave tag list, default-target fallback, no-persistence-per-sheet rule (inherited from ADR-0019), worker contract decision to keep `workerLanguageBase`. Use ADR-0019 as the structural template.
- [x] T003 [P] Add lookupLanguage* ARB placeholders to `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb` — one key per first-wave tag (English, English (UK), 中文, 日本語, 한국어, Español (España), Español (México), Français (France), Français (Canada), Deutsch, Italiano, Português (Brasil), Português (Portugal), Русский) — both en + zh values inline. Existing `lookup*` keys remain unchanged.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Catalog, resolver, result-cache extensions that MUST be complete before any user story work begins

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Add `kSupportedLookupLanguageTags` constant + extend `kLookupLanguageLabels` map in `lib/core/application/app_language_catalog.dart` with the 14 first-wave tags (`en-US`, `en-GB`, `zh-CN`, `ja-JP`, `ko-KR`, `es-ES`, `es-MX`, `fr-FR`, `fr-CA`, `de-DE`, `it-IT`, `pt-BR`, `pt-PT`, `ru-RU`) per [contracts/lookup-language-catalog.md](./contracts/lookup-language-catalog.md) and [data-model.md § LookupLanguageTag](./data-model.md#lookuplanguagetag-catalog-entry-pure-dart). Preserve existing `kSupportedNativeLanguageTags` / `kSupportedFocusLanguageTags` untouched.
- [x] T005 Add `sortLookupLanguages(List<String> tags, {required String learningTag})` helper in `lib/core/application/app_language_catalog.dart` per [data-model.md § sortLookupLanguages](./data-model.md#sortlookuplanguages-new-pure-logic): learning-first, then alphabetical by primary subtag, then by region. Pure function, stable for ties.
- [x] T006 Add `resolveLookupSourceOverride(String? override)` helper in `lib/features/lookup/application/lookup_target_languages.dart` (per [data-model.md § resolveLookupSourceOverride](./data-model.md#resolookupsourceoverride-new-pure-logic)) — returns `null` for empty / whitespace / `und` / `mul` / `mis` / `zxx`; otherwise returns `normalizeBcp47Tag(override)`. Also extend `resolveLookupTarget` so a stored native not in `kSupportedLookupLanguageTags` falls back via primary-subtag match to a lookup entry, then to the first non-equal / non-learning entry per [data-model.md § resolveLookupTarget (extended)](./data-model.md#resolookuptarget-extended-pure-logic).
- [x] T007 Add `evictForPair({required String sourceLanguage, required String targetLanguage})` method to `LookupSheetResultCache` in `lib/features/lookup/application/lookup_sheet_result_cache.dart` per [data-model.md § LookupSheetResultCache (extended)](./data-model.md#lookupsheetresultcache-extended-application-state). Removes every entry whose `sourceLanguage == sourceLanguage && targetLanguage == targetLanguage` from both the contextual and dictionary maps.
- [x] T008 Write catalog invariant test in `test/core/application/lookup_catalog_test.dart` (new file) per [data-model.md § Validation summary](./data-model.md#validation-summary): assert `kSupportedLookupLanguageTags` and `kLookupLanguageLabels` agree (same key set), no entry is in `kInvalidLanguageTags`, every entry round-trips through `normalizeBcp47Tag` + `workerLanguageBase`. Test fails before T004 lands → must be red initially.
- [x] T009 Extend `test/features/lookup/lookup_target_languages_test.dart` with cases per [data-model.md § Validation summary](./data-model.md#validation-summary): `canonicalLookupTag` for each new lookup tag, `resolveLookupSourceOverride` rejects `und` / empty / `mul`, `resolveLookupTarget` falls back when stored native is `de-AT` (primary-subtag match to `de-DE`) / `fr-CH` (primary-subtag match to `fr-FR`) / `en-XX` (in list), `sortLookupLanguages` ordering (learning first, then alphabetical). Existing cases for en-US / zh-CN must continue to pass. Tests fail before T005 + T006 land → must be red initially.
- [x] T010 Add unit test for `LookupSheetResultCache.evictForPair` in `test/features/lookup/lookup_sheet_result_cache_test.dart` (new file): seed cache with three distinct pairs, call `evictForPair` on one pair, assert only the matching pair's entries are removed and other pairs are intact. Test fails before T007 lands → must be red initially.
- [x] T011 Run `dart run build_runner build` (sanity re-run after catalog touch; no new `@riverpod` providers expected but avoids generated-code drift), then `flutter analyze` and `flutter test test/features/lookup/ test/core/application/`. Resolve any analyzer warning introduced by T004–T010 before opening Phase 3.

**Checkpoint**: Foundation ready — catalog + resolver + cache extensions in place, tests green.

---

## Phase 3: User Story 1 — Pick any target language for a Korean transcript lookup (Priority: P1) 🎯 MVP

**Goal**: User selects a Korean word on a transcript cue, opens the lookup sheet, and can pick **any** of the 14 first-wave target languages (English, Chinese, Japanese, Korean, Spanish, French, German, Italian, Portuguese, Russian with regional variants) — not just English / Chinese.

**Independent Test**: Per [quickstart.md § 1, § 2](./quickstart.md#1-korean--any-target-picker-expansion-sc-001-fr-001--fr-003): import media with a Korean transcript track, select a Korean word, confirm the target pill picker offers all 14 entries, pick Japanese, confirm translation / dictionary / contextual-translation sections all return Japanese content. Worker payloads use `workerLanguageBase` (`source = ko`, `target = ja`).

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T012 [P] [US1] Widget test in `test/features/lookup/lookup_language_picker_row_test.dart` (new file): mount `LookupLanguagePickerRow` with `sourceLanguage = ko-KR` / `targetLanguage = en-US`, tap the target pill, assert the bottom-sheet option list contains all 14 entries from `kSupportedLookupLanguageTags` in `sortLookupLanguages` order (learning first), and that the user's stored native preference is highlighted when in the lookup list. Test fails before T014 lands → must be red initially.
- [x] T013 [P] [US1] Widget test in `test/features/lookup/lookup_language_picker_row_test.dart`: mount `DictionaryLookupSheet` with `sourceLanguage = ko-KR` / `targetLanguage = ja-JP`, expand the dictionary + contextual sections to populate cache, tap the swap control, assert that `LookupSheetResultCache.evictForPair(ko-KR, ja-JP)` was called and the prior pair's results are not observable above the shimmer skeletons. Test fails before T015 lands → must be red initially.

### Implementation for User Story 1

- [x] T014 [US1] Switch `LookupLanguagePickerRow` option source from `kSupportedNativeLanguageTags` to `kSupportedLookupLanguageTags` (via `sortLookupLanguages` with the sheet's current `learningTag`) in `lib/features/lookup/presentation/widgets/lookup_language_picker_row.dart` per [contracts/lookup-picker-ui.md § 1, § 2, § 3](./contracts/lookup-picker-ui.md). Update the auto-switch-target-when-source-picks-current-target branch to iterate the lookup list. Use `EnjoyTappableSurface` for the segment tappables; preserve the 44 px tap target, `Tooltip` on swap, 28%-alpha vertical divider, and segmented control row layout. Depends on T004, T005.
- [x] T015 [US1] Wire `LookupSheetResultCache.evictForPair(prevSource, prevTarget)` in `DictionaryLookupSheet` in `lib/features/lookup/presentation/dictionary_lookup_sheet.dart` before each `setState` on `_sourceLanguage` / `_targetLanguage` change and before the swap control's `setState` so stale results from the prior pair cannot render above the new pair's shimmer skeletons (FR-006, FR-010, SC-004). Depends on T007, T014.
- [x] T016 [US1] Verify `AuthRequiredCallout` is shown for **all** expanded lookup languages (not just en-US / zh-CN) in `lib/features/lookup/presentation/sections/{translation,dictionary,contextual_translation}_lookup_section.dart`. The surface enum (`AuthRequiredSurface.lookupTranslation`, etc.) is already language-agnostic; this task is a verification pass that confirms no language-gated code path was added. If any gating is found, remove it. Depends on T014.
- [x] T017 [US1] Add `package:logging` instrumentation via `logNamed('Lookup')` in `lib/features/lookup/application/transcript_lookup_open.dart` and `lib/features/lookup/presentation/dictionary_lookup_sheet.dart`: log pair changes (`'lookup pair ${prev} → ${next}'` at info level) and worker rejections (`'lookup worker rejected pair ${pair}: ${error}'` at warning level). No `print()`. Depends on T014.

**Checkpoint**: User Story 1 fully functional — user can pick any target language from the 14-entry list, swap is atomic with cache eviction, all three sections return content in the chosen target.

---

## Phase 4: User Story 2 — Override the source language inside the sheet (Priority: P2)

**Goal**: When the active transcript track has no language metadata (`und`, `null`, `''`, `zxx`), the user can explicitly pick a source language from the same 14-entry list so that lookup doesn't silently fall back to a wrong-language default.

**Independent Test**: Per [quickstart.md § 3](./quickstart.md#3-source-override-for-und--missing-track-language-fr-005-fr-006): import media with `und` transcript track, select a word, confirm source pill defaults to learning language but is tappable, pick French, confirm swap control reflects new pair, next section refresh sends `source = fr` to the worker.

### Tests for User Story 2

- [x] T018 [P] [US2] Unit test in `test/features/lookup/lookup_target_languages_test.dart`: `resolveLookupSourceOverride` for `und`, empty string, whitespace-only, `mul`, `mis`, `zxx`, valid `ko-KR`, legacy alias `kor`. Existing cases continue to pass. Test fails before T006 → already red (covered by T009); this task adds the explicit US2 cases for the override entry point only. Depends on T009.
- [x] T019 [P] [US2] Widget test in `test/features/lookup/lookup_language_picker_row_test.dart`: mount `DictionaryLookupSheet` with `sourceLanguage = ko-KR` / `targetLanguage = ja-JP`, swap to `sourceLanguage = ja-JP` / `targetLanguage = ko-KR`, expand dictionary to seed cache, assert `LookupSheetResultCache.evictForPair(ko-KR, ja-JP)` was called and the cache for the new pair is empty before the new section refresh resolves. Depends on T013, T015.

### Implementation for User Story 2

- [x] T020 [US2] Verify `openTranscriptLookup` in `lib/features/lookup/application/transcript_lookup_open.dart` threads the active transcript track language through `resolveLookupSource` correctly when the track is `und` (existing fallback to learning tag preserved per FR-005). Add a debug-level log via `logNamed('Lookup')` that records the resolved source so the override-vs-default distinction is observable in logs. Depends on T017.
- [x] T021 [US2] Wire source pill override path in `DictionaryLookupSheet` in `lib/features/lookup/presentation/dictionary_lookup_sheet.dart`: when the user picks a new source via the source pill, call `resolveLookupSourceOverride(picked)` — if it returns non-null, use it as `_sourceLanguage` and evict the prior pair via `evictForPair`; if it returns null (invalid / empty / `und` selection), fall back to `resolveLookupSource(activeTrack.language, learningTag)` and surface a brief `AppNotice.info` ("Source language reset to learning default"). Depends on T006, T015.

**Checkpoint**: User Story 2 fully functional — source override works for `und` tracks; swap atomicity + cache eviction guarantee no cross-pair leakage.

---

## Phase 5: User Story 3 — Default behavior preserved for en-US / zh-CN users (Priority: P3)

**Goal**: 100% parity with the pre-change lookup behaviour for users whose stored native preference and learning language are both in the original narrow set (`en-US` / `zh-CN`). No regression in profile / settings pickers, no silent default change.

**Independent Test**: Per [quickstart.md § 4](./quickstart.md#4-default-behaviour-preserved-for-en-us--zh-cn-users-sc-005): with stored native = `zh-CN`, learning = `en-US`, Korean transcript — open a fresh lookup sheet, confirm source = "한국어", target = "中文", worker payloads use `source = ko` / `target = zh`.

### Tests for User Story 3

- [x] T022 [P] [US3] Extend `test/features/lookup/lookup_target_languages_test.dart` with explicit parity cases per [data-model.md § Validation summary](./data-model.md#validation-summary): `resolveLookupTarget('en-US', learningTag: 'zh-CN')` returns `'en-US'`; `resolveLookupTarget('zh-CN', learningTag: 'en-US')` returns `'zh-CN'`; `resolveLookupTarget(null, learningTag: 'en-US')` returns `'zh-CN'` (existing `coerceNativeIfEqualsLearning` behaviour); `resolveLookupSource('und', learningTag: 'en-US')` returns `'en-US'`; `resolveLookupSource('ko-KR', learningTag: 'en-US')` returns `'ko-KR'`. All cases must match the pre-change expected values exactly. Depends on T009.
- [x] T023 [P] [US3] Run full `flutter test` suite per [quickstart.md § Setup / Automated checks](./quickstart.md#automated-checks): assert zero new failures in `test/features/lookup/`, `test/features/settings/`, `test/features/auth/`, and any other touched-area suite. Document any pre-existing flakes separately; new failures must block. Depends on T011, T022.

### Implementation for User Story 3

- [x] T024 [US3] No new implementation — US3 is covered by Phase 2's `resolveLookupTarget` / `resolveLookupSource` parity preservation. Verification task only: confirm via T022 + T023 that the existing en-US / zh-CN default-target + learning-fallback behavior is byte-identical to the pre-change contract. Manual cross-check against [quickstart.md § 4](./quickstart.md#4-default-behaviour-preserved-for-en-us--zh-cn-users-sc-005) with a real Korean video import + the en/zh profile pair. Depends on T022, T023.

**Checkpoint**: User Stories 1, 2, AND 3 all work independently — P1 delivers the bug fix, P2 adds source override, P3 confirms zero regression for existing users.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation updates, ADR finalization, full quality gates

- [x] T025 [P] Finalize ADR `docs/decisions/0021-multi-language-lookup-catalog.md` (Status: Draft → Accepted) after the implementation lands and Phase 2 + 3 + 4 tests are green. Add a "Consequences" section listing the explicit behavior changes (catalog expanded; picker widened; source overridable; per-pair cache key; no persistence; no worker contract change) and link the spec.md / plan.md / data-model.md / contracts/ artifacts.
- [x] T026 [P] Update `docs/features/dictionary-lookup.md` Languages section per [plan.md § V. Documentation and Traceability](./plan.md#v-documentation-and-traceability) + [contracts/lookup-language-catalog.md](./contracts/lookup-language-catalog.md) + [contracts/lookup-picker-ui.md](./contracts/lookup-picker-ui.md): replace the existing "Languages" subsection with the new catalog name (`kSupportedLookupLanguageTags`), the 14-entry first-wave list, the default-target resolution algorithm (stored native → primary-subtag fallback → first non-equal non-learning entry), swap atomicity + cache key, and worker-rejection error handling. Preserve the rest of the file.
- [x] T027 [P] Update `AGENTS.md` "Hard rules" / "MVP scope" section to call out `kSupportedLookupLanguageTags` next to the existing catalog references (per [plan.md § Project Structure](./plan.md#project-structure)). One-line addition, no other changes.
- [x] T028 Run `dart run build_runner build` (final sanity) and `flutter gen-l10n` (re-generate `AppLocalizations` after ARB additions from T003).
- [x] T029 Run `flutter analyze` — zero new warnings introduced.
- [x] T030 Run `flutter test` (full suite) — all pre-existing tests still green + all new tests from T008–T023 green.
- [x] T031 Run quickstart.md validation scenarios § 1 through § 9 per [quickstart.md](./quickstart.md). Document pass / fail per scenario in the PR description; any failure blocks release. Manual verification per Constitution Principle II for subjective visual polish (scenario § 8).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion — **BLOCKS all user stories**. T004–T007 must land before any user story work; their tests (T008–T010) must be red → green before opening Phase 3.
- **User Story 1 (Phase 3)**: Depends on Foundational (T004–T007). T014 depends on T004 + T005; T015 depends on T007 + T014; T016–T017 depend on T014.
- **User Story 2 (Phase 4)**: Depends on Foundational (T006, T007) and User Story 1 (T015) — shares the picker widget + cache eviction wiring.
- **User Story 3 (Phase 5)**: Depends on Foundational (T006) and User Story 1's parity check — implementation is verification-only.
- **Polish (Phase 6)**: Depends on all three user stories complete (T024).

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) — no dependencies on other stories.
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) — depends on T015 from US1 for the picker + sheet wiring, but is independently testable.
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) — depends on T009 + T022 from Phase 2 / Phase 5 itself; verification-only.

### Within Each User Story

- Tests (T012, T013, T018, T019, T022) MUST be written and FAIL before implementation lands.
- Catalog (T004–T005) before picker (T014).
- Resolver + cache (T006–T007) before sheet wiring (T015, T021).
- All implementation before integration / verification (T024, T031).

### Parallel Opportunities

- **Phase 1**: T002 (ADR draft) and T003 (ARB additions) can run in parallel — different files.
- **Phase 2**: T004–T005 (catalog touch) must be sequential within `app_language_catalog.dart`; T006 (resolver) and T007 (cache) are independent and can run in parallel with T004. T008–T010 (test files) are independent and can run in parallel with each other once their corresponding impl lands.
- **Phase 3**: T012 + T013 (test files) can run in parallel with T014 + T015 (impl) — different files. T016 + T017 can run in parallel with each other (different files).
- **Phase 4**: T018 + T019 (tests) can run in parallel with each other. T020 + T021 can run in parallel with each other after T015 + T017 land.
- **Phase 5**: T022 + T023 can run in parallel. T024 is verification-only.
- **Phase 6**: T025 + T026 + T027 (docs) can run in parallel. T028–T031 are sequential quality gates.

---

## Parallel Example: User Story 1

```bash
# Launch tests + impl together (different files):
Task: "T012 widget test for LookupLanguagePickerRow option list in test/features/lookup/lookup_language_picker_row_test.dart"
Task: "T013 widget test for swap + cache eviction in test/features/lookup/lookup_language_picker_row_test.dart"
Task: "T014 switch option source in lib/features/lookup/presentation/widgets/lookup_language_picker_row.dart"
Task: "T015 wire evictForPair in lib/features/lookup/presentation/dictionary_lookup_sheet.dart"
Task: "T016 verify AuthRequiredCallout covers all lookup languages in lib/features/lookup/presentation/sections/*_lookup_section.dart"
Task: "T017 add logNamed instrumentation in lib/features/lookup/application/transcript_lookup_open.dart + dictionary_lookup_sheet.dart"

# After T014 + T015 land, T016 + T017 can each run in parallel:
Task: "T016 verify AuthRequiredCallout"
Task: "T017 add package:logging instrumentation"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T003).
2. Complete Phase 2: Foundational (T004–T011) — **CRITICAL**, blocks all stories.
3. Complete Phase 3: User Story 1 (T012–T017).
4. **STOP and VALIDATE**: run `flutter test test/features/lookup/`, then run quickstart.md § 1 + § 2 manually with a Korean video import. Confirm Korean → Japanese / Spanish / French translations work end-to-end.
5. Ship / demo if ready — the original bug (Korean → English-only / Chinese-only lookup) is fixed.

### Incremental Delivery

1. Complete Phase 1 + Phase 2 → Foundation ready.
2. Add User Story 1 → test independently → ship / demo (**MVP** — fixes the reported bug).
3. Add User Story 2 → test independently → ship / demo (source override for `und` tracks).
4. Add User Story 3 → test independently (regression suite only) → ship / demo (parity guarantee).
5. Each story adds value without breaking previous stories.

### Parallel Team Strategy

With multiple developers:

1. Team completes Phase 1 + Phase 2 together (small surface area — single file each for T004 / T005 / T006 / T007, plus three test files).
2. Once Phase 2 lands:
   - Developer A: User Story 1 (picker + sheet + auth verification + logging) — T012–T017.
   - Developer B: User Story 2 (source override + swap verification) — T018–T021 (starts after T015 from Developer A).
   - Developer C: User Story 3 (regression tests) — T022–T024 (independent of A and B once T009 lands).
3. Stories complete and integrate independently — picker widening (US1) is the only shared surface, so Developer B's T019 / T021 are sequenced after Developer A's T015 lands.

---

## Notes

- [P] tasks = different files, no dependencies.
- [Story] label maps task to specific user story for traceability.
- Each user story is independently completable and testable.
- All catalog / resolver / cache / picker changes have unit + widget tests; subjective visual polish is documented manual verification per quickstart.md § 8.
- Commit after each task or logical group (T004–T007 as one logical commit on the catalog + cache; T014–T017 as one on the picker + sheet).
- Stop at any checkpoint to validate story independently.
- Avoid: vague tasks, same-file conflicts (T004–T005 touch `app_language_catalog.dart` — keep them sequential within the same commit), cross-story dependencies that break independence.
