# Phase 0 Research: Settings Redesign

All Technical Context unknowns from [plan.md](./plan.md) are resolved below before Phase 1 design.

## 1. Search implementation approach

- **Decision**: Client-side, in-memory, case-insensitive substring match over a static registry of section/row titles (`domain/settings_search_entry.dart`, `filterSettingsEntries(query, entries)`). No debounce.
- **Rationale**: The spec's Assumptions section explicitly scopes search as "a client-side, in-memory match against already-loaded section/row titles — not a new backend search feature." The registry is ~28 rows; a synchronous `where()` filter is well under the 16ms/frame budget with no need for async work, isolates, or debouncing. This mirrors the existing `librarySearchProvider` pattern (`features/library/application/library_search_provider.dart`) already used for the compact library search bar, so the app already has a proven, tested Riverpod shape for "typed query → filtered view" that this redesign can follow rather than invent.
- **Alternatives considered**:
  - *Fuzzy/scored matching (e.g. Levenshtein)* — rejected as over-engineering for ~28 short, distinct English/localized labels; substring match already satisfies SC-007 (find a setting in <5s).
  - *Debounced search with `Timer`* — rejected; unnecessary at this data size and adds a testable-but-pointless async edge case (would violate QR-004's "no new synchronous work" concern by adding *asynchronous* complexity with zero benefit).

## 2. Two-pane layout breakpoint

- **Decision**: Reuse `EnjoyThemeTokens.breakpointRail` (currently `900`px), the same threshold that already switches `AppSidebar` on for primary app navigation (`docs/features/app-ui.md`: "Desktop (≥ 900 px): `AppSidebar`").
- **Rationale**: The spec's Assumptions section calls for reusing "the app's existing desktop/wide-layout breakpoint concept" rather than a new bespoke value, directly serving SC-003 (zero bespoke tokens). Using the same token the rest of the app already uses for "is this a desktop-width layout" keeps Settings visually and behaviorally consistent with the rest of the shell, and means a future breakpoint tuning pass only touches one token.
- **Alternatives considered**:
  - *New dedicated `breakpointSettingsRail` token* — rejected; would duplicate `breakpointRail` for no functional reason and risks the two thresholds drifting apart over time.
  - *`breakpointTranscriptSideBySide` (720px)* — rejected; that token is tuned for the player's video+transcript layout, a different content shape (16:9 video vs. a list + detail pane) with different minimum-width needs.

## 3. Section-collapse and rail-selection state persistence

- **Decision**: Ephemeral, in-memory Riverpod state (`settingsSectionCollapseProvider`, `settingsSelectedSectionProvider`) that resets each time the Settings hub is (re)opened; not persisted to Drift, secure storage, or shared preferences.
- **Rationale**: Matches the spec Assumption ("treated as ephemeral UI state for this change ... unless the plan phase determines persisting it is low-cost and worthwhile"). Evaluated persisting via the existing local preferences store: the marginal UX benefit (remembering which section was open) is low compared to the cost of adding a new persisted preference key, migration surface, and test matrix for a v1 visual redesign. Deferring persistence keeps this change strictly IA/visual as scoped, with no new Drift schema or preference keys.
- **Alternatives considered**:
  - *Persist via `AppPreferences`* — rejected for v1; flagged as a candidate low-risk follow-up if user feedback shows people want it remembered.

## 4. Shared card/list-row reuse vs. bespoke widgets

- **Decision**: Replace the private `_SettingsCard` / `_SettingsSubduedCard` with the existing shared `EnjoyCard` (`lib/core/theme/widgets/enjoy_card.dart`, already documented as a "grouped settings-style surface"). Keep the gradient account-hero treatment as-is since it already consumes `EnjoyThemeTokens.gradientStart/gradientEnd` tokens (not one-off hex).
- **Rationale**: `EnjoyCard` already exists specifically for this shape of UI and using it directly serves SC-003 (zero bespoke one-off colors/radii/spacing). The current `_SettingsCard` largely duplicates `EnjoyCard`'s intent (rounded surface, outline, tonal fill) with a slightly different gradient overlay that isn't reused anywhere else in the app — a sign it was one-off rather than a deliberate second card style.
- **Alternatives considered**:
  - *Keep `_SettingsCard`/`_SettingsSubduedCard` as-is, just re-theme colors* — rejected; doesn't reduce bespoke surface area and keeps two near-duplicate card implementations in the codebase.

## 5. Single source of truth for sections/rows (search + rail + collapse)

- **Decision**: One static registry describing every section and row (id, title key, section membership, collapsible-by-default flag) lives in `domain/settings_search_entry.dart` and is consumed by three places: the search filter, the two-pane rail item list, and the default-collapse logic.
- **Rationale**: The spec's edge cases explicitly call out those two failure modes (search must reach collapsed sections; a section must never look "clean" while actually containing an error). A single registry makes it structurally impossible for the rail, the search index, and the collapse defaults to drift out of sync, versus maintaining three separate hard-coded lists.
- **Alternatives considered**:
  - *Derive the registry by reflecting over the widget tree at runtime* — rejected; far more complex than declaring a small static list, and couples search indexing to widget lifecycle timing.

## 6. Testing approach for visual-only changes

- **Decision**: Automate everything that has an observable state contract (breakpoint switch, default collapse, search match/no-match/auto-expand, selection persistence across breakpoint changes) with widget tests; treat only *subjective* visual polish (spacing rhythm "feels" consistent, side-by-side comparison against Home/Library) as documented manual verification, per Constitution Principle II's explicit allowance for that when automation is impractical.
- **Rationale**: This directly satisfies QR-002 ("automated tests or a documented manual verification reason") without pretending pixel-level aesthetic judgment can be meaningfully unit-tested.
- **Alternatives considered**:
  - *Golden-image tests* — considered but not required for this change; the app has no existing golden-test harness for Settings, and introducing one is a larger investment than this redesign's scope warrants. Left as a documented future option rather than a blocking requirement.
