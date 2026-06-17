## Why

YouTube playback in Enjoy Player feels slow to initialize compared to lightweight feed apps (e.g. Folo) because the app loads the full `m.youtube.com/watch` page in a cold WebView on every open. A direct switch to the embed player is not viable — `youtube-nocookie.com/embed/…` fails with **Error 153** (missing embed identity / Referer in native WebViews). ADR-0015’s watch-page approach remains correct; we need to optimize **perceived and actual init time** without changing the playback URL strategy.

## What Changes

- Show **stored YouTube thumbnail artwork** over the video stage while the WebView is loading or buffering (poster overlay until first frame / `canplay`).
- Show **YouTube artwork during the expanded-player loading skeleton** when opening a YouTube row (instead of a generic bootstrap skeleton only).
- **Mount the YouTube WebView earlier** in the open pipeline so WebView cold-start overlaps with `openMedia()` work (DB resolve, engine swap, seek restore).
- **Keep the YouTube engine warm** between sessions: stop playback on dismiss but avoid disposing the WebView process on every `clear()`; reuse on next YouTube open.
- Implement **`warmVideoSurface()` for YouTube** — optional pre-warm when the user taps a YouTube library/discover row (before navigation completes).
- Add lightweight **init timing logs** (fine level) to measure WebView create → load → first `playing` for future tuning.
- **Out of scope**: embed / IFrame API migration, `-nocookie` URL, new packages (`youtube_player_iframe`), or changing echo/transport semantics.

## Capabilities

### New Capabilities

- `youtube-playback-init`: Requirements for faster perceived and actual YouTube player initialization while retaining the mobile watch-page engine (ADR-0015).

### Modified Capabilities

<!-- No existing OpenSpec capability covers YouTube playback init. docs/features/youtube.md will be updated during implementation. -->

## Impact

- `lib/features/player/application/engines/youtube/` — engine lifecycle, video stage widget, warm/preload hooks.
- `lib/features/player/application/player_controller.dart` — `clear()` YouTube engine retention policy.
- `lib/features/player/presentation/expanded_player_widgets.dart` — loading body artwork for YouTube rows.
- `lib/features/library/` and `lib/features/discover/` — optional tap-to-warm hook before route navigation.
- `docs/features/youtube.md` — document init behavior and warm-session semantics.
- Tests: player controller clear/warm behavior, poster overlay visibility tied to buffering state.
