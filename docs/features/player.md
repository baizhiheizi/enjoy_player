# Feature: Player

## MVP behavior

- `PlayerController` owns playback via injectable `PlayerEngine` (production: `MediaKitPlayerEngine` wrapping a single `mk.Player`, ADR-0003).
- Restores position + echo flags from `echo_sessions`.
- Debounced persistence via `PlaybackSessionPersister`; embedded subtitle discovery via `EmbeddedTrackSync`.
- `PlayerUi` tracks chrome mode (mini vs expanded) only; playing/buffering come from `playerIsPlayingProvider` / `playerIsBufferingProvider` (stream providers over the engine, each seeded with `Player.state` so the transport bar matches the engine immediately after route changes).
- Re-opening `/player/:mediaId` while that media is already the active session does **not** call `openUri` again (avoids restarting playback when expanding from the mini player).
- **Synced local-only media**: If metadata was synced from another device but this machine has no file at `localUri`, and the row has a content fingerprint (`md5` column — SHA-256 hex), opening the player shows **Locate media file**. The user picks the same file; the app imports it only when the hash matches, then updates `localUri` and enqueues a sync update.
- **Shell**: adaptive `NavigationBar` / `NavigationRail` + mini player; nav chrome is hidden on `/player/*` for focus.
- **Wide layout** (`VideoPlayerLayout`): draggable transcript width (min ~240px, max 50% of width), gradient video stage, no vertical divider between panels.
- Echo enforcement uses `lib/features/player/domain/echo_window.dart` (ported from web).

## Fullscreen (desktop)

- The transport bar shows a fullscreen toggle button for video on Windows/macOS/Linux. The button is hidden for audio and on non-desktop platforms.
- F11 (customizable) also toggles fullscreen when a video session is active.
- Pressing Escape while fullscreen exits fullscreen first; a second Escape then pops the route/dialog as normal.
- Collapsing the expanded player (via the back arrow or `Ctrl+Shift+P`) also exits fullscreen automatically.

## Future

- Repeat modes (`RepeatMode` persisted — wiring to playback end events).
- Keyboard shortcuts / desktop menu integration.
