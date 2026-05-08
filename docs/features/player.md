# Feature: Player

## MVP behavior

- `PlayerController` owns playback via injectable `PlayerEngine` (production: `MediaKitPlayerEngine` wrapping a single `mk.Player`, ADR-0003).
- Restores position + echo flags from `echo_sessions`.
- Debounced persistence via `PlaybackSessionPersister`; embedded subtitle discovery via `EmbeddedTrackSync`.
- `PlayerUi` tracks chrome mode (mini vs expanded) only; playing/buffering come from `playerIsPlayingProvider` / `playerIsBufferingProvider` (stream providers over the engine).
- **Shell**: adaptive `NavigationBar` / `NavigationRail` + mini player; nav chrome is hidden on `/player/*` for focus.
- **Wide layout** (`VideoPlayerLayout`): draggable transcript width (min ~240px, max 50% of width), gradient video stage, no vertical divider between panels.
- Echo enforcement uses `lib/features/player/domain/echo_window.dart` (ported from web).

## Future

- Repeat modes (`RepeatMode` persisted — wiring to playback end events).
- Keyboard shortcuts / desktop menu integration.
