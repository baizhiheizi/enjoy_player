---

description: "Task list template for feature implementation"

---

# Tasks: Settings Redesign

**Input**: Design documents from `/specs/004-settings-redesign/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present)

**Tests**: Automated tests are required for changed behavior (widget/unit); pure visual polish is documented as manual verification per plan.md Constitution Check §II — see Final Phase.

**Organization**: Tasks are grouped by user story (US1/US2/US3, priorities P1/P2/P3 from spec.md) so each story is independently implementable, testable, and deployable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- File paths are exact per plan.md's Project Structure

## Path Conventions

- **Feature code**: `lib/features/settings/{application,domain,presentation}/`
- **Shared code**: `lib/core/theme/widgets/` (reused, not modified — `EnjoyCard`, `EnjoyButton`, `Haptics`, `EditorialHeader`, `Skeleton`)
- **Tests**: `test/features/settings/`
- **Feature docs**: `docs/features/settings.md`
- **Localization**: `lib/l10n/app_en.arb`, `lib/l10n/app_zh.arb`, `lib/l10n/app_zh_CN.arb`

---

## Phase 1: Setup

**Purpose**: Confirm target structure before any code moves.

- [X] T001 Create `lib/features/settings/presentation/widgets/sections/` directory and confirm `lib/features/settings/domain/` and `lib/features/settings/application/` exist per plan.md Project Structure
- [X] T002 [P] Read current `lib/features/settings/presentation/settings_screen.dart` end-to-end and enumerate every existing row/section/route/gating rule into a migration checklist (used to verify FR-004/FR-005/FR-006 parity in later phases)
- [X] T003 [P] Confirm no ADR is needed (plan.md Constitution Check §V) and open a tracking note referencing `docs/features/settings.md` as the doc to update in the Final Phase

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared registry, state, and primitives that **all three** user stories depend on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T004 [P] Create `SettingsSearchEntry` model + `filterSettingsEntries(query, entries)` pure function in `lib/features/settings/domain/settings_search_entry.dart` (data-model.md)
- [X] T005 [P] Unit test `filterSettingsEntries` (case-insensitive, empty query, no match, keyword match) in `test/features/settings/domain/settings_search_entry_test.dart`
- [X] T006 [P] Populate the static section/row registry with one `SettingsSearchEntry` per current section and row (Account, Cloud sync, Appearance & Language ×3, AI providers, Recording, Keyboard shortcuts ×2, Developer ×3, About) in `lib/features/settings/domain/settings_search_entry.dart`, satisfying `contracts/settings-section-registry.md` — `collapsedByDefault: true` only for `developer` and `about`
- [X] T007 [P] Create `settingsSearchQueryProvider` (`@riverpod`, string notifier) in `lib/features/settings/application/settings_search_query_provider.dart`
- [X] T008 [P] Create `settingsSelectedSectionProvider` (`@riverpod`, string notifier, defaults to `account`) in `lib/features/settings/application/settings_selected_section_provider.dart`
- [X] T009 [P] Create `settingsSectionCollapseProvider` (`@riverpod`, `Map<String, bool>` notifier with `toggle(sectionId)`, seeded from each entry's `collapsedByDefault`) in `lib/features/settings/application/settings_section_collapse_provider.dart`
- [X] T010 Run `dart run build_runner build` to generate code for T007–T009
- [X] T011 [P] Create `SettingsSectionCard` (thin wrapper around `EnjoyCard`) in `lib/features/settings/presentation/widgets/settings_section_card.dart`
- [X] T012 [P] Create `SettingsRow` (extracted/generalized from today's `_SettingsTile`: icon, title, subtitle, value badge, trailing, chevron) in `lib/features/settings/presentation/widgets/settings_row.dart`
- [X] T013 [P] Create `SettingsCollapsibleSection` (collapse/expand chevron, header, error/warning badge-when-collapsed per spec edge case) in `lib/features/settings/presentation/widgets/settings_collapsible_section.dart`
- [X] T014 [P] Add new ARB keys — search placeholder, no-results message + clear affordance, collapse/expand semantics labels — to `lib/l10n/app_en.arb`, `lib/l10n/app_zh.arb`, `lib/l10n/app_zh_CN.arb`
- [X] T015 Run `flutter gen-l10n`

**Checkpoint**: Registry, state providers, and shared row/card/collapsible primitives exist and compile — user story implementation can now begin.

---

## Phase 3: User Story 1 - Find any setting quickly (Priority: P1) 🎯 MVP

**Goal**: A user can scan the Settings hub, see clearly-grouped sections with unambiguous headings, and either browse or search to reach any setting without scrolling past unrelated dense content — deliverable as a single-column redesign (two-pane desktop layout is added in US3).

**Independent Test**: Open Settings on a fresh install and time how long it takes to locate and open "Keyboard shortcuts", "Display language", and "Cloud sync status" — both by scanning and by typing into the search field — without two-pane mode.

### Tests for User Story 1

- [X] T016 [P] [US1] Widget test: Developer and About sections render collapsed by default; Account, Cloud sync, Appearance & Language, AI providers, Recording, Keyboard shortcuts render expanded, in `test/features/settings/presentation/settings_screen_test.dart`
- [X] T017 [P] [US1] Widget test: typing a query into the search field filters visible rows across all sections, including auto-expanding a currently-collapsed section that contains a match, in `test/features/settings/presentation/settings_search_field_test.dart`
- [X] T018 [P] [US1] Widget test: a query matching nothing shows the "no results" empty state with a working clear affordance that restores the prior collapse state, in `test/features/settings/presentation/settings_search_field_test.dart`
- [X] T019 [P] [US1] Widget test: on a narrow (mobile) width, row titles/values never clip in a way that hides the current value (long email/device/language label truncates gracefully, full value still conveyed), in `test/features/settings/presentation/widgets/settings_row_narrow_width_test.dart`

### Implementation for User Story 1

- [X] T020 [US1] Build `SettingsSearchField` (wraps `TextField`, writes to `settingsSearchQueryProvider`, trailing clear icon) in `lib/features/settings/presentation/widgets/settings_search_field.dart`
- [X] T021 [P] [US1] Extract Account hero content into `lib/features/settings/presentation/widgets/sections/account_hero_section.dart` (from `_AccountHeroCard`/`_AccountHeroSkeleton`), preserving signed-in/out/loading/error states 1:1
- [X] T022 [P] [US1] Extract Cloud sync content into `lib/features/settings/presentation/widgets/sections/cloud_sync_section.dart`, preserving the `_SyncQueueStatusPill` states 1:1
- [X] T023 [P] [US1] Extract Appearance & Language content into `lib/features/settings/presentation/widgets/sections/appearance_language_section.dart`, preserving display/learning/native language picker behavior 1:1
- [X] T024 [P] [US1] Extract AI providers content into `lib/features/settings/presentation/widgets/sections/ai_providers_section.dart`
- [X] T025 [P] [US1] Extract Recording content into `lib/features/settings/presentation/widgets/sections/recording_section.dart` (from `_RecordingMicTile`), preserving the mic picker dialog 1:1
- [X] T026 [P] [US1] Extract Keyboard shortcuts content into `lib/features/settings/presentation/widgets/sections/keyboard_shortcuts_section.dart`, preserving desktop-only visibility (FR-006)
- [X] T027 [P] [US1] Extract Developer content into `lib/features/settings/presentation/widgets/sections/developer_section.dart` (from `_ApiBaseUrlEditor`/`_AiApiBaseUrlEditor`), preserving non-release-build gating (FR-005)
- [X] T028 [P] [US1] Wrap existing `about_section_card.dart` content in `lib/features/settings/presentation/widgets/sections/about_section.dart` for registry/layout consistency
- [X] T029 [US1] Build `SettingsLayoutSingleColumn` assembling all section widgets from T021–T028 via `SettingsSectionCard`/`SettingsCollapsibleSection` in reading order, applying default-collapse from `settingsSectionCollapseProvider`, in `lib/features/settings/presentation/widgets/settings_layout_single_column.dart`
- [X] T030 [US1] Rewrite `lib/features/settings/presentation/settings_screen.dart` to render `EditorialHeader` + `SettingsSearchField` + `SettingsLayoutSingleColumn`, wiring `settingsSearchQueryProvider` to filter the registry, auto-expand matching collapsed sections, and show the no-results state (per `contracts/settings-search.md`)
- [X] T031 [US1] Manually walk every destination against the T002 migration checklist to confirm 100% route/action parity (SC-002) before proceeding to US2/US3

**Checkpoint**: User Story 1 is fully functional and independently testable/deployable — searchable, clearly-grouped single-column Settings hub with default-collapsed Developer/About.

---

## Phase 4: User Story 2 - Understand current state and change it confidently (Priority: P2)

**Goal**: Every settings row shows its current value clearly, edits confirm immediately, and unavailable/gated rows explain why instead of looking broken.

**Independent Test**: Change the display language, the learning language, and the microphone input device from the redesigned Settings hub and confirm each change is reflected immediately in the row's value with a success notice, without needing to navigate away from the hub.

### Tests for User Story 2

- [X] T032 [P] [US2] Widget test: changing the display language via `SettingsRow` → language picker sheet updates the row's value badge immediately and does not require leaving the hub, in `test/features/settings/presentation/sections/appearance_language_section_test.dart`
- [X] T033 [P] [US2] Widget test: selecting a microphone device updates the Recording row's subtitle and closes the picker dialog, in `test/features/settings/presentation/sections/recording_section_test.dart`
- [X] T034 [P] [US2] Widget test: a loading state (account/sync/language prefs) renders a skeleton, not a blank or broken-looking row, in `test/features/settings/presentation/sections/settings_loading_states_test.dart`
- [X] T035 [P] [US2] Widget test: a capability-gated row (e.g. native language when only one choice is allowed) renders disabled with its existing explanatory subtitle rather than silently omitting the control, in `test/features/settings/presentation/sections/appearance_language_section_test.dart`

### Implementation for User Story 2

- [X] T036 [US2] Audit every extracted section (T021–T028) against the T002 checklist to confirm `SettingsRow`'s value badge is never clipped in a way that hides the current value (FR-002) — adjust `SettingsRow` layout constraints if any regression is found. Audited (compared each extracted section against the pre-redesign `settings_screen.dart` at commit `688b849`); no regression found — `SettingsRow`'s narrow-width behavior is covered by T019
- [X] T037 [US2] Confirm `AppNotice.success` (or equivalent) fires after every value change (language pickers, mic picker, developer API URL saves) is preserved 1:1 through the extraction — add if any section lost its confirmation during T021–T027. Confirmed identical to the pre-redesign implementation (3/3 `AppNotice.success` call sites preserved in `developer_section.dart`); nothing to add
- [X] T038 [US2] Confirm all existing loading/error/empty states (account load failure + retry, sync loading/error, language prefs loading, mic empty-state, developer save failure) are preserved and re-styled via `SettingsRow`/`SettingsSectionCard`, not removed (FR-007). Confirmed identical `.when()` loading/error branches preserved in `account_hero_section.dart`, `cloud_sync_section.dart`, `appearance_language_section.dart`; covered by `settings_loading_states_test.dart` and `recording_section_test.dart`'s empty-device-list case
- [X] T039 [US2] Add any missing localized explanation string for a disabled/gated row found during T035/T036 to `lib/l10n/app_en.arb`, `app_zh.arb`, `app_zh_CN.arb`. None missing — the native-language gated row already reuses the existing `settingsLanguageSubtitleSignedIn`/`settingsLanguageSubtitleDeviceOnly` strings

**Checkpoint**: User Stories 1 AND 2 both work independently — findable AND confidently editable.

---

## Phase 5: User Story 3 - Feel the app is polished and trustworthy (Priority: P3)

**Goal**: The hub (and its sub-screens/pickers) visually matches the rest of the app, gains the two-pane desktop layout for reduced scrolling, and remains usable with reduced motion / large text.

**Independent Test**: Side-by-side visual review of the redesigned hub against Home/Library confirming shared design tokens; resize a desktop window across the two-pane breakpoint repeatedly and confirm no flicker or lost selection.

### Tests for User Story 3

- [X] T040 [P] [US3] Widget test: layout renders `SettingsLayoutSingleColumn` below `EnjoyThemeTokens.breakpointRail` and `SettingsLayoutTwoPane` at/above it, in `test/features/settings/presentation/settings_screen_test.dart`
- [X] T041 [P] [US3] Widget test: resizing the test surface across the breakpoint 10+ times in a row preserves `settingsSelectedSectionProvider`'s value and produces no exceptions/flicker (SC-008), in `test/features/settings/presentation/settings_screen_test.dart`
- [X] T042 [P] [US3] Widget test: every interactive row and rail item exposes a `Focus`/`FocusableActionDetector` that receives a visible focus ring on keyboard traversal, in `test/features/settings/presentation/widgets/settings_focus_traversal_test.dart`

### Implementation for User Story 3

- [X] T043 [US3] Build `SettingsSectionRailItem` (icon + title + selected-state highlight, matching `AppSidebar`'s selected-nav-item treatment) in `lib/features/settings/presentation/widgets/settings_section_rail_item.dart`
- [X] T044 [US3] Build `SettingsLayoutTwoPane` (rail of `SettingsSectionRailItem`s + detail pane rendering the selected section's rows via the same `sections/*.dart` widgets from Phase 3) in `lib/features/settings/presentation/widgets/settings_layout_two_pane.dart`, reading/writing `settingsSelectedSectionProvider`
- [X] T045 [US3] Wire a `LayoutBuilder` in `lib/features/settings/presentation/settings_screen.dart` keyed on `EnjoyThemeTokens.breakpointRail` to choose between `SettingsLayoutSingleColumn` (T029) and `SettingsLayoutTwoPane` (T044) without resetting search/selection/collapse state (`contracts/settings-layout.md`)
- [X] T046 [US3] Apply the same search-filtered visibility rules to the two-pane rail (hide non-matching sections; auto-select the first matching section when the current selection has zero matches) per `contracts/settings-search.md` §3
- [X] T047 [P] [US3] Restyle `lib/features/settings/presentation/hotkeys_settings_screen.dart` to use `SettingsRow`/`SettingsSectionCard` where applicable (visual language only — no change to hotkey domain logic)
- [X] T048 [P] [US3] Restyle `lib/features/settings/presentation/sync_status_screen.dart` to use `SettingsRow`/`SettingsSectionCard` where applicable (visual language only — no change to sync domain logic)
- [X] T049 [US3] Delete the now-unused private widgets (`_SettingsCard`, `_SettingsSubduedCard`, old `_SettingsTile`, `_SettingsDivider`, `_SettingsSectionHeader`, etc.) from the old monolithic `settings_screen.dart` body once T021–T048 fully replace their usages, confirming zero bespoke one-off tokens remain (SC-003). Verified: `settings_screen.dart` is now a ≈55-line composition root with zero private widgets; grepped the whole `lib/features/settings/` tree for the old private-widget names and found only a doc-comment reference in `settings_row.dart`
- [X] T050 [US3] Manual accessibility pass with OS reduced-motion and largest text scale enabled across the hub and its sub-screens/pickers — confirm no overlapping/clipped text and that collapse/expand works via a visible tap target, not only animation (documented per Constitution §II manual-verification allowance). Automated equivalent added in `test/features/settings/presentation/settings_accessibility_test.dart` (reduced motion + 3x text scale, single-column and two-pane, collapse/expand via tap). This caught and fixed a real bug: `SettingsCollapsibleSection`'s `AnimatedSize`/`AnimatedRotation` used a literal `Duration.zero` under reduced motion, which throws a Flutter framework assertion ("`RenderAnimatedSize` was mutated in its own `performLayout`") — changed to a 1ms duration. A true OS-level manual pass is still recommended before release (see T052)

**Checkpoint**: All three user stories are independently functional; the hub matches Home/Library's visual language and gains the two-pane desktop layout.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Purpose**: Repo-wide verification and documentation required before this change is considered done.

- [X] T051 [P] Update `docs/features/settings.md` — document search, two-pane layout, default-collapsed sections, and the refreshed code map (file split) per QR-005
- [ ] T052 [P] Run all 7 manual scenarios in `quickstart.md` and record sign-off (route/action parity, findability timing with/without search, breakpoint resize stress, default collapse, no-results state, cross-platform visual comparison, reduced-motion/large-text pass). **Needs a human**: requires interactively running the built app on-device/OS, which an automated coding session cannot perform — automated equivalents exist for the resize-stress (T041), default-collapse (T016), no-results (T018), and reduced-motion/large-text (T050) scenarios, but sign-off itself is still outstanding
- [X] T053 Run `flutter analyze` — zero new warnings (37 pre-existing issues remain in unrelated `ai`/`subscription`/`byok` files; `flutter analyze lib/features/settings test/features/settings` reports 0 issues)
- [X] T054 Run `flutter test` (full suite) — zero regressions, all new Settings tests (T005, T016–T019, T032–T035, T040–T042) green (712/713 passing; the 1 failure — `recommended_channels_test.dart` — is a pre-existing, unrelated Discover-feature data assertion, reproduced identically with all Settings changes stashed)
- [X] T055 Run `dart run build_runner build` — confirm generated code is up to date after all `@riverpod` additions
- [X] T056 Run `flutter gen-l10n` — confirm zero missing-translation fallback warnings across `app_en.arb`/`app_zh.arb`/`app_zh_CN.arb` (SC-004). The 3 new T014 keys are present with matching translations in all three ARB files; `zh_CN`'s pre-existing 141 untranslated-fallback count (it intentionally overlays `zh` rather than duplicating every key) is unrelated to this feature and unchanged by it

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS** all user stories (registry/providers/primitives are shared by US1–US3).
- **User Story 1 (Phase 3)**: Depends on Phase 2 only. Delivers the MVP (searchable, clearly-grouped single-column hub).
- **User Story 2 (Phase 4)**: Depends on Phase 2 and on the section extraction from Phase 3 (T021–T028) since it audits/hardens those same rows — not independent of US1's *files*, but independently *testable* and *demoable* once US1 lands.
- **User Story 3 (Phase 5)**: Depends on Phase 2 and on Phase 3's section widgets (reused verbatim in the two-pane detail pane) — independently testable as an additive desktop-layout/visual-polish layer on top of US1.
- **Final Phase**: Depends on all desired user stories being complete.

### User Story Dependencies

- **US1 (P1)**: No dependency on US2/US3 — ships as a complete, independently valuable improvement on its own.
- **US2 (P2)**: Builds on the section widgets US1 extracts; independently testable (its acceptance scenarios don't require search or two-pane).
- **US3 (P3)**: Builds on the section widgets US1 extracts; independently testable (its acceptance scenarios are about layout/visual consistency, not search or value-editing).

### Parallel Opportunities

- T004–T009, T011–T014 (Phase 2) can all run in parallel — different files, no cross-dependencies except the shared registry file (T004/T006 touch the same file sequentially).
- T021–T028 (all eight section extractions in Phase 3) can run fully in parallel — different files, each behavior-preserving in isolation.
- T032–T035, T040–T042 (test tasks within US2/US3) can run in parallel with each other.
- T047/T048 (sub-screen restyles in US3) can run in parallel with each other and with T043–T046.

---

## Parallel Example: Phase 2 (Foundational)

```bash
Task: "Create SettingsSearchEntry model in lib/features/settings/domain/settings_search_entry.dart"
Task: "Create settingsSearchQueryProvider in lib/features/settings/application/settings_search_query_provider.dart"
Task: "Create settingsSelectedSectionProvider in lib/features/settings/application/settings_selected_section_provider.dart"
Task: "Create settingsSectionCollapseProvider in lib/features/settings/application/settings_section_collapse_provider.dart"
Task: "Create SettingsSectionCard in lib/features/settings/presentation/widgets/settings_section_card.dart"
Task: "Create SettingsRow in lib/features/settings/presentation/widgets/settings_row.dart"
Task: "Create SettingsCollapsibleSection in lib/features/settings/presentation/widgets/settings_collapsible_section.dart"
```

## Parallel Example: Phase 3 (User Story 1 section extraction)

```bash
Task: "Extract Account hero into sections/account_hero_section.dart"
Task: "Extract Cloud sync into sections/cloud_sync_section.dart"
Task: "Extract Appearance & Language into sections/appearance_language_section.dart"
Task: "Extract AI providers into sections/ai_providers_section.dart"
Task: "Extract Recording into sections/recording_section.dart"
Task: "Extract Keyboard shortcuts into sections/keyboard_shortcuts_section.dart"
Task: "Extract Developer into sections/developer_section.dart"
Task: "Wrap About into sections/about_section.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Run quickstart.md scenarios 1, 2, 4, 5 — confirm findability + search work without two-pane
5. Ship as an incremental improvement if ready — US2/US3 can follow in later iterations

### Incremental Delivery

1. Setup + Foundational → shared registry/state/primitives ready
2. US1 → searchable, clearly-grouped hub → validate → ship (MVP)
3. US2 → confirm/harden value clarity and edit confidence → validate → ship
4. US3 → two-pane desktop layout + full visual/accessibility polish → validate → ship
5. Each story adds value without breaking the previous one (US2/US3 only touch styling/state around the same section widgets, never routes or gating)

### Solo/Small-Team Strategy

Given this is a single-file-today refactor, sequential delivery (Setup → Foundational → US1 → US2 → US3 → Polish) is the safer default even for one contributor — Phase 3's T021–T028 extractions are still individually parallelizable within that step.

---

## Notes

- [P] tasks = different files, no dependencies.
- [Story] label maps task to specific user story for traceability.
- Tests are written before their corresponding implementation task within each story's block; run them and confirm they fail first if practicing strict TDD.
- Commit after each task or logical group (e.g. after all of T021–T028, or after T029–T031).
- Stop at any checkpoint to validate a story independently before continuing.
- Avoid: editing the old monolithic `settings_screen.dart` sections in place — extract into the new files first (T021–T028), then delete dead code (T049) only after the new composition (T030/T045) is verified working.
