# Implementation Plan: YouTube Worker Discovery

**Branch**: `018-youtube-worker-discovery` | **Date**: 2026-07-14 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/018-youtube-worker-discovery/spec.md`

## Summary

Replace the client-side dual-source YouTube channel discovery pipeline (InnerTube `browse` primary + Atom RSS fallback) with a single server-side RSSHub proxy. The worker serves three RSSHub YouTube routes (`/youtube/channel/:id`, `/youtube/user/:handle`, `/youtube/playlist/:id`) returning JSON Feed v1.1. The client constructs feed URLs from user input, fetches JSON, parses entries, and caches them locally using the existing append-only Drift contract. Subscriptions remain local-first (Drift `youtube_channel_subscriptions`), synced across devices via existing cloud sync (ADR-0010/ADR-0013). Playlist subscriptions become a first-class source type alongside channels/users.

This is a redesign from zero — the legacy client-side code (`YoutubeRssParser`, `YoutubeBrowseClient`, `YoutubeChannelResolver`, `YoutubeVideoDuration`, `YoutubeFetch`) is replaced, not extended.

## Technical Context

**Language/Version**: Dart ^3.12, Flutter stable 3.x

**Primary Dependencies**: Riverpod 3, Drift, `package:http` (for worker HTTP), `package:logging` (logNamed)

**Storage**: Drift `AppDatabase` — tables `youtube_channel_subscriptions` (alter), `youtube_feed_entries` (alter), new migration

**Testing**: `flutter test` for unit/widget tests; `discover_repository_test.dart` pattern for integration; stub HTTP for worker responses

**Target Platform**: Android, iOS, macOS, Windows, Linux — no web

**Project Type**: Flutter native mobile/desktop app

**Performance Goals**: 60 fps timeline scroll with 20 subscriptions × 500 entries; worker feed fetch <2s; subscribe-to-video <5s

**Constraints**: No direct YouTube HTTP calls from client; local-first subscriptions; append-only cache; no `print()`; feature-first architecture under `lib/features/discover/`

**Scale/Scope**: Supports 3 source types (channel, user/handle, playlist); up to 20 active subscriptions; unlimited cached entries per source (no upper bound per ADR-0046)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Architecture and Code Quality

- [x] Code stays in `lib/features/discover/{application,data,domain,presentation}` — PASS
- [x] Domain models remain UI-free; persistence through Drift DAOs — PASS
- [x] Riverpod for app state; no new mutable global singletons — PASS
- [x] No `print()` calls; no direct `media_kit` `Player()` — PASS (discover doesn't own a player)

### II. Testing Defines the Contract

- [x] Unit tests: URL parsing/validation, worker URL construction, JSON Feed v1.1 parsing, handle-to-ID canonicalization, deduplication logic
- [x] Integration tests: worker feed fetch + parse + cache write, append-only upsert, cooldown enforcement, error state handling
- [x] Widget tests: subscribe sheet URL validation, subscription management UI, error/empty/loading states
- [x] Schema change requires `dart run build_runner build` — PASS (migration, Drift annotations)

### III. User Experience Consistency

- [x] User-facing strings in ARB localization — PASS (new keys for URL validation errors, source-unavailable, etc.)
- [x] Tappable controls use `EnjoyTappableSurface`/`EnjoyButton` — PASS (existing patterns in `discover_actions.dart`)
- [x] `docs/features/discover.md` will be updated — PASS

### IV. Performance Is a Requirement

- [x] Timeline scroll: 60 fps with 20 subs × 500 entries — PASS (existing `ValueKey` + `findChildIndexCallback` preserved)
- [x] Worker feed fetch <2s — PASS (simple GET, no multi-phase pipeline)
- [x] Image/DB work: thumbnail caching reused, Drift upserts batched — PASS

### V. Documentation and Traceability

- [x] New ADR: `0051-youtube-worker-discovery.md` — PASS
- [x] Updated feature doc: `docs/features/discover.md` — PASS
- [x] Updated agent guidance if needed — CONFIRM at Phase 1 re-check

**Gate result: PASS — proceed to Phase 0 research.**

## Project Structure

### Documentation (this feature)

```text
specs/018-youtube-worker-discovery/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── features/discover/
│   ├── application/
│   │   ├── discover_providers.dart          # MODIFY: new providers for worker feed
│   │   └── discover_providers.g.dart         # REGENERATE
│   ├── data/
│   │   ├── discover_repository.dart          # REWRITE: replace dual-source with worker feed
│   │   ├── worker_feed_client.dart           # NEW: HTTP GET to RSSHub proxy
│   │   ├── json_feed_parser.dart             # NEW: JSON Feed v1.1 parser
│   │   ├── youtube_url_parser.dart           # NEW: URL → source type + canonical ID
│   │   ├── recommended_channels_loader.dart  # KEEP (bundled catalog unchanged)
│   │   ├── youtube_browse_client.dart        # REMOVE (legacy InnerTube)
│   │   ├── youtube_channel_resolver.dart     # REMOVE (legacy HTML resolver)
│   │   ├── youtube_rss_parser.dart           # REMOVE (legacy RSS)
│   │   ├── youtube_video_duration.dart       # REMOVE (legacy enrichment)
│   │   ├── youtube_fetch.dart                # REMOVE (legacy YouTube HTTP helpers)
│   │   └── catalog_channel_ids.dart          # REMOVE (legacy channel repairs)
│   ├── domain/
│   │   ├── discover_channel.dart             # MODIFY: add source_type, feed_url
│   │   ├── feed_entry.dart                   # MODIFY: remove view_count (not in JSON Feed)
│   │   └── recommended_channel.dart          # KEEP
│   └── presentation/
│       ├── discover_screen.dart              # MODIFY: worker error states
│       ├── discover_subscribe_sheet.dart     # MODIFY: playlist URL support
│       ├── discover_manage_channels.dart     # MODIFY: playlist type indicator
│       ├── discover_actions.dart             # MODIFY: new subscribe flow
│       ├── discover_subscription_row.dart    # MODIFY: source type icon
│       ├── discover_channel_filter_strip.dart # MODIFY: playlist indicators
│       ├── discover_feed_tile.dart           # MINOR: adapt to new model fields
│       ├── channel_feed_screen.dart          # MINOR: adapt
│       ├── discover_channel_avatar.dart      # KEEP
│       ├── discover_recommended_avatar_strip.dart # KEEP
│       ├── discover_recommended_channel_card.dart # KEEP
│       └── discover_subscription_row.dart    # MODIFY
├── data/
│   └── db/
│       ├── tables/
│       │   ├── youtube_channel_subscriptions.dart  # MODIFY: add source_type, feed_url
│       │   └── youtube_feed_entries.dart           # MODIFY: maybe remove durationSeconds?
│       ├── daos/
│       │   ├── youtube_channel_subscription_dao.dart  # MODIFY: new columns
│       │   └── youtube_feed_entry_dao.dart            # MINOR
│       └── app_database.dart                          # MODIFY: migration
├── core/
│   └── logging/log.dart                               # KEEP
└── api/
    └── api_client.dart                                # KEEP (worker base URL config)

test/
├── features/discover/
│   ├── discover_repository_test.dart          # REWRITE
│   ├── worker_feed_client_test.dart           # NEW
│   ├── json_feed_parser_test.dart             # NEW
│   ├── youtube_url_parser_test.dart           # NEW
│   ├── discover_dedupe_test.dart              # MODIFY
│   ├── discover_subscribe_sheet_test.dart     # MODIFY
│   ├── discover_subscription_ui_test.dart     # MODIFY
│   ├── discover_feed_tile_test.dart           # MODIFY
│   ├── discover_feed_filter_test.dart         # KEEP/MODIFY
│   ├── discover_horizontal_strips_test.dart   # KEEP/MODIFY
│   ├── discover_subscribe_actions_test.dart   # MODIFY
│   ├── recommended_channels_test.dart         # KEEP
│   └── discover_manage_channels_test.dart     # MODIFY
│   ├── youtube_browse_client_test.dart        # REMOVE
│   ├── youtube_channel_resolver_test.dart     # REMOVE
│   ├── youtube_rss_parser_test.dart           # REMOVE
│   └── youtube_video_duration_test.dart       # REMOVE

docs/
├── features/discover.md                       # REWRITE
└── decisions/0051-youtube-worker-discovery.md # NEW
```

**Structure Decision**: All new code stays under `lib/features/discover/data/` following the existing feature-first convention. Worker API contracts go in `specs/018-youtube-worker-discovery/contracts/`. The legacy code removal is part of this feature (not a follow-up), since the redesign replaces it completely.

## Complexity Tracking

> No constitution violations. This feature simplifies the architecture (single-source worker feed vs dual-source client-side pipeline) and removes more code than it adds.
