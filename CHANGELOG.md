# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Wiki documentation template at `.github/agentic-wiki/PAGES.md` consumed by the
  `agentic-wiki-writer` workflow. Includes page outlines for Home, Getting
  Started, Architecture, Player, Transcripts, Library, Sync, Auth, Settings,
  Release & CI, Local Packages, and an index page for AI coding agents.
- Google Sign-In configuration files (`google-services.json` /
  `GoogleService-Info.plist`) flipped from `REPLACE_WITH_*` placeholders to
  shipped defaults; the Web application client ID is referenced from
  `kGoogleWebClientId` in `lib/features/auth/domain/google_auth_config.dart`.
- `macos/Runner/ReleaseDirect.entitlements` — separate entitlements file for
  Developer ID direct-download builds (sandbox + network + app keychain
  group, **without** `com.apple.developer.applesignin`, which is unsupported
  on Developer ID distribution).
- Dicebear SVG avatar URLs are rewritten to PNG before being handed to
  Flutter image decoders, fixing black/missing avatars in the community
  activity card, account hero, and profile sidebar.

### Changed

- Database is now strictly sign-in gated — guest rekey imports and the
  signed-out library fallback were removed in `35a2a57`. `guestAppDatabaseProvider`
  was renamed to `deviceGlobalAppDatabaseProvider` so `enjoy_player.sqlite` is
  clearly device-global settings (not a guest library). See
  [ADR-0012](docs/decisions/0012-per-user-sqlite-isolation.md) and
  [ADR-0031](docs/decisions/0031-login-only-access.md).
- macOS local/Xcode builds no longer reference `com.apple.developer.applesignin`
  (the capability is unsupported on Developer ID distribution and breaks
  provisioning on macOS). iOS still ships with the entitlement on all
  Runner configurations; macOS Direct builds use `ReleaseDirect.entitlements`
  via `notarize_release.sh`.
- `release.ps1` `--notarize` is now auto-enabled when `--publish` builds a
  macOS zip, so direct-download publish flows no longer need to pass it
  explicitly.
- `--norsrc` was added to the macOS zip `ditto` invocation in the Apple
  release CI to omit AppleDouble entries that broke framework seals when
  unzipping downstream.

### Fixed

- **Landing page store buttons**: iOS TestFlight and Android Play beta cards now stay visible when their URLs are unset in `landing/config.js`, rendering a disabled "Coming soon" button (`btn--disabled`, `aria-disabled="true"`) instead of dropping the cards or shipping a broken link. See [docs/packaging.md](docs/packaging.md#updating-store-links) and [ADR-0024](docs/decisions/0024-download-landing-page.md).
- **macOS keychain cold-start (`-34018`)**: `keychain-access-groups` was
  empty, which broke `flutter_secure_storage` in local debug builds and
  trapped the app in an auth retry loop. The app's own keychain group
  (`$(AppIdentifierPrefix)$(CFBundleIdentifier)`) is now set on Debug,
  Profile, Release, and ReleaseDirect entitlements. See
  [docs/features/auth.md](docs/features/auth.md).
- **macOS Developer ID direct-download launch (`error 163`)**: Sign in with
  Apple entitlements are unsupported on Developer ID builds; switching to
  `ReleaseDirect.entitlements` and repacking from a stapled app before
  publish unblocks notarized direct downloads on macOS 26.
- **Apple Sign-In entitlements** on iOS and macOS: `ios/Runner/Runner.entitlements`
  now ships `com.apple.developer.applesignin` referenced from all Runner
  build configurations (`CODE_SIGN_ENTITLEMENTS`) so physical devices no
  longer surface `AuthorizationError error 1000` before the API call.
- **Auth cold-start resilience**: keychain and transient network failures
  during startup are now treated as signed-out (`AuthSignedOut`) instead
  of fatal errors. `AuthCtrl.handleAuthCallbackUri` also catches any
  non-`AuthFailure` error from the token exchange and resets state, so
  the sign-in hub is no longer trapped on the "waiting for browser" pane.
- **Apple release test gate**: macOS Info.plist and Runner entitlements are
  now consistent across local Xcode and notarized release flows, so the
  release Apple workflow no longer gets blocked on missing plist keys.
- **Apple CI on self-hosted mac runners**: `.github/actions/setup-flutter`
  now installs CocoaPods and the iOS toolchain on the self-hosted mac
  runner so `build_apple.yml` and `release_apple.yml` can run end-to-end
  without manual `pod install`.
- **Skipped-frame skeleton crash**: skeleton list placeholders no longer
  crash inside nested scroll views when the parent scroll view computes
  a negative scroll offset during initial layout.
- **Drift `ADD COLUMN` migrations are now idempotent**: `_addColumnIfMissing`
  short-circuits when the column already exists, so downgrading and
  re-upgrading the schema no longer hangs the database open.
- **Blank-window hang after a failed migration**: combined with the
  idempotent ADD COLUMN fix above, the database opens even when the on-disk
  schema includes columns added by a newer build.
- **Local DB recovery paths**: `RecoverySurface` and `performRecoveryReset`
  now point at the correct per-user / device-global database files and
  the in-place reset flow is wired into the recovery UI for the user that
  needs it (with a downgrade-safe migration test). See
  [docs/features/local-database-recovery.md](docs/features/local-database-recovery.md).
- **`TranscriptRepository.watchTracks` re-emissions**: identical watch
  emissions are now deduped with `Stream.distinctBy(_listEqualsTranscriptTrack)`
  so the always-mounted transport bar stops rebuilding on no-op Drift
  ticks (#208). Mirrors the same fix already applied to `watchLines`.
- **Apple Info.plist placeholder URL scheme** is now a valid reversed host
  format (`com.googleusercontent.apps.REPLACE_WITH_CLIENT_ID`) so iOS
  bundle validation stops rejecting the binary before Google Sign-In
  configuration can be completed.

### Security

- Sign in with Apple entitlement is no longer included in the macOS
  ReleaseDirect entitlements (unsupported on Developer ID distribution);
  this narrows the entitlement set for direct-download macOS builds.

## [0.3.1] - 2026-07-03

### Added

- `findSliverIndexByPrefixedId<T>` in `lib/core/utils/sliver_key_index.dart` — shared `findChildIndexCallback` lookup for sliver grids/lists keyed by a `"$prefix${id}"` `ValueKey<String>`.
- `ArtworkPalette` now has value-equality on its four `Color` fields so `Map<ArtworkPalette, ...>` use sites and `==` checks behave like data classes. `@visibleForTesting` cache seams on `lib/core/theme/dynamic_color/artwork_palette.dart`: `debugResetArtworkPaletteCache`, `debugArtworkPaletteCacheSize`, `debugArtworkPaletteCacheContainsPath`, `debugLookupArtworkPalette`, `debugPutArtworkPalette`. 12 tests in `test/core/theme/artwork_palette_test.dart` cover the new invalidation contract.

### Changed

- Home recents grid, discover merged feed grid, and channel feed grid use stable per-row `ValueKey`s + `findChildIndexCallback` so a Drift re-emit or RSS refresh no longer rebuilds every visible tile.
- **Artwork palette LRU cache key**: switched from thumbnail path alone to `(path, size, mtime)`. The in-process LRU in `extractArtworkPalette` re-`stat`s the file on every lookup and evicts any prior entry for the same path whose `(size, mtime)` no longer matches the live stat. LRU cap stays at 32 entries. ADR-0007 updated to describe the new key shape and invalidation contract.

### Fixed

- Documented the `POST /youtube/transcripts` polling contract (request body, attempt/delay budget, `forceRefresh` semantics, and outcome handling) — no behavior change, closes a docs gap between `YoutubeTranscriptsApi` and `docs/features/transcript.md`.
- **Artwork palette stale-cache leak**: re-thumbnailing or rewriting the local artwork file in place used to return the cached palette for the previous bytes because the LRU key was the path string only. Keyed by `(path, size, mtime)` so a regenerate-then-reopen cycle extracts a fresh palette.
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
