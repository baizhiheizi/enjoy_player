# Tasks: Craft History & First-Class Entry

**Input**: Design documents from `/specs/029-craft-history-home/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included — constitution and plan require automated coverage for behavior changes.

**Organization**: Tasks are grouped by user story (US1–US5). Shared l10n lands in Foundational so Home, hotkey, and history can proceed without string blockers.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Maps to spec user stories (US1–US5)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Feature branch and confirm design artifacts.

- [x] T001 Create and checkout branch `029-craft-history-home` from current `main` (`git checkout -b 029-craft-history-home`)
- [x] T002 Confirm design docs exist under `specs/029-craft-history-home/` (`spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared localization keys and generated l10n used by every story. No UI wiring yet beyond ARBs.

**CRITICAL**: No user story work begins until this phase is complete.

- [x] T003 [P] Add/update Craft entry & history ARB keys in `lib/l10n/app_en.arb`: `homeCraftAction`, `hotkeysDescCraft`, `craftHistoryTooltip`, `craftHistoryTitle`, `craftHistoryEmptyTitle`, `craftHistoryEmptyHint`, `craftHistoryEmptyAction`, `craftEditUnavailable` per `specs/029-craft-history-home/contracts/localization-branding.md`
- [x] T004 [P] Add matching ZH strings in `lib/l10n/app_zh.arb` and `lib/l10n/app_zh_CN.arb` (product noun Latin **Craft**; history copy per C3)
- [x] T005 [P] Update product-face ZH keys in `lib/l10n/app_zh.arb` and `lib/l10n/app_zh_CN.arb`: `craftScreenTitle` → `Craft`, `libraryProviderCraftBadge` → `Craft`, `importCraftFromText` → `Craft…` (do not change `craftAction` 合成)
- [x] T006 Run `flutter gen-l10n` and verify generated getters exist in `lib/l10n/app_localizations*.dart`

**Checkpoint**: Shared strings ready — US1–US5 can start (US1 + US2 in parallel after this).

---

## Phase 3: User Story 1 — Open Craft from Home (Priority: P1) 🎯 MVP

**Goal**: Home header shows Craft next to Import; tapping opens `/craft` without the import chooser.

**Independent Test**: On Home, tap Craft → Craft Studio opens; Import still works via its own button.

### Tests for User Story 1

- [x] T007 [P] [US1] Add/extend widget test in `test/features/library/presentation/home_screen_test.dart` (or new `home_craft_entry_test.dart`) asserting Craft + Import trailing actions and that Craft navigates to `/craft`

### Implementation for User Story 1

- [x] T008 [US1] Change `EditorialHeader.trailing` on Home (data + loading paths) in `lib/features/library/presentation/home_screen.dart` to a `Row` with Craft control (`l10n.homeCraftAction` → `context.push('/craft')`) then existing Import `FilledButton.icon`
- [x] T009 [US1] Confirm Import chooser Craft row remains in `lib/features/library/presentation/library_actions.dart` using updated `importCraftFromText` label

**Checkpoint**: MVP — Craft is first-class from Home.

---

## Phase 4: User Story 2 — Hotkey `c` opens Craft (Priority: P1)

**Goal**: Global bare `c` opens Craft when shortcuts are allowed; discoverable/rebindable; no-op if already on Craft.

**Independent Test**: From Home (no text focus) press `c` → Craft; in a text field press `c` → types letter; shortcuts help lists Craft.

### Tests for User Story 2

- [x] T010 [P] [US2] Add unit/widget coverage for `global.craft` default binding in `test/features/hotkeys/` (definition present, `defaultKeys: 'c'`, description maps to `hotkeysDescCraft`)

### Implementation for User Story 2

- [x] T011 [P] [US2] Register `HotkeyDefinition(id: 'global.craft', defaultKeys: 'c', descriptionKey: 'craft', scope: HotkeyScope.global)` in `lib/features/hotkeys/domain/hotkey_definitions.dart`
- [x] T012 [P] [US2] Map `descriptionKey: 'craft'` → `l10n.hotkeysDescCraft` in `lib/features/hotkeys/presentation/hotkeys_description.dart`
- [x] T013 [US2] Dispatch `global.craft` in `lib/features/hotkeys/presentation/app_hotkeys_keyboard_listener.dart`: if path already `/craft` (or `/craft/...`) consume/no-op; else `goRouter.go('/craft')` (respect existing text-field focus guard)

**Checkpoint**: US1 + US2 deliver first-class entry (click + key).

---

## Phase 5: User Story 3 — Browse Craft history (Priority: P2)

**Goal**: From Craft Studio, open a Craft-only history list (recency order) with empty state.

**Independent Test**: With mixed library, history shows only Craft items newest-first; with zero Craft items, empty state offers path back to create. (Tap→edit wired in US4.)

### Tests for User Story 3

- [x] T014 [P] [US3] Add provider/unit test for Craft-only filter + `updatedAt` desc sort in `test/features/craft/application/craft_history_provider_test.dart` (or under `test/features/library/`)
- [x] T015 [P] [US3] Add widget test for history empty + populated list in `test/features/craft/presentation/craft_history_test.dart`

### Implementation for User Story 3

- [x] T016 [US3] Add `craftHistoryProvider` in `lib/features/craft/application/craft_history_provider.dart` watching library media, filtering `provider == 'craft'`, sorting by `updatedAt` descending
- [x] T017 [US3] Add history UI in `lib/features/craft/presentation/craft_history_screen.dart` (or sheet) with `EnjoyPage` title `craftHistoryTitle`, list tiles (label/snippet), `EmptyState` using empty l10n keys + CTA back to create
- [x] T018 [US3] Register route `/craft/history` in `lib/core/routing/app_router.dart` (child or sibling of `/craft` per go_router patterns)
- [x] T019 [US3] Add history `IconButton` to `EnjoyPage.actions` in `lib/features/craft/presentation/craft_screen.dart` with tooltip `craftHistoryTooltip` navigating to history

**Checkpoint**: History browse works; selection may be stubbed until US4.

---

## Phase 6: User Story 4 — Edit from history & update same item (Priority: P2)

**Goal**: Select history item → prefilled Craft edit session → regenerate/save updates the **same** media id.

**Independent Test**: Open item from history, change text, regenerate, save → one library item with updated audio; history reflects update.

### Tests for User Story 4

- [x] T020 [P] [US4] Add repository tests for `updateCraftedFromText` in `test/features/library/library_repository_craft_test.dart` (same id returned; non-craft/missing fails; transcript/audio fields updated)
- [x] T021 [P] [US4] Add `CraftController` tests in `test/features/craft/application/craft_controller_test.dart` for `loadForEdit` prefill, `editingMediaId` cleared on `resetForNextCapture`, save-while-editing calls update path (not different-id dedupe)

### Implementation for User Story 4

- [x] T022 [US4] Add `editingMediaId` to `CraftJobState` in `lib/features/craft/domain/craft_job_state.dart` (copyWith + clear on `resetForNextCapture` / new-create paths in `CraftController`)
- [x] T023 [US4] Implement `MediaLibraryRepository.updateCraftedFromText(...)` in `lib/features/library/data/library_repository.dart` per `contracts/craft-history-edit.md` (require `provider == 'craft'`; replace file; upsert transcript; bump `updatedAt`; sync update; return same id). Add DAO helpers only if needed in `lib/data/db/` audio DAO
- [x] T024 [US4] Add helper to load craft `AudioRow` + primary timeline for edit (repo method used by controller) in `lib/features/library/data/library_repository.dart`
- [x] T025 [US4] Implement `CraftController.loadForEdit(String mediaId)` in `lib/features/craft/application/craft_controller.dart` per research R4 / data-model (prefill texts, languages, voice; style defaults; set stage/mode)
- [x] T026 [US4] Branch `saveToLibrary` / Express save paths in `lib/features/craft/application/craft_controller.dart`: when `editingMediaId != null`, call `updateCraftedFromText` and skip hash-dedupe return of a different id
- [x] T027 [US4] Wire history tile `onTap` in `lib/features/craft/presentation/craft_history_screen.dart` to `loadForEdit` then navigate back to `/craft`; show `craftEditUnavailable` when load fails

**Checkpoint**: Full history → edit → update-same-item loop works.

---

## Phase 7: User Story 5 — Craft branding without 自制 (Priority: P3)

**Goal**: Chinese product surfaces use Latin **Craft**; audit removes 自制 from title/badge/import/home Craft labels.

**Independent Test**: ZH locale — Home Craft, Craft title, badge, Import Craft row show Craft; grep ARBs for 自制 on those keys is clean.

### Tests for User Story 5

- [x] T028 [P] [US5] Add/extend l10n or widget assertion that ZH `craftScreenTitle` / `libraryProviderCraftBadge` / `homeCraftAction` / `importCraftFromText` equal `Craft` / `Craft…` in `test/features/craft/` or `test/l10n/`

### Implementation for User Story 5

- [x] T029 [US5] Audit `lib/l10n/app_zh.arb`, `lib/l10n/app_zh_CN.arb`, and generated `lib/l10n/app_localizations_zh.dart` for remaining 自制 on Craft product surfaces; fix any stragglers (keep `craftAction` = 合成 if still a verb)
- [x] T030 [US5] Spot-check Import chooser + library badge still use updated keys in `lib/features/library/presentation/library_actions.dart` and home/library tile badge wiring

**Checkpoint**: Branding FR-014 / SC-005 satisfied.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Docs, ADR, verification gates.

- [x] T031 [P] Write ADR-0061 in `docs/decisions/0061-craft-first-class-history.md` (first-class Home entry, history-as-filtered-library, update-in-place edit, Latin Craft in ZH) and link from `docs/decisions/README.md`
- [x] T032 [P] Update Navigation / History / Localization sections in `docs/features/craft.md`
- [x] T033 Run manual quickstart scenarios M1–M5 from `specs/029-craft-history-home/quickstart.md` (or document residual manual-only gaps in PR)
- [x] T034 Run `flutter analyze`, targeted `flutter test` for craft/library/hotkeys, then `bash .github/scripts/validate_ci_gates.sh --fix`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)** → **Phase 2 (Foundational)** → user stories
- **US1** and **US2** can proceed in parallel after Phase 2 (MVP = US1 alone; US2 recommended same milestone)
- **US3** after Phase 2 (independent of US1/US2)
- **US4** depends on **US3** UI existing (T017–T019) plus new repo/controller APIs
- **US5** largely satisfied by T005; audit/polish after US1 strings are live
- **Phase 8** after desired stories complete

### User Story Dependencies

| Story | Depends on | Independently testable? |
|-------|------------|-------------------------|
| US1 Home Craft | Phase 2 | Yes — Home CTA only |
| US2 Hotkey `c` | Phase 2 | Yes — hotkey only |
| US3 History list | Phase 2 | Yes — list/empty without edit |
| US4 Edit/save | US3 UI + repo/controller | Yes — given ≥1 Craft item |
| US5 Branding | Phase 2 (T005) | Yes — locale string audit |

### Parallel Opportunities

- T003 / T004 / T005 in parallel
- After Phase 2: US1 (T007–T009) ‖ US2 (T010–T013) ‖ US3 (T014–T019)
- Within US4: T020 ‖ T021 tests; T023–T024 before T025–T027
- Polish: T031 ‖ T032

---

## Parallel Example: After Foundational

```text
Developer A: T007–T009  (US1 Home Craft button)
Developer B: T011–T013  (US2 global.craft hotkey)
Developer C: T016–T019  (US3 history provider + UI)
```

Then one developer: T022–T027 (US4 edit/update), then T028–T030 (US5 audit), then T031–T034.

---

## Parallel Example: User Story 4 Tests

```text
Task: "Repository updateCraftedFromText tests in test/features/library/library_repository_craft_test.dart"
Task: "CraftController loadForEdit/save tests in test/features/craft/application/craft_controller_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 + Phase 2  
2. Phase 3 (US1) — Home Craft button  
3. **STOP and VALIDATE** (quickstart M1)  
4. Optionally add US2 in the same PR for desktop completeness  

### Incremental Delivery

1. Setup + Foundational → strings ready  
2. US1 → first-class Home entry (MVP)  
3. US2 → hotkey `c`  
4. US3 → history browse  
5. US4 → edit + update-same-item  
6. US5 + Polish → branding audit, ADR, docs, CI gates  

### Suggested MVP Scope

**US1 only** (Home Craft next to Import). Recommended first shippable slice: **US1 + US2 + foundational branding ARBs (T005)**.

---

## Notes

- Do not reuse ZH `craftAction` (`合成`) for the Home product button — use `homeCraftAction`.
- `importCraftedFromText` stays for **new** creates; edit saves must use `updateCraftedFromText`.
- Style is not persisted — edit uses defaults (research R4).
- Library header Craft parity is out of scope.
- Commit after each story checkpoint when possible.
