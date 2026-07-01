# UI Contract: Settings Search / Filter

**Implements**: FR-010, SC-007, and the "search matches nothing" / "search must reach collapsed sections" edge cases from [spec.md](../spec.md).

## Contract

1. **Input**: `SettingsSearchField` is a single text field rendered at the top of the hub (both single-column and two-pane layouts). It writes to `settingsSearchQueryProvider` on every change — no submit button required.
2. **Matching**: `filterSettingsEntries(query, entries)` performs a case-insensitive substring match against each visible `SettingsSearchEntry.title` (already-localized) and its `keywords`. An empty/whitespace-only query returns every entry unfiltered (i.e., "no active filter" — this is the default state, not a zero-results state).
3. **Result rendering**:
   - **Single-column layout**: sections with zero matching rows collapse out of view entirely while a query is active; sections with at least one match render with only the matching rows visible, and the section auto-expands even if it was collapsed by default or by the user.
   - **Two-pane layout**: the rail shows only sections with at least one match; if the currently-selected rail section has zero matches while a query is active, selection automatically moves to the first section that does match.
4. **No-results state**: if the query is non-empty and zero entries match across every section, the hub shows a dedicated empty state (icon + "No settings found for '{query}'" message + a visible "Clear" affordance that resets the query) instead of an empty screen or a blank list.
5. **Clearing**: clearing the query (manually, via the "Clear" affordance, or via a trailing clear icon on the field itself once non-empty) restores the normal grouped view, including restoring each section's collapse state to whatever it was before the search began (default-collapsed sections collapse again; a section the user had manually expanded stays expanded — searching never permanently changes a user's manual collapse choice).
6. **Scope**: search only ever indexes rows that are currently visible per the platform/auth/build-mode gating rules described in [settings-section-registry.md](./settings-section-registry.md) — a hidden row is never a valid search result.

## Out of scope

- No search history, no recent/suggested queries, no fuzzy/typo-tolerant matching (see [research.md](../research.md) §1) — substring match only, per the spec's Assumptions.
- No server-side or cross-device search — this is local to the current session's rendered registry.
