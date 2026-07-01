# UI Contract: Settings Section/Row Registry

**Consumers**: `SettingsLayoutSingleColumn`, `SettingsLayoutTwoPane` (rail), `SettingsSearchField` (index), `SettingsCollapsibleSection` (default-collapse state).

## Contract

1. There is exactly **one** static list of `SettingsSearchEntry` (see [data-model.md](../data-model.md)) that every consumer above reads from. No consumer may maintain its own hard-coded copy of section/row titles or ids.
2. Every row currently rendered by `SettingsScreen` (Account, Cloud sync, Appearance & Language ×3 rows, AI providers, Recording, Keyboard shortcuts ×2 rows, Developer ×3 rows, About) MUST have exactly one registry entry. Adding a row to a section in code without adding its registry entry is a contract violation (caught by the widget test described in [quickstart.md](../quickstart.md)).
3. A registry entry's `title` is resolved through `AppLocalizations` at read time — the registry never hard-codes an English string, so it stays correct across locale switches without a rebuild of the registry itself.
4. Conditional visibility (desktop-only keyboard shortcuts, debug-only developer tools, learning-language capability gating, signed-in vs signed-out copy) is applied by the **rendering** widget for that row, not by removing the row from the registry. This means:
   - A row that's currently hidden (e.g. Keyboard shortcuts on a mobile build) MUST NOT appear in search results or the rail on that build.
   - The registry itself can stay platform/state-agnostic; each consumer filters the registry against current app state (platform, auth state, build mode) before use, using the exact same predicates `SettingsScreen` uses today (FR-005/FR-006 — no new gating logic, just relocated).
5. `sectionId` and `rowId` values are stable identifiers (not display strings) and MUST NOT change once introduced, since they may be referenced by `settingsSelectedSectionProvider` / `settingsSectionCollapseProvider` state that could theoretically outlive a single build (e.g. via widget rebuilds during a session).

## Non-goals

- This registry does not gate whether a *feature* exists (e.g. it doesn't decide whether AI providers are BYOK-capable) — it only describes what's discoverable in the Settings hub's IA. Feature-level capability logic stays exactly where it lives today.
