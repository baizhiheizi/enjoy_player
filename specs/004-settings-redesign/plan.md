# Implementation Plan: Settings Redesign

**Branch**: `main` (no dedicated feature branch — this repo's `004-settings-redesign` spec directory is independent of git branch naming; see [spec.md](./spec.md)) | **Date**: 2026-07-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/004-settings-redesign/spec.md`

## Summary

Redesign the existing `SettingsScreen` (~1566 LOC, one file, 14+ private widgets — see [Issue #45](https://github.com/baizhiheizi/enjoy_player/issues/45)) into a componentized, easy-to-scan hub without changing any underlying preference logic, routes, or gating rules (FR-004). Three clarified IA decisions drive the redesign: (1) a client-side search/filter field that indexes every section/row title, including inside collapsed sections (FR-010); (2) a persistent two-pane layout (category rail + detail pane) at the app's existing `breakpointRail` (900px) desktop threshold, falling back to today's single scrolling column below it (FR-011); (3) the Developer/Advanced and About sections collapsed by default while everyday sections stay expanded (FR-012). The extraction also replaces the screen's bespoke `_SettingsCard` / `_SettingsSubduedCard` with the already-existing shared `EnjoyCard` primitive, directly serving SC-003 (zero bespoke tokens).

## Technical Context

**Language/Version**: Dart ^3.12, Flutter stable (SDK constraint in `pubspec.yaml`)

**Primary Dependencies**: Riverpod 3 (`@riverpod`), go_router, existing settings-adjacent providers (`appPreferencesCtrlProvider`, `authCtrlProvider`, `syncQueueSnapshotProvider`, `hotkeysCtrlProvider`, `recordingInputDeviceCtrlProvider`, `apiBaseUrlProvider`, `aiApiBaseUrlProvider`, `recordingInputDeviceCtrlProvider`), shared UI primitives (`EnjoyCard`, `EnjoyButton`, `Haptics`, `EditorialHeader`, `Skeleton`, `showEnjoySheet`/`showEnjoyAlertDialog`/`showEnjoyDialog`)

**Storage**: No new Drift tables and no new persisted preference values. Search query, selected rail section, and section-collapse state are ephemeral in-memory Riverpod state per the spec's Assumptions — not persisted across app restarts.

**Testing**: `flutter test` — unit tests for the pure search-matching function (domain layer, no Flutter import); widget tests for the two-pane/single-column breakpoint switch, default collapse state, search filtering (match / no-match / auto-expand-on-match), and keyboard focus/tab order.

**Target Platform**: Android, iOS, macOS, Windows (no Flutter web). The two-pane layout triggers on **width**, not platform — it can appear on a maximized/resized desktop window or a wide tablet, matching how `breakpointRail` already drives `AppSidebar` vs mobile nav today.

**Project Type**: Flutter native mobile/desktop app

**Performance Goals**: Hub initial frame build time not regressed vs. the current implementation (QR-004 / SC-006, verified by profile trace comparison); search filtering feels instant (<16ms per keystroke) since the registry is a static in-memory list of ~30 rows — no debounce required, but the filter function is pure/allocation-light so it's safe to call on every keystroke.

**Constraints**: Pure visual/IA redesign — no new backend calls, no new routes beyond the ones already registered in `app_router.dart`, no bespoke design tokens (SC-003); every conditional visibility rule (desktop-only keyboard shortcuts, debug-only developer tools, learning-language capability gating, signed-in vs signed-out copy) must be preserved exactly (FR-005/FR-006).

**Scale/Scope**: ~8 sections / ~28 rows total today; refactor of 1 existing ~1566 LOC file into ~14 smaller files; ARB additions (~12–15 keys) across all 3 supported locales (`app_en.arb`, `app_zh.arb`, `app_zh_CN.arb`); no new ADR expected (see Constitution Check V) but `docs/features/settings.md` must be updated (QR-005).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Architecture and Code Quality

- **Pass**: New/extracted code stays under `lib/features/settings/{application,domain,presentation}`. The search-matching logic (`filterSettingsEntries`) is pure Dart in `domain/` — no `BuildContext`, no Flutter widget imports.
- **Pass**: Search query, selected rail section, and collapse-state are Riverpod (`@riverpod`) notifiers — no mutable global singletons.
- **Note (not a new violation)**: `SettingsScreen` inherently imports from several other features (`auth`, `sync`, `hotkeys`, `shadow_reading` for the mic picker) to aggregate their entry points — this is pre-existing and documented in `docs/features/settings.md`. FR-004 requires the exact same destinations/imports, so this redesign introduces **no additional** feature↔feature coupling versus today.
- **Pass**: No `print()`; no `media_kit` `Player()` involvement (Settings has none today).

### II. Testing Defines the Contract

- **Required**: Unit tests for `filterSettingsEntries` (domain) — case-insensitive substring match, empty query, no-match.
- **Required**: Widget tests — layout switches to two-pane at `breakpointRail` and back; Developer/About render collapsed by default while other sections render expanded; search surfaces matches (including inside collapsed sections) and auto-expands the containing section; search with no matches shows the "no results" empty state; selected section/scroll position survives a breakpoint crossing.
- **Manual** (documented reason: pure visual polish is not practically automatable): side-by-side visual comparison against Home/Library on at least one mobile and one desktop build, and a keyboard-navigation/touch-target pass — per SC-003/SC-005.
- **Codegen**: Run `dart run build_runner build` after adding the new `@riverpod` providers.

### III. User Experience Consistency

- **Pass**: Reuses `EnjoyCard` (already documented as the "grouped settings-style surface" primitive) in place of the private `_SettingsCard`/`_SettingsSubduedCard`; reuses `EnjoyButton`, `Haptics.wrapTap`, `EditorialHeader`, `Skeleton`, and the existing modal helpers.
- **Pass**: All new strings (search placeholder/no-results, collapse/expand affordance labels, rail item semantics) added to `app_en.arb`, `app_zh.arb`, `app_zh_CN.arb`.
- **Required**: Update `docs/features/settings.md` — new search/layout/collapse behavior and the file-split code map (this also closes the split half of Issue #45).

### IV. Performance Is a Requirement

- **Pass**: Search is a synchronous in-memory filter over a small static list — no work in `build()` beyond a cheap `where()` call; no debounce needed at this data size.
- **Pass**: The two-pane/single-column switch is a `LayoutBuilder` read, not a rebuild-heavy operation; existing provider watches (auth, sync, prefs, hotkeys, recording devices) are unchanged in number or shape.
- **Evidence**: Manual before/after widget build trace comparison on a signed-in account with cloud sync enabled (representative "worst case" state), per SC-006.

### V. Documentation and Traceability

- **Required**: Update `docs/features/settings.md` (routes unchanged; new sections: search, two-pane layout, default-collapsed sections; updated code map reflecting the file split).
- **No ADR needed**: This is a reversible visual/information-architecture change, not an architecture or product-scope decision that is "costly to reverse" per the ADR threshold in `docs/decisions/README.md` — no routes, persistence, or platform support change.
- **No exception required.**

**Post-design re-check**: All gates pass; see [research.md](./research.md) Decision log for how each Technical Context unknown was resolved before Phase 1 design.

## Project Structure

### Documentation (this feature)

```text
specs/004-settings-redesign/
├── plan.md              # This file
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1 validation guide
├── contracts/           # Phase 1
│   ├── settings-section-registry.md
│   ├── settings-search.md
│   └── settings-layout.md
└── tasks.md             # Phase 2 (/speckit-tasks — not created here)
```

### Source Code (repository root)

```text
lib/features/settings/
├── domain/
│   └── settings_search_entry.dart          # NEW — pure {sectionId, rowId?, title, keywords}; filterSettingsEntries()
├── application/
│   ├── settings_search_query_provider.dart      # NEW — @riverpod current query string
│   ├── settings_selected_section_provider.dart  # NEW — @riverpod selected rail section id (two-pane)
│   └── settings_section_collapse_provider.dart  # NEW — @riverpod Map<sectionId, bool>; Developer + About default true
├── data/                                          # unchanged — no data-layer changes
└── presentation/
    ├── settings_screen.dart                 # REWRITE — composes layout only, no longer ~1566 LOC
    ├── hotkeys_settings_screen.dart         # Restyle only (adopt shared row/card primitives)
    ├── sync_status_screen.dart              # Restyle only (adopt shared row/card primitives)
    └── widgets/
        ├── settings_search_field.dart               # NEW
        ├── settings_layout_two_pane.dart             # NEW — rail + detail pane at breakpointRail
        ├── settings_layout_single_column.dart        # NEW — today's stacked layout, restyled
        ├── settings_section_rail_item.dart           # NEW
        ├── settings_section_card.dart                # NEW — thin wrapper around EnjoyCard
        ├── settings_row.dart                         # Extracted from `_SettingsTile`
        ├── settings_collapsible_section.dart         # NEW — collapse/expand + error/warning badge
        ├── about_section_card.dart                   # unchanged
        ├── language_choice_sheet.dart                # unchanged
        └── sections/
            ├── account_hero_section.dart             # Extracted from `_AccountHeroCard` / `_AccountHeroSkeleton`
            ├── cloud_sync_section.dart                # Extracted
            ├── appearance_language_section.dart       # Extracted
            ├── ai_providers_section.dart               # Extracted
            ├── recording_section.dart                  # Extracted from `_RecordingMicTile`
            ├── keyboard_shortcuts_section.dart         # Extracted
            ├── developer_section.dart                  # Extracted from `_ApiBaseUrlEditor` / `_AiApiBaseUrlEditor`
            └── about_section.dart                       # Wraps existing `about_section_card.dart`

test/features/settings/
├── domain/
│   └── settings_search_entry_test.dart      # NEW
└── presentation/
    ├── settings_screen_test.dart             # NEW — breakpoint switch, default collapse state
    └── settings_search_field_test.dart       # NEW — match / no-match / auto-expand

lib/l10n/
├── app_en.arb        # + settingsSearch*, settingsSection*Collapsed*, settingsRailItem* keys
├── app_zh.arb         # same keys, translated
└── app_zh_CN.arb      # same keys, translated

docs/
└── features/settings.md   # UPDATE — search/layout/collapse behavior, refreshed code map
```

**Structure Decision**: Keep everything inside the existing `settings` feature module (no new feature, no cross-feature widget moves). The pure search-matching logic goes in `domain/` specifically so it can be unit-tested without pumping a widget tree — it's the only genuinely new "business logic" this redesign introduces; everything else is layout/composition using primitives that already exist elsewhere in the app (`EnjoyCard`, `breakpointRail`, the library-search Riverpod pattern in `features/library/application/library_search_provider.dart`).

## Complexity Tracking

> No constitution violations.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|---------------------------------------|
| — | — | — |

## Implementation Phases (for `/speckit-tasks`)

### Phase A — Domain + application state foundation

1. Add `SettingsSearchEntry` + `filterSettingsEntries()` in `domain/settings_search_entry.dart` (pure Dart).
2. Add `settingsSearchQueryProvider`, `settingsSelectedSectionProvider`, `settingsSectionCollapseProvider` (Developer + About default collapsed).
3. Unit tests for the matcher (case-insensitivity, empty query, no match, matches within a "collapsed" entry).
4. `dart run build_runner build`.

### Phase B — Shared presentation primitives (P1/P3 stories)

1. `SettingsSectionCard` (thin `EnjoyCard` wrapper), `SettingsRow` (extracted `_SettingsTile`), `SettingsCollapsibleSection` (collapse/expand + badge-when-collapsed-and-erroring), `SettingsSearchField`.
2. Widget tests: collapsible section shows a badge when a child row reports an error while collapsed (edge case from spec).

### Phase C — Section extraction (behavior-preserving 1:1 migration)

1. Move each existing section's content into `presentation/widgets/sections/*.dart` verbatim (account hero, cloud sync, appearance & language, AI providers, recording, keyboard shortcuts, developer, about) — no new IA yet, just file-split + `EnjoyCard` swap.
2. Re-run existing manual verification checklist (route walkthrough from SC-002) to confirm zero regressions before adding new IA.

### Phase D — Layout composition (P1 story 1, P3 story 3)

1. `SettingsLayoutSingleColumn` (today's stacked-card order, restyled) and `SettingsLayoutTwoPane` (rail + detail pane) behind a `LayoutBuilder` keyed on `EnjoyThemeTokens.breakpointRail`.
2. Wire `settingsSelectedSectionProvider` so selection/scroll survive a breakpoint crossing (edge case from spec).
3. Widget test: resize across the breakpoint repeatedly — no flicker, no lost selection (SC-008).

### Phase E — Search + default collapse wiring (P1 story 1)

1. Wire `SettingsSearchField` to `settingsSearchQueryProvider`; filter the section/row registry; auto-expand a collapsed section containing a match; render "no results" empty state on zero matches.
2. Apply `settingsSectionCollapseProvider` defaults (Developer + About collapsed; others expanded) to both layouts.
3. Widget tests: search reaches rows inside collapsed sections (SC-007); no-results state; manual expand/collapse still works.

### Phase F — Sub-screen visual alignment

1. Restyle `hotkeys_settings_screen.dart` and `sync_status_screen.dart` to use `SettingsRow`/`SettingsSectionCard` where applicable — visual language only, no change to hotkey/sync domain logic.

### Phase G — Docs & validation

1. `docs/features/settings.md` — document search, two-pane layout, default-collapsed sections, refreshed code map.
2. `flutter gen-l10n`, `dart run build_runner build`, `flutter analyze`, `flutter test`.
3. Manual quickstart per [quickstart.md](./quickstart.md): route/action checklist (SC-002), 5-setting findability timing (SC-001/SC-007), keyboard/touch-target pass (SC-005), cross-platform visual comparison (SC-003).

## Risk Notes

| Risk | Mitigation |
|------|------------|
| Splitting a 1566 LOC screen risks silent behavior regressions | Phase C extracts sections 1:1 with **zero** new IA before Phase D/E add search/two-pane/collapse — regressions are caught early against a known-good baseline. |
| Two-pane selection/scroll state lost when the window crosses the breakpoint repeatedly (spec edge case) | Selection lives in a Riverpod provider, not `State` local to a rebuilt widget, so it survives layout swaps. |
| Search must reach rows inside collapsed sections without drifting out of sync with the rendered sections | The section/row registry (`domain/settings_search_entry.dart`) is the single source of truth consumed by both the rail/collapse renderer and the search index — see [contracts/settings-section-registry.md](./contracts/settings-section-registry.md). |
| New ARB keys land in `app_en.arb` but miss `app_zh.arb`/`app_zh_CN.arb` | Add all three locale entries in the same commit; run `flutter gen-l10n` before `flutter analyze` (SC-004). |
| Reusing `EnjoyCard`/`EnjoyButton` might visually flatten the existing gradient account hero | Per spec Assumptions, the gradient hero look is preserved — it already uses `EnjoyThemeTokens.gradientStart/gradientEnd` tokens today, not one-off hex values, so it is not "bespoke" under SC-003. |
