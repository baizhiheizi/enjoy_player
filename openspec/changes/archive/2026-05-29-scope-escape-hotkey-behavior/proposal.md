## Why

The `Escape` key is overloaded as a global priority ladder in `AppHotkeysKeyboardListener`: dismiss overlays, exit fullscreen, cancel shadow-reading capture, and—when nothing else matches—`GoRouter.pop()`, which collapses the expanded player. That fallback is fragile (Navigator vs GoRouter ordering, missed overlays, recording-bus timing) and produces bugs where Escape collapses the player while a sheet is still open or cancels the wrong action. Collapse should be an explicit navigation action, not an accidental side effect of modal dismissal.

## What Changes

- **Scope `modal.close` (Escape)** to dismiss transient UI only: cheatsheet, fullscreen, active recording cancel, and Navigator overlays (sheets/dialogs). **Do not** `GoRouter.pop()` when the current route is `/player/...` and no overlay remains.
- **Keep player collapse** on explicit affordances only: collapse chevron button and `player.toggleExpand` (default `Ctrl+Shift+P`).
- **Unify collapse behavior** when collapse *is* triggered (button or toggleExpand): exit fullscreen, call `playerUiProvider.collapse()`, then pop the player route—matching the existing AppBar handler.
- **Harden recording cancel on Escape**: set `isRecordingActive` synchronously when capture starts; ensure cancel works even if `ShadowReadingPanel` echo gating would otherwise ignore the pulse.
- **Allow `GoRouter.pop()` on Escape** for non-player routes (e.g. pushed sign-in) when no overlay remains.
- Update **hotkeys feature docs** and cheatsheet copy to reflect the new Escape semantics.
- **BREAKING (desktop UX)**: Escape no longer collapses the expanded player when no modal/sheet/recording/fullscreen is active. Users rely on the collapse button or `Ctrl+Shift+P`.

## Capabilities

### New Capabilities

- `escape-dismissal`: Scoped Escape behavior—overlay/fullscreen/recording dismissal with explicit rules for when route navigation is allowed vs blocked on the player route.

### Modified Capabilities

<!-- No existing openspec/specs capabilities yet. Behavior delta captured in change-local spec and docs/features/hotkeys.md during implementation. -->

## Impact

- **Hotkeys dispatch**: `lib/features/hotkeys/presentation/app_hotkeys_keyboard_listener.dart` — revise `modal.close` ladder; align `player.toggleExpand` with collapse button.
- **Shadow reading**: `shadow_reading_panel.dart`, `shadow_reading_hotkey_bus.dart` — recording-active timing and cancel handling.
- **Player UI**: `expanded_player_widgets.dart` — optional shared `collapsePlayer()` helper to DRY button/toggleExpand paths.
- **Docs**: `docs/features/hotkeys.md` — Escape no longer collapses player; collapse shortcuts documented.
- **Tests**: Widget/unit tests for Escape priority (sheet open → pop sheet not player; player idle → no-op; recording → cancel; non-player route → pop).
