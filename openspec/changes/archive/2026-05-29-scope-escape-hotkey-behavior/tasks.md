## 1. Shared collapse helper

- [x] 1.1 Add `collapseExpandedPlayer(WidgetRef ref, BuildContext context)` in player application layer (e.g. `player_navigation.dart` or new `player_collapse.dart`)
- [x] 1.2 Refactor expanded player AppBar collapse buttons in `expanded_player_widgets.dart` to use the shared helper

## 2. Escape handler — scope modal.close

- [x] 2.1 Update `modal.close` ladder in `app_hotkeys_keyboard_listener.dart`: after Navigator overlay pops, skip `goRouter.pop()` when path starts with `/player/`
- [x] 2.2 When on `/player/...` with nothing to dismiss, consume Escape (`return true`) with no navigation side effects
- [x] 2.3 Keep `goRouter.pop()` fallback for non-player routes when no overlay remains
- [x] 2.4 Wire `player.toggleExpand` on player route through `collapseExpandedPlayer` instead of raw `collapse()` + `goRouter.pop()`

## 3. Shadow-reading recording cancel

- [x] 3.1 Set `isRecordingActive(true)` synchronously when user initiates recording (before async mic start) in `shadow_reading_panel.dart`
- [x] 3.2 Ensure `recordingCancel` listener runs when `_recording` is true even if `echoActive` gating would block it
- [x] 3.3 Verify `setRecordingActive(false)` on all cancel/stop/error paths remains correct

## 4. Tests

- [x] 4.1 Add unit/widget tests for Escape: overlay open → pops overlay, player route unchanged
- [x] 4.2 Add test: Escape on `/player/...` idle → no `GoRouter.pop`
- [x] 4.3 Add test: Escape during `isRecordingActive` → cancel pulse, no route pop
- [x] 4.4 Add test: Escape on non-player route with no overlay → `GoRouter.pop` when `canPop`
- [x] 4.5 Add test: `player.toggleExpand` on player route uses unified collapse (fullscreen exit + collapse + pop)

## 5. Documentation and verification

- [x] 5.1 Update `docs/features/hotkeys.md`: Escape dismisses overlays/recording/fullscreen; does not collapse player; collapse via button and `Ctrl+Shift+P`
- [x] 5.2 Update hotkeys cheatsheet l10n/description if Escape copy mentions player collapse
- [x] 5.3 Run `flutter analyze` and `flutter test`; fix regressions
