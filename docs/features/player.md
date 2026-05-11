# Feature: Player

## MVP behavior

- `PlayerController` owns playback via injectable `PlayerEngine` (production: `MediaKitPlayerEngine` wrapping a single `mk.Player`, ADR-0003). Open flow is split for clarity:
  - [`resolvePlaybackOpen`](../../lib/features/player/application/playback_open_resolver.dart) — loads rows + `PlayableSource`, throws `MediaNeedsRelocateException` when needed.
  - [`ensureEngineForPlayableSource`](../../lib/features/player/application/player_engine_binding.dart) — swaps MediaKit vs YouTube engine and bumps `playerEngineRevProvider`.
  - [`schedulePlayerOpenSideEffects`](../../lib/features/player/application/player_open_side_effects.dart) — cloud transcript fetch + recording pull when signed in.
  - [`VideoPosterCaptureService`](../../lib/features/player/application/video_poster_capture_service.dart) — optional JPEG poster capture + Drift thumbnail update.
- Restores position + echo flags from `echo_sessions`.
- Debounced persistence via `PlaybackSessionPersister`; embedded subtitle discovery via `EmbeddedTrackSync`.
- `PlayerUi` tracks chrome mode (mini vs expanded) for expand/collapse side effects; route `/player/:id` still drives most visible chrome. Playing/buffering come from `playerIsPlayingProvider` / `playerIsBufferingProvider` (stream providers over the engine, each seeded with `Player.state` so the transport bar matches the engine immediately after route changes).
- Re-opening `/player/:mediaId` while that media is already the active session does **not** call `openUri` again (avoids restarting playback when expanding from the mini player).
- **Video library poster**: when a `VideoRow` has no `http(s)` `thumbnail_url` and no readable local thumbnail file, after open `VideoPosterCaptureService` may capture a JPEG via `PlayerEngine.screenshot` (`image/jpeg`) and write `media_thumbs/<key>.jpg`, then patch Drift (see `library.md`). Remote artwork URLs are never overwritten.
- **Synced local-only media**: If metadata was synced from another device but this machine has no file at `localUri`, and the row has a content fingerprint (`md5` column — SHA-256 hex), opening the player shows **Locate media file**. The user picks the same file; the app imports it only when the hash matches, then updates `localUri` and enqueues a sync update.
- **Shell**: adaptive `NavigationBar` / `NavigationRail` + mini player; nav chrome is hidden on `/player/*` for focus.
- **Wide layout** (`VideoPlayerLayout`): draggable transcript width (min ~240px, max 50% of width), gradient video stage, no vertical divider between panels.
- Echo enforcement uses `lib/features/player/domain/echo_window.dart` (ported from web).

## Presentation

- **Global transport** — composed from [`presentation/widgets/transport/`](../../lib/features/player/presentation/widgets/transport/) (progress strip, volume popover, artwork/meta, CC, fullscreen, play ring). [`GlobalTransportBar`](../../lib/features/player/presentation/widgets/global_transport_bar.dart) wires Riverpod + routing only.
- **Expanded player** — [`ExpandedPlayerChromeBody`](../../lib/features/player/presentation/expanded_player_widgets.dart) + loading/error bodies; YouTube account affordance uses [`playerYoutubeLoginChromeSupportedProvider`](../../lib/features/player/application/player_engine_capabilities_provider.dart) so UI does not depend on concrete engine types.

## Engine contract (ADR-0015)

- `PlayerEngine` continues to expose **`buildVideoStage`** alongside transport commands so YouTube can keep a **single long-lived** `InAppWebView` (no `Key` by `videoId`) without duplicating lifecycle between layers. Splitting a separate “video surface factory” from playback ports would be possible later but is **not** planned unless tests or reuse demand it — the WebView ordering constraints are easy to regress.

## Fullscreen (desktop)

- The transport bar shows a fullscreen toggle button for video on Windows/macOS/Linux. The button is hidden for audio and on non-desktop platforms.
- F11 (customizable) also toggles fullscreen when a video session is active.
- Pressing Escape while fullscreen exits fullscreen first; a second Escape then pops the route/dialog as normal.
- Collapsing the expanded player (via the back arrow or `Ctrl+Shift+P`) also exits fullscreen automatically.

## Future

- Repeat modes (`RepeatMode` persisted — wiring to playback end events).
- Keyboard shortcuts / desktop menu integration.
