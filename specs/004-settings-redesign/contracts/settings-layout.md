# UI Contract: Settings Two-Pane / Single-Column Layout Switch

**Implements**: FR-011, SC-008, and the "resize repeatedly across the breakpoint" edge case from [spec.md](../spec.md).

## Contract

1. **Breakpoint**: The hub renders `SettingsLayoutTwoPane` when the available width is **≥** `EnjoyThemeTokens.breakpointRail` (900px today — see [research.md](../research.md) §2), and `SettingsLayoutSingleColumn` below that width. This is the same token that already decides `AppSidebar` vs. mobile navigation, so Settings' layout switch always agrees with the rest of the app's shell about what counts as "desktop-width."
2. **Two-pane structure**:
   - **Left rail** (fixed width, consistent with `EnjoyThemeTokens.sidebarWidth`-scale proportions): search field at the top, then one row per visible section (icon + title), ending with the collapsible Developer/About group. The currently-selected section is visually highlighted (per the app's existing selected-nav-item treatment).
   - **Right detail pane**: the selected section's header (icon, title, hint) followed by its rows, using the same `SettingsRow`/`SettingsSectionCard` primitives as the single-column layout.
3. **Single-column structure**: unchanged ordering from today (Account → Cloud sync → Appearance & Language → AI providers → Recording → Keyboard shortcuts → Developer → About), restyled with `SettingsSectionCard`/`SettingsRow`, with Developer and About rendering collapsed by default (FR-012).
4. **State continuity across the breakpoint**:
   - The selected section (`settingsSelectedSectionProvider`) is read by two-pane mode and otherwise idle in single-column mode — it is **never reset** by a layout switch in either direction.
   - Crossing the breakpoint repeatedly (e.g. dragging a desktop window's edge back and forth) MUST NOT cause visible flicker, a dropped selection, or a lost scroll position (SC-008) — this is verified by a widget test that resizes the test surface across the threshold multiple times in a row and asserts the selected section and rendered content stay stable except for the intended layout shape change.
5. **Accessibility/interaction parity**: both layouts expose the same keyboard focus order semantics and touch targets — the two-pane rail's items are focusable/tappable exactly like the single-column section headers, and the detail pane's rows behave identically to the single-column rows (same `SettingsRow` widget, just placed differently).

## Out of scope

- No user-facing toggle to force one layout regardless of width — the switch is purely width-driven, matching how `AppSidebar` already works.
- No persistence of the last-used layout mode across app restarts (it's derived from window size every time, per `data-model.md`'s `SettingsLayoutMode`).
