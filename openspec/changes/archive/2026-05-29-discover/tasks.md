## 1. Documentation and ADR

- [x] 1.1 Add ADR for RSS-based YouTube discovery and local-only channel subscriptions (`docs/decisions/`)
- [x] 1.2 Add `docs/features/discover.md` describing UX, refresh policy, and limitations
- [x] 1.3 Link discover doc from `docs/README.md`

## 2. Data layer (Drift)

- [x] 2.1 Add `youtube_channel_subscriptions` and `youtube_feed_entries` Drift tables under `lib/data/db/tables/`
- [x] 2.2 Add DAOs with watch/list/upsert/delete for subscriptions and feed entries
- [x] 2.3 Bump `AppDatabase` schema version and register tables in destructive `onUpgrade`
- [x] 2.4 Run `dart run build_runner build` for Drift codegen

## 3. Discover domain and data services

- [x] 3.1 Add domain models: `DiscoverChannel`, `FeedEntry`, recommended catalog types under `lib/features/discover/domain/`
- [x] 3.2 Add bundled `assets/discover/recommended_channels.json` and register in `pubspec.yaml`
- [x] 3.3 Implement `RecommendedChannelsLoader` to parse asset JSON
- [x] 3.4 Implement `YoutubeRssParser` (Atom → feed entries)
- [x] 3.5 Implement `YoutubeChannelResolver` (URL/handle → `channel_id`, best-effort HTML parse)
- [x] 3.6 Implement `DiscoverRepository` (subscribe, unsubscribe, list subscriptions, refresh feeds, watch timeline)

## 4. Application layer (Riverpod)

- [x] 4.1 Add providers: recommended channels, subscriptions, merged timeline stream, refresh state
- [x] 4.2 Implement `DiscoverFeedRefreshScheduler` (launch refresh, 8h interval, min 1h per-channel skip)
- [x] 4.3 Wire scheduler start from app bootstrap (after DB ready)
- [x] 4.4 Add `addFeedEntryToLibrary` action delegating to `MediaLibraryRepository.importYoutubeVideo()` with duplicate check via `getYoutubeByVid`

## 5. Presentation

- [x] 5.1 Add `DiscoverScreen` with Recommended row, Subscriptions section, merged Timeline list
- [x] 5.2 Add `ChannelFeedScreen` (single-channel cached entries)
- [x] 5.3 Add subscribe sheet (paste channel URL/handle) and unsubscribe affordance
- [x] 5.4 Add feed tile widget with Add to library / In library / Play states
- [x] 5.5 Add pull-to-refresh, loading skeleton, empty, and error states
- [x] 5.6 Update Home empty state with secondary Browse Discover action

## 6. Routing and shell

- [x] 6.1 Add `/discover` and channel detail routes in `app_router.dart`
- [x] 6.2 Add Discover nav item in `root_shell.dart` with l10n label and icon
- [x] 6.3 Run `dart run build_runner build` if router `@Riverpod` annotations change

## 7. Localization

- [x] 7.1 Add ARB strings for Discover tab, subscribe/unsubscribe, feed states, add-to-library, errors
- [x] 7.2 Run `flutter gen-l10n`

## 8. Tests and verification

- [x] 8.1 Unit tests: RSS parser (sample Atom fixture)
- [x] 8.2 Unit tests: channel resolver (mock HTTP with sample HTML)
- [x] 8.3 Unit tests: repository refresh upserts and timeline ordering
- [x] 8.4 Widget test: feed tile shows In library when video already imported
- [x] 8.5 Run `flutter analyze` and `flutter test`
