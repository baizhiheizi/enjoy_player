# Hotkeys

Keyboard shortcuts mirror the Enjoy web app defaults (`stores/hotkeys.ts`). Custom bindings are stored in Drift settings KV under key `hotkeys_custom_bindings` as JSON `{ "actionId": "ctrl+k", ... }`.

## Behavior

- **Global** shortcuts are evaluated whenever no editable field has focus (`EditableText`).
- **Modal / Escape**: When the shortcuts cheatsheet is open, `Escape` dismisses it via the root `Navigator`. On desktop, if the window is fullscreen, `Escape` exits fullscreen next. While a shadow-reading take is actively recording (including mic permission / start pending), `Escape` cancels that recording (discard temp WAV). When a modal bottom sheet or dialog is open, `Escape` pops the top **`PopupRoute`** — first on the **shell** nested navigator (`enjoyShellNavigatorKey`), then on the root navigator. Pushed GoRouter pages alone are **not** treated as overlays. **Escape does not collapse the expanded player** when no overlay applies — use the collapse chevron or `player.toggleExpand` (default `Ctrl+Shift+P`). On non-player routes, `Escape` may still pop the GoRouter stack when nothing else applies. Mobile system Back does not use this ladder; it follows normal Navigator pop semantics.
- **Help / cheatsheet**: `global.help` (default `Shift+/` → `?`) opens `HotkeysHelpDialog`; pressing the same chord again closes it. Open state is tracked via `hotkeysCheatsheetOpen` (`lib/features/hotkeys/presentation/hotkeys_cheatsheet_open.dart`) so the hotkey and Settings “Open shortcuts cheatsheet” stay in sync. The cheatsheet also handles `Escape` in its focus scope. UI is search-first (autofocus filter, compact title + close), with muted scope labels and an adaptive **one- or two-column** shortcut grid (two columns when the list is wide enough). Footer keeps the open-list hint and **Customize shortcuts**.
- **Library** `/`: on desktop shell browse routes (Home, Library, Cloud, Settings — not the expanded player), focuses library search and navigates to `/library` when needed so filtered results are visible. On **wide** layouts the sidebar field receives focus; on **narrow** layouts the compact Library search field receives focus after navigation. Clicking or tabbing into the sidebar search also navigates to Library.
- **Player** shortcuts apply when a playback session exists (`playerControllerProvider`).
- **Echo brackets**: expand/shrink apply only when Echo mode is active (handled inside `PlayerInteractions`).
- **Shadow reading**: `R` / `G` / `P` / `V` pulse a Riverpod bus consumed by `ShadowReadingPanel` / `PitchContourSection`. `Escape` during an active recording cancels via the same bus (`recordingCancel` / `isRecordingActive`). Assessment (`V`) runs the same flow as the shadow-reading **assess** control (view result if already assessed, otherwise run). `H` toggles listening-focus (blur practice).

## Customization

Settings → **Keyboard shortcuts** → **Customize shortcuts** opens `/settings/keyboard` with filter, per-row edit/reset, and reset-all in the app bar (confirmation required). Editor rows use fixed **chord** and **action** columns so keycaps and edit/reset icons align vertically; scope labels match the cheatsheet’s muted style. From the cheatsheet, **Customize shortcuts** navigates to the same screen. Legacy `/settings?section=keyboard` redirects to `/settings/keyboard` on desktop. The capture dialog shows **live chord text** (including invalid attempts) with screen-reader semantics. Reset per row or reset all restores defaults. The cheatsheet dialog is up to **`contentMaxWidth` (720)** wide and **85%** of viewport height so the two-column grid and large text scales remain usable.

## Implementation entry points

- Definitions: `lib/features/hotkeys/domain/hotkey_definitions.dart`
- Persistence: `lib/features/hotkeys/application/hotkeys_ctrl.dart`
- Dispatch: `lib/features/hotkeys/presentation/app_hotkeys_keyboard_listener.dart` (`HardwareKeyboard.addHandler`); Escape priority in `lib/features/hotkeys/application/escape_dismissal.dart` (`navigatorHasTopPopupRoute` on shell then root via `GlobalKey.currentState`). Shell key: `enjoyShellNavigatorKey` in `lib/core/routing/app_router.dart`. Mounted via **`MaterialApp.router`'s `builder`** so the listener sits **under** `MaterialApp` / GoRouter (valid overlay + `ref.read(appRouterProvider)` for path/navigation — avoids `GoRouterState.of(context)` when context was above the router).
- Player collapse helper: `lib/features/player/application/player_collapse.dart`
- Cheatsheet UI: `lib/features/hotkeys/presentation/hotkeys_help_dialog.dart` (`showHotkeysHelpDialog`)
