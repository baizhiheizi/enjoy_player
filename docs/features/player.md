# Feature: Player

## MVP behavior

- `PlayerController` opens `Media(uri)` from stored `sourceUri`.
- Restores position + echo flags from `playback_sessions`.
- Debounced persistence while playing.
- `PlayerUi` tracks chrome mode (mini vs expanded); playing/buffering synced from `Player` streams in `RootShell`.
- Echo enforcement uses `lib/features/player/domain/echo_window.dart` (ported from web).

## Future

- Repeat modes (`RepeatMode` persisted — wiring to playback end events).
- Keyboard shortcuts / desktop menu integration.
