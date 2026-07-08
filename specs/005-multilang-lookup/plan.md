# Implementation Plan: Multi-language transcript lookup & translation

**Branch**: `005-multilang-lookup` | **Date**: 2026-07-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/005-multilang-lookup/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

The transcript dictionary lookup sheet currently hard-caps the user's target language to either `en-US` or `zh-CN` (the only entries in `kSupportedNativeLanguageTags`). When a learner opens the sheet against a non-English / non-Chinese transcript (e.g., Korean), they cannot pick a meaningful target translation: only the two profile "native" choices are exposed, and the sheet cannot override the source either. This plan widens the lookup catalog to a separate `kSupportedLookupLanguageTags` (≥ 13 BCP-47 tags covering English, Chinese, Japanese, Korean, Spanish, French, German, Italian, Portuguese, Russian with US/GB, CN, JP, KR, ES/MX, FR/CA, DE, IT, BR/PT, RU regional variants) so both source and target can be picked freely inside the sheet, the worker payload still uses `workerLanguageBase` for backwards compatibility, and per-pair cache invalidation keeps stale results from leaking across language changes. No server contract changes; only the client catalog, picker UI, source/target resolution, and result cache are touched.

## Technical Context

**Language/Version**: Dart `^3.8` (per `pubspec.yaml`), Flutter stable channel. No toolchain upgrade required for this change.

**Primary Dependencies** (existing, no additions):
- `flutter_riverpod` + `riverpod_annotation` + `riverpod_generator` — lookup state, section async providers, result cache (`@Riverpod` / `@riverpod`).
- `package:logging` via `lib/core/logging/log.dart` — informational logging on swap / cache evict / worker-rejection paths.
- `flutter_localizations` + ARB — new `lookupLanguage*` labels added to `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb`.
- Enjoy worker `package:http` + `lib/data/api/services/ai/{translation_api,dictionary_api}.dart` — no shape change; just wider source / target inputs (`workerLanguageBase` already strips to base codes).

**Storage**: No Drift schema changes. The expanded language set is a compile-time constant catalog in `lib/core/application/app_language_catalog.dart`. The lookup result cache (`lib/features/lookup/application/lookup_sheet_result_cache.dart`) stays in-memory and is keyed on `LookupTranslationParams` / `LookupContextualParams` / `LookupDictionaryParams` value objects — both already include `sourceLanguage` / `targetLanguage` so the (source, target) pair is the cache key without a schema change.

**Testing**: `flutter test` for unit + widget coverage; `dart run build_runner build` for the existing generated `*.g.dart` files (no new `@riverpod` providers, but a sanity re-run is required after touching the catalog / resolver); `flutter analyze` for lint gate.

**Target Platform**: Android, iOS, macOS, Windows (per AGENTS.md / constitution § Flutter Quality Gates — no Flutter web).

**Project Type**: Flutter native mobile/desktop app (single `lib/` workspace; no packages split).

**Performance Goals**:
- Picker open to first non-loading option list: < 100 ms p95 on Windows desktop cold cache (SC-001).
- Translation section first result after a target change: < 2.5 s p95 on 50 Mbps connection (SC-002); same budget for dictionary + contextual-translation (SC-003).
- Swap → first section refresh starts within 50 ms of swap, no flicker of prior pair's content above the shimmer skeleton (SC-004).
- Zero regressions in playback, transcript scrolling, transport-bar responsiveness while the sheet is open (SC-006).

**Constraints**:
- Local-first / no Flutter web (AGENTS.md, ADR-0005).
- Single `media_kit` `Player` (ADR-0003, ADR-0015) — this change does not touch playback.
- All SQLite via Drift DAOs (ADR-0002) — this change adds no schema, so no DAO migration.
- All UI strings in ARB, all `print()` banned, all tappable UI uses `EnjoyTappableSurface` / `EnjoyButton` / `EnjoyTappableIcon` (conventions.md, ADR-0018).
- The lookup picker must keep the existing segmented control row layout — no new dialog / tabbed UI surface (QR-003).

**Scale/Scope**:
- 1 catalog file touched (`lib/core/application/app_language_catalog.dart`).
- 1 picker widget refactored (`lib/features/lookup/presentation/widgets/lookup_language_picker_row.dart`).
- 1 resolver updated (`lib/features/lookup/application/lookup_target_languages.dart`).
- 1 cache helper extended (`lib/features/lookup/application/lookup_sheet_result_cache.dart`).
- 1 test file extended (`test/features/lookup/lookup_target_languages_test.dart`) + new picker widget test.
- 2 ARB files updated (`lib/l10n/app_en.arb`, `lib/l10n/app_zh.arb`).
- 1 ADR added (`docs/decisions/0021-multi-language-lookup-catalog.md`).
- 1 feature doc updated (`docs/features/dictionary-lookup.md`).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Re-evaluation (post Phase 1 design)**: All five gates still pass. The research decisions resolved every Technical Context unknown; the contracts ([lookup-language-catalog.md](./contracts/lookup-language-catalog.md), [lookup-picker-ui.md](./contracts/lookup-picker-ui.md)) lock the change surface to existing feature folders + one new ADR; the data model ([data-model.md](./data-model.md)) keeps every domain entity UI-free and stays inside the existing `LookupRequest` / `LookupSheetResultCache` shape (no Drift migration). The complexity-tracking table remains empty. No exception required.

### I. Architecture and Code Quality

- All new code stays under `lib/features/lookup/{application,presentation}` and `lib/core/application`. No feature-to-feature shortcuts; the expanded catalog lives next to the existing `kSupportedNativeLanguageTags` / `kSupportedFocusLanguageTags` constants in `app_language_catalog.dart`. ✅
- Domain models (`LookupRequest`, `LookupTranslationParams`, `LookupContextualParams`, `LookupDictionaryParams`) remain pure Dart with no Flutter widget imports. ✅
- Persistence is unchanged (no Drift migration). ✅
- State orchestration stays in Riverpod (`@Riverpod(keepAlive: true)` for the result cache, `@riverpod` for section families). No new mutable global singleton; the picker state is per-sheet `StatefulWidget` state. ✅
- No `print()` calls. Log lines via `logNamed` (e.g. `logNamed('Lookup').info('pair swap ${prevPair} → ${nextPair}')`). ✅
- No `media_kit` `Player` instances created — this change does not touch playback. ✅

### II. Testing Defines the Contract

Automated tests required:
- Unit: `test/features/lookup/lookup_target_languages_test.dart` — extended for each new `kSupportedLookupLanguageTags` entry (`canonicalLookupTag`), `resolveLookupSourceOverride` for `und` / empty / unsupported / denylisted primaries, `resolveLookupTarget` when stored native is **not** in the expanded list (falls back to first allowed ≠ source ≠ learning), `sortLookupLanguages` ordering (learning first, then alphabetical by primary subtag + region), `LookupSheetResultCache.evictForPair` round-trip.
- Widget: `test/features/lookup/lookup_language_picker_row_test.dart` (new) — mount the picker with `sourceLanguage = ko-KR`, tap source / target pills, confirm bottom-sheet options list contains every entry in `kSupportedLookupLanguageTags`, and that the swap control toggles correctly.
- Build: `dart run build_runner build` (re-run after touching the catalog; no new `@riverpod` providers, but a sanity pass avoids drift in the generated `*.g.dart`).
- Gate: `flutter analyze`, `flutter test test/features/lookup/`, `flutter test` (full suite for regressions).

Manual verification rationale: subjective visual polish on the picker bottom-sheet (e.g. chevron alignment, ripple) — Constitution Principle II explicitly allows this when automation is impractical. Documented in `quickstart.md` § Cross-platform visual consistency.

### III. User Experience Consistency

- New per-language labels live in ARB under `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb` (FR-011). Existing `lookupSourceLanguage`, `lookupTargetLanguage`, `lookupSwapLanguages`, `lookupPickSourceTitle`, `lookupPickTargetTitle`, `lookupCloudRequiresSignIn`, `lookupErrorRetry` are unchanged.
- Tappable controls continue to use `EnjoyTappableSurface` (per ADR-0018); `LookupLanguagePickerRow` already routes through `showLanguageChoiceSheet` / `LanguageChoiceOption`, no new touch targets introduced.
- Tooltips + keyboard affordances preserved (the existing `Tooltip` on the swap control, the 44 × 44 icon buttons, and the `languageChoiceSheet` keyboard navigation remain unchanged).
- `docs/features/dictionary-lookup.md` updated in the same change (FR-005, QR-005).

### IV. Performance Is a Requirement

- Picker bottom-sheet option list pre-sorted on read (`sortLookupLanguages` returns a pre-built `List<String>`), so the first frame after the sheet opens contains the full ordered list with no per-item recomputation (SC-001).
- Section async providers use the existing `@riverpod` family pattern; switching source / target produces a new params struct, so Riverpod cancels the prior in-flight future before resolving the new one — no extra cost on swap (FR-006, SC-004).
- Result cache hits skip the network round-trip; cache key includes both language tags (FR-010) so widening the catalog does not change hit rate for existing en-US / zh-CN pairs.
- Heavy work stays off the UI isolate: catalog sort is O(n) over ~13 entries; cache lookup is O(1) hash; nothing in this change runs palette / image / transcript work.
- Windows desktop (slowest target) cold-cache budget: picker open < 100 ms, swap → refresh start < 50 ms — both measured in `quickstart.md`.

### V. Documentation and Traceability

- New ADR: `docs/decisions/0021-multi-language-lookup-catalog.md` covering catalog separation rationale, first-wave tag list, default-target fallback, no-persistence-per-sheet rule (inherited from ADR-0019), and the worker-contract decision to keep `workerLanguageBase` (FR-007). Required by QR-005 before implementation begins.
- Feature doc: `docs/features/dictionary-lookup.md` updated with the new "Languages" subsection (catalog name, ordering, default-target resolution, swap behaviour, cache key, worker-rejection error handling) — matches QR-005.
- Agent guidance: `AGENTS.md` updated to call out `kSupportedLookupLanguageTags` next to the existing catalog references, so future lookup changes see the new constant in the same place.
- No constitution exception required.

## Project Structure

### Documentation (this feature)

```text
specs/005-multilang-lookup/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   ├── lookup-language-catalog.md
│   └── lookup-picker-ui.md
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── core/
│   └── application/
│       └── app_language_catalog.dart        # +kSupportedLookupLanguageTags, +kLookupLanguageLabels entries, +sortLookupLanguages
├── features/
│   └── lookup/
│       ├── application/
│       │   ├── lookup_target_languages.dart # +resolveLookupSourceOverride, extended resolveLookupTarget fallback
│       │   └── lookup_sheet_result_cache.dart # +evictForPair(source, target)
│       └── presentation/
│           └── widgets/
│               └── lookup_language_picker_row.dart # switch option source to kSupportedLookupLanguageTags
├── l10n/
│   ├── app_en.arb                            # +per-language labels
│   └── app_zh.arb                            # +per-language labels
└── data/
    └── api/services/ai/                      # no change (worker contract preserved via workerLanguageBase)

test/
├── features/
│   └── lookup/
│       ├── lookup_target_languages_test.dart # extended cases
│       └── lookup_language_picker_row_test.dart # new widget test
└── widget_test.dart                          # no change

integration_test/
└── multilang_lookup_test.dart                # not added — coverage at unit + widget level sufficient

docs/
├── features/
│   └── dictionary-lookup.md                  # Languages section rewrite
└── decisions/
    └── 0021-multi-language-lookup-catalog.md # new ADR

AGENTS.md                                     # +kSupportedLookupLanguageTags reference
```

**Structure Decision**: Reuse the existing `lib/features/lookup/` slice, extending only the catalog, picker widget, resolver, and result-cache file. No new feature folder; the change is a behavior + UX widening inside an established slice. New unit + widget tests live next to the existing lookup test suite. New ADR lives in the existing `docs/decisions/` folder alongside ADR-0019 (the original lookup feature). ARB additions follow the existing `app_en.arb` / `app_zh.arb` convention. No new package or layer is introduced.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitution violations. No row added.