# Phase 1 Data Model: Settings Redesign

No Drift schema changes and no new persisted entities. Everything below is in-memory presentation/application state scoped to the Settings hub's lifetime, backing the `SettingsSection`/`SettingsRow` entities already declared in [spec.md](./spec.md#key-entities-include-if-feature-involves-data).

## `SettingsSearchEntry` (domain, pure Dart)

Static registry item — one per row (and one per section header, so section titles are searchable too).

| Field | Type | Notes |
|---|---|---|
| `sectionId` | `String` | Stable id, e.g. `account`, `cloudSync`, `appearanceLanguage`, `aiProviders`, `recording`, `keyboardShortcuts`, `developer`, `about`. |
| `rowId` | `String?` | Null for a section-header entry; otherwise a stable id like `displayLanguage`, `learningLanguage`, `micPicker`, `hotkeysOpenCheatsheet`. |
| `title` | `String` | Already-localized display title (resolved from `AppLocalizations` at build time — the registry itself holds no hard-coded English strings, only a `titleBuilder(AppLocalizations l10n) -> String` function reference, so localization stays in ARB per QR-003/FR-009). |
| `keywords` | `List<String>` | Optional extra localized synonyms (e.g. `micPicker` row also matches "microphone", "audio input"). |
| `collapsedByDefault` | `bool` | Section-header entries only; `true` for `developer` and `about`, `false` for everything else (FR-012). |

**Validation rules**:
- Every row in the current `SettingsScreen` implementation MUST have exactly one corresponding entry (enforced by the widget test asserting registry size matches the rendered row count — see [quickstart.md](./quickstart.md)).
- `rowId` MUST be unique within a `sectionId`.

**State transitions**: None — this is a static, build-time-constant list; it does not change at runtime (it doesn't need to, since visibility/gating is applied when *rendering* a row, not when *indexing* it — see `settings-search.md` contract for how gated rows are handled).

## `SettingsSearchQuery` (application state)

| Field | Type | Notes |
|---|---|---|
| `query` | `String` | Current text in `SettingsSearchField`. Empty string = no filter (show normal grouped view). |

Backed by `settingsSearchQueryProvider` (`@riverpod`, simple string notifier). Ephemeral — resets when the hub is disposed (per `research.md` §3).

## `SettingsSectionCollapseState` (application state)

| Field | Type | Notes |
|---|---|---|
| `collapsed` | `Map<String, bool>` | Keyed by `sectionId`. Missing key = fall back to that section's `SettingsSearchEntry.collapsedByDefault`. |

Backed by `settingsSectionCollapseProvider` (`@riverpod`, `Map<String, bool>` notifier with a `toggle(sectionId)` method). Ephemeral — resets on hub reopen (per `research.md` §3). A section entering an error/warning state (e.g. a failed developer API URL save) does not change this map — the *badge* is a rendering concern layered on top by `SettingsCollapsibleSection`, not a forced state change, so a user's manual expand/collapse choice is never silently overridden.

## `SettingsSelectedSection` (application state, two-pane layout only)

| Field | Type | Notes |
|---|---|---|
| `sectionId` | `String` | Currently selected rail item in the two-pane layout. Defaults to the first section (`account`). |

Backed by `settingsSelectedSectionProvider` (`@riverpod`, simple string notifier). Persists across a breakpoint crossing (single-column ↔ two-pane) so re-entering two-pane mode restores the same detail pane (FR-011, SC-008) — in single-column mode this value is unused (every section renders in the scrolling column) but is not reset, so the *next* switch to two-pane mode is seamless.

## `SettingsLayoutMode` (derived, not stored)

```dart
enum SettingsLayoutMode { singleColumn, twoPane }
```

Derived per-build from `MediaQuery`/`LayoutBuilder` width vs. `EnjoyThemeTokens.breakpointRail` — not itself a provider, to avoid a redundant second source of truth for something Flutter's layout system already gives for free.

## Relationships

```text
SettingsSearchEntry (static registry, N entries)
   ├── grouped by sectionId → rendered as SettingsSection headers (rail items in two-pane, headers in single-column)
   ├── filtered by SettingsSearchQuery.query → visible subset when searching
   └── collapsedByDefault seeds SettingsSectionCollapseState on first read (per section, if no explicit entry yet)

SettingsSelectedSection.sectionId ──(two-pane only)──> which section's rows render in the detail pane
SettingsLayoutMode ──(derived)──> chooses SettingsLayoutTwoPane vs SettingsLayoutSingleColumn
```
