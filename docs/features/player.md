# Feature: Player

## MVP behavior

- `PlayerController` opens `Media(uri)` from stored `sourceUri`.
- Restores position + echo flags from `playback_sessions`.
- Debounced persistence while playing.
- `PlayerUi` tracks chrome mode (mini vs expanded); playing/buffering synced from `Player` streams in `RootShell`.
- **Shell**: adaptive `NavigationBar` / `NavigationRail` + mini player; nav chrome is hidden on `/player/*` for focus.
- **Wide layout** (`VideoPlayerLayout`): draggable transcript width (min ~240px, max 50% of width), gradient video stage, no vertical divider between panels.
- Echo enforcement uses `lib/features/player/domain/echo_window.dart` (ported from web).

## Future

- Repeat modes (`RepeatMode` persisted — wiring to playback end events).
- Keyboard shortcuts / desktop menu integration.
