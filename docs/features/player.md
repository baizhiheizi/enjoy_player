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
- **Video library poster**: when a `VideoRow` has no `http(s)` `thumbnail_url` and no readable local thumbnail file, after open `VideoPosterCaptureService` may capture a JPEG via `PlayerEngine.screenshot` (`image/jpeg`) and write `media_thumbs/<key>.jpg`, then patch Drift (see `library.md`). Remote artwork URLs are never overwritten. If the temporary seek used to grab the frame fails to restore back to position zero afterward, that failure is logged at **WARNING** with the grep-friendly message `video poster capture failed to restore seek-zero position` (previously a nested empty `catch` silently swallowed it).
- **Synced local-only media**: If metadata was synced from another device but this machine has no file at `localUri`, and the row has a content fingerprint (`md5` column — SHA-256 hex), opening the player shows **Locate media file**. The user picks the same file; the app imports it only when the hash matches, then updates `localUri` and enqueues a sync update.
- **Shell**: `EnjoyBottomNav` on compact widths, `AppSidebar` from ~900px + mini player; nav chrome is hidden on `/player/*` for focus.
- **Wide layout** (`VideoPlayerLayout`): when width **>** `breakpointTranscriptSideBySide` (720), video and transcript are **side-by-side** (portrait-wide tablets included). Below that breakpoint, **stacked** video (16:9 stage) over transcript. Draggable split: transcript column min **360** logical px (capped at 50% width); split width is **persisted** in player preferences (`splitPx`). Transcript panel uses a subtle **1px** left border on the zinc surface; video stage is letterboxed on black with **top SafeArea** padding on the narrow stacked layout.
- **Expanded video (narrow)**: while actively playing (not buffering), there is no reserved `AppBar` height; when **paused or buffering**, back/title/YouTube login chrome is drawn in a **top overlay** (same gradient as before) so the 16:9 stage does not shift. Audio still uses a normal `AppBar` when paused (title + back).
- Echo enforcement uses `lib/features/player/domain/echo_window.dart` (ported from web).

## Presentation

- **Global transport** — composed from [`presentation/widgets/transport/`](../../lib/features/player/presentation/widgets/transport/) (progress strip, volume popover, artwork/meta, CC, fullscreen, play ring). [`GlobalTransportBar`](../../lib/features/player/presentation/widgets/global_transport_bar.dart) wires Riverpod + routing only. Playback speed opens an **Enjoy** bottom sheet (`showEnjoySheet` + drag handle) rather than a stock `PopupMenuButton`. When the user is **not** on `/player/...` (collapsed shell / “mini” transport), **swipe down** on the bar dismisses it: stops playback via `PlayerController.clear()`, resets `PlayerUi`, and clears the active session.
- **Line-level transport** — previous line, next line, replay line, and echo mode are disabled when there is no primary transcript (empty or still loading); the echo button stays enabled while echo mode is active so the user can exit echo without transcript lines. On **narrow layouts** (≤720px), the bar always shows **previous** and **next** when a transcript is loaded (compact 40px slots); **replay** is omitted from the bar (tap the active transcript line or use hotkeys). When width is still tight, **expand** (mini transport) and **volume** defer before line navigation.
- **Expanded player** — [`ExpandedPlayerChromeBody`](../../lib/features/player/presentation/expanded_player_widgets.dart) + loading/error bodies; YouTube account affordance uses [`playerYoutubeLoginChromeSupportedProvider`](../../lib/features/player/application/player_engine_capabilities_provider.dart) so UI does not depend on concrete engine types. Local video uses [`playerEngineProvider`](../../lib/features/player/application/player_engine_provider.dart) for the active engine (same instance as the controller’s engine, including test doubles).

## Engine contract (ADR-0015)

- `PlayerEngine` continues to expose **`buildVideoStage`** alongside transport commands so YouTube can keep a **single long-lived** `InAppWebView` (no `Key` by `videoId`) without duplicating lifecycle between layers. Splitting a separate “video surface factory” from playback ports would be possible later but is **not** planned unless tests or reuse demand it — the WebView ordering constraints are easy to regress.
- **`supportsSubtitleDisabling`** tells the open coordinator whether `disableRenderedSubtitles()` is meaningful for the active engine. `MediaKitPlayerEngine` returns `true` (it owns the libmpv embedded track list); `YoutubePlayerEngine` returns `false` because the WebView watch page renders its own captions and there is no engine-side track to disable — the open coordinator short-circuits the await on YouTube opens. Callers that need to gate UI on this capability should read it instead of branching on engine type.

## Fullscreen (desktop)

- The transport bar shows a fullscreen toggle button for video on Windows/macOS/Linux. The button is hidden for audio and on non-desktop platforms.
- F11 (customizable) also toggles fullscreen when a video session is active.
- Pressing Escape while fullscreen exits fullscreen first; a second Escape then pops the route/dialog as normal.
- Collapsing the expanded player (via the back arrow or `Ctrl+Shift+P`) also exits fullscreen automatically.

## Future

- Repeat modes (`RepeatMode` persisted — wiring to playback end events).
- Keyboard shortcuts / desktop menu integration.

## Position quantization (single source of truth)

`lib/features/player/application/position_buckets.dart` consolidates the three position quantization buckets into named constants. Do not inline these values in feature code — the per-bucket split keeps the transport scrubber responsive while the transcript highlight avoids per-tick rebuilds that flood the Windows accessibility bridge (flutter/flutter#182444). See `quantized_position.dart` for the dedup behavior.

| Constant | Value | Used by |
|----------|------:|---------|
| `kPositionBucketEchoApplyMs` | 400 | Echo window apply — echo enforcement snaps to 400 ms ticks so the recorded clip window lines up across runs |
| `kPositionBucketDisplayMs` | 400 | Time display + transcript active-line highlight — 400 ms matches human-perceptible cue changes |
| `kPositionBucketScrubberMs` | 50 | Transport scrubber position updates — finer bucket keeps the slider tracking finger drags without regressing accessibility |

## Open / close behavior

- **`PlayerController.openMedia`** catches exceptions from `engine.open` and any downstream awaits so a failed open does not leave `state` pointing at a phantom session. The player surfaces the error to the existing failure path (`AsyncValue.error`) rather than masking it with stale session metadata.
- **`PlayerController.clear()`** flushes the pending `PlaybackSessionPersister` write **before** cancelling the debounce timer, so a swipe-to-dismiss does not lose the last ~450 ms of position updates. Tests for the persister should cover the "dismiss while debounced write is queued" case explicitly.
