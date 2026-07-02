# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- **Windows deep links**: PKCE sign-in callbacks no longer spawn a stray second window. The installer-registered `enjoyplayer://` protocol previously launched a fresh `enjoy_player.exe` per click; that process had no in-memory PKCE state, so the original window was stuck waiting and a second window was left open. `windows/runner/main.cpp` now detects an already-running instance via `FindWindow(L"FLUTTER_RUNNER_WIN32_WINDOW", L"Enjoy Player")`, forwards the URI to it through `app_links`'s `SendAppLink` (`WM_COPYDATA`), restores/foregrounds that window, and exits. See [docs/features/auth.md](docs/features/auth.md#deep-links-pkce-callback).

## [0.3.0] - 2026-07-01

### Added

- NotFoundScreen fallback route for unknown go_router locations (en/zh/zh-CN localized).
- GitHub issue templates (`bug`, `feature`, `chore`) and a PR template at `.github/`.
- `PlayerEngine.supportsSubtitleDisabling` to skip the no-op `disableRenderedSubtitles` await on YouTube opens.
- `kPositionBucketEchoApplyMs`, `kPositionBucketDisplayMs`, `kPositionBucketScrubberMs` constants in `lib/features/player/application/position_buckets.dart` consolidating three previously inline quantization values.
- `SyncMissingUpdatedAtError` thrown by `SyncUploadService` when the server omits `updatedAt`, preserving local `serverUpdatedAt` instead of silently bumping it to `DateTime.now()`.
- Redesigned **Settings** hub with search, a two-pane layout, and default-collapsed sections; inline Account profile card in the two-pane layout.
- Developer contact bottom sheet from the About section.

### Changed

- `lib/main.dart` wraps the entire bootstrap in `runZonedGuarded` and installs `FlutterError.onError` + `PlatformDispatcher.instance.onError` so framework errors are routed through the diagnostic log pipeline instead of crashing silently.
- `PlayerController.openMedia` catches exceptions from `engine.open` and downstream awaits so a failed open no longer leaves `state` pointing at a phantom session.
- `PlayerController.clear()` flushes the pending `PlaybackSessionPersister` write before cancelling, so swipe-to-dismiss no longer loses the last 450 ms of position updates.
- `YoutubePlayerEngine._emitBuffering(false)` only bumps `mountTick` on the first buffering→false transition per open, reducing ad-reload flicker.
- `_userSessionDatabases` in `app_database_provider.dart` is a bounded `LinkedHashMap` (cap = 2) — oldest entry is closed before inserting a new one.
- `SecureTokenStore` now pins `AndroidOptions()` (v10 RSA-OAEP / AES-GCM with auto-migration from legacy ciphers) and `IOSOptions(accessibility: KeychainAccessibility.first_unlock)`.
- `EmailEntryScreen` BackButton always calls `cancelSignIn()` (it was previously gated on `AuthAwaitingOtp`).
- `_EnjoyAppState.build` uses `ref.listen` to mirror `appPreferencesCtrlProvider` into `_lastResolvedPrefs` via `setState` instead of writing the field as a build-time side effect.

### Fixed

- `VideoPosterCaptureService` seek-zero restore failures now log at warning level (was a nested empty `catch` that swallowed real errors).
- Drift `transcript_fetch_states` missing index — see follow-up.
- Auth deep-link stream subscription now stored + cancelled in `dispose()`; `getInitialLink()` has an `onError` handler.
- `YoutubePlayerEngine.idleAfterClear()` removed a dead branch where `_videoId.isNotEmpty` was checked after `_videoId = ''`.
- Two `kIsWeb` branches removed from `log_file_sink.dart` and `practice_poster_export.dart` per AGENTS.md hard rule.
- Library empty state now shows insight cards alongside the empty-state illustration on the home screen.

### Security

- ADR-0028 accepted: agentic workflows route inference through the MiniMax proxy with CI egress allow-list checks; zero-retention posture pending annual re-verification (medium risk).

## [0.2.3] - 2026-06-24

### Fixed

- YouTube player WebView: unblock Windows release playback (CDN subresource navigation policy).
- YouTube player WebView: harden cross-platform playback recovery after renderer crashes and stalls.

## [0.2.2] - 2026-06-23

### Added

- Local production diagnostics logging and zip export.

### Changed

- YouTube player: poster overlay and warm WebView on init.

### Fixed

- Echo-mode transcript autoscroll crashes without losing scroll accuracy.
- YouTube player WebView: block Google sign-in navigations that interrupt playback.
- Windows debug: silence `accessibility_bridge` AXTree console spam.

## [0.2.1] - 2026-06-16

### Added

- Public download landing page at [get.enjoy.bot](https://get.enjoy.bot) with platform detection, i18n, and feature showcase.
- Cloudflare Pages deploy workflow for the landing site.
- Discover UI tests (horizontal drag scroll, subscription actions).

### Changed

- Discover subscribe sheet: keyboard handling, state management, and layout improvements.
- Discover: horizontal drag scroll behavior; clearer subscription error handling.
- Android: flavor handling docs and build config; JNI merge cache workaround.

### Fixed

- Release publish pipeline: pubspec-versioned artifacts, per-platform `latest.json` overwrites, and macOS release fixes.

## [0.2.0] - 2026-06-10

### Added

- **Discover** tab: browse recommended YouTube channels, subscribe locally, and import videos from a merged upload feed.
- **Unified Library** navigation: Local and Cloud media in one shell tab (`/library?source=cloud`).
- **OTA updates**: in-app update prompts with platform feeds on `dl.enjoy.bot` (Android, iOS, macOS Sparkle, Windows WinSparkle).
- Transcript **recording counts** per line; hotkey **settings** screen and global focus policy.
- **Mobile transport** line navigation for narrow player layouts.
- Signed-in **Home**: today's practice goal and community activity cards.

### Changed

- Library search with `/` hotkey; improved media card thumbnails and YouTube artwork handling.
- Release tooling: shared local/CI scripts, R2 publish pipeline, and local-first packaging docs.

## [0.1.0] - 2026-05-22

First public beta.

### Added

- Initial MVP scaffold: feature-first layout, Drift schema, media_kit player, Riverpod providers, go_router shell with mini player, transcript import (SRT/VTT), echo mode parity with web `echo-utils`.
- Documentation system: AGENTS.md, ADRs, feature specs, Cursor rules.
