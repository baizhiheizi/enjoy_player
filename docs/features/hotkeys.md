# Hotkeys

Keyboard shortcuts mirror the Enjoy web app defaults (`stores/hotkeys.ts`). Custom bindings are stored in Drift settings KV under key `hotkeys_custom_bindings` as JSON `{ "actionId": "ctrl+k", ... }`.

## Behavior

- **Global** shortcuts are evaluated whenever no editable field has focus (`EditableText`).
- **Modal**: `Escape` pops the top dialog/route when possible.
- **Library** `/`: focuses the sidebar search field when the wide layout with sidebar is visible. Narrow layouts without the sidebar have no search focus target yet.
- **Player** shortcuts apply when a playback session exists (`playerControllerProvider`).
- **Echo brackets**: expand/shrink apply only when Echo mode is active (handled inside `PlayerInteractions`).
- **Shadow reading**: `R` / `G` / `P` / `V` pulse a Riverpod bus consumed by `ShadowReadingPanel` / `PitchContourSection`. Assessment (`V`) shows a stub snackbar until pronunciation assessment UI exists. Dictation (`H`) is reserved (no UI yet).

## Customization

Settings → **Keyboard shortcuts**: tap a row to capture a new chord; conflicts show an error snackbar. Reset per row or reset all restores defaults.

## Implementation entry points

- Definitions: `lib/features/hotkeys/domain/hotkey_definitions.dart`
- Persistence: `lib/features/hotkeys/application/hotkeys_ctrl.dart`
- Dispatch: `lib/features/hotkeys/presentation/app_hotkeys_keyboard_listener.dart` (`HardwareKeyboard.addHandler`). Mounted via **`MaterialApp.router`'s `builder`** so the listener sits **under** `MaterialApp` / GoRouter (valid overlay + `ref.read(appRouterProvider)` for path/navigation — avoids `GoRouterState.of(context)` when context was above the router).
