# Tasks: YouTube Worker Discovery

**Input**: Design documents from `specs/018-youtube-worker-discovery/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Automated tests are required for changed behavior (constitution requires tests for all contract changes). Existing tests for removed code are removed.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **Feature code**: `lib/features/discover/{application,data,domain,presentation}/`
- **Shared code**: `lib/core/`, `lib/data/`
- **Tests**: `test/features/discover/`, `test/data/`
- **Feature docs**: `docs/features/discover.md`
- **ADRs**: `docs/decisions/0049-youtube-worker-discovery.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Schema changes, new domain types, and remove legacy code — all blocking prerequisites

- [x] T001 [P] Add `YoutubeSourceType` enum (`channel`, `playlist`) in `lib/data/db/youtube_subscription_source.dart`
- [x] T002 [P] Add `sourceType` and `feedUrl` columns to `YoutubeChannelSubscriptions` Drift table in `lib/data/db/tables/youtube_channel_subscriptions.dart`
- [x] T003 Create incremental Drift schema migration in `lib/data/db/app_database.dart` — ALTER TABLE add `source_type`, `feed_url`; backfill existing rows
- [x] T004 [P] Update `YoutubeChannelSubscriptionDao` with new column accessors in `lib/data/db/daos/youtube_channel_subscription_dao.dart`
- [x] T005 Run `dart run build_runner build` to regenerate Drift code (*.g.dart files)
- [x] T006 [P] Create `ParsedYoutubeUrl` domain model in `lib/features/discover/domain/youtube_source.dart` (sourceType, canonicalId, feedUrl)
- [x] T007 [P] Update `DiscoverChannel` domain model — add `sourceType` and `feedUrl` fields in `lib/features/discover/domain/discover_channel.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core worker feed infrastructure that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T008 [P] Create `YoutubeUrlParser` — pure URL validation and canonical ID extraction in `lib/features/discover/data/youtube_url_parser.dart`
- [x] T009 [P] Create `JsonFeedParser` — JSON Feed v1.1 parsing in `lib/features/discover/data/json_feed_parser.dart`
- [x] T010 Create `WorkerFeedClient` — HTTP GET to RSSHub proxy in `lib/features/discover/data/worker_feed_client.dart`
- [x] T011 [P] Create `WorkerFeedException` — typed exceptions in `lib/features/discover/data/worker_feed_exception.dart`
- [x] T012 [P] Unit test `YoutubeUrlParser` in `test/features/discover/youtube_url_parser_test.dart`
- [x] T013 [P] Unit test `JsonFeedParser` in `test/features/discover/json_feed_parser_test.dart`
- [x] T014 [P] Unit test `WorkerFeedClient` in `test/features/discover/worker_feed_client_test.dart`

**Checkpoint**: Foundation ready — URL parsing, feed fetching, and JSON parsing are all proven. User story implementation can now begin.

---

## Phase 3: User Story 1 - Subscribe to a YouTube source and browse recent uploads (Priority: P1) 🎯 MVP

**Goal**: User can paste a YouTube channel, @handle, or playlist URL and see video entries in the Discover timeline within 5 seconds, all fetched through the RSSHub worker proxy.

**Independent Test**: Using a stub worker serving JSON Feed at `GET /youtube/channel/UC_test?format=json`, enter a YouTube channel URL → subscription created → video entries in timeline → pull-to-refresh works.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T015 [P] [US1] Unit test `WorkerFeedClient` handle-to-ID canonicalization: fetch `/youtube/user/@test` → extract channel ID from `home_page_url` → subsequent refresh uses `/youtube/channel/UC...` in `test/features/discover/worker_feed_client_test.dart`
- [ ] T016 [US1] Widget test subscribe sheet — enter valid channel/playlist/handle URLs, assert feed is fetched and timeline populates; enter invalid URLs, assert validation error in `test/features/discover/discover_subscribe_sheet_test.dart`

### Implementation for User Story 1

- [ ] T017 [US1] Implement `subscribeFromUrl()` in `DiscoverRepository` — validate URL via `YoutubeUrlParser` → construct worker feed URL → fetch via `WorkerFeedClient` → parse via `JsonFeedParser` → create subscription (from feed title/icon/home_page_url) → upsert video entries → touch lastFetchedAt in `lib/features/discover/data/discover_repository.dart`
- [ ] T018 [US1] Wire `subscribeFromUrl()` into `discoverProviders` — new Riverpod provider for subscribe action, exposes loading/error/success states in `lib/features/discover/application/discover_providers.dart`
- [ ] T019 [US1] Update `_DiscoverSubscribeSheet` — add playlist URL detection, show source type indicator, local validation before worker call, loading spinner, error display in `lib/features/discover/presentation/discover_subscribe_sheet.dart`
- [ ] T020 [US1] Update `discover_actions.dart` — call new subscribe provider, handle errors, show success notice in `lib/features/discover/presentation/discover_actions.dart`
- [ ] T021 [US1] Add ARB localization strings for new subscribe flow: URL validation errors (invalid URL, already subscribed), subscribe success, source not found, source unavailable in `lib/l10n/app_en.arb`
- [ ] T022 [US1] Integration test: full subscribe flow — valid URL → subscription in DB → feed entries in DB → timeline renders entries in `test/features/discover/discover_repository_test.dart`
- [ ] T023 [US1] Regenerate `discover_providers.g.dart` via `dart run build_runner build`

**Checkpoint**: User Story 1 complete — subscribe to channels, handles, and playlists; videos render in timeline; errors handled gracefully.

---

## Phase 4: User Story 2 - Automatic background refresh (Priority: P2)

**Goal**: Feed stays current without manual intervention. 1-hour cooldown-gated automatic refresh fetches new videos for all subscribed sources. Pull-to-refresh bypasses cooldown.

**Independent Test**: Seed stub with initial videos → add subscription → update stub with 1 new video → wait/fast-forward refresh timer → new video appears in timeline, no duplicates.

### Tests for User Story 2

- [ ] T024 [P] [US2] Unit test cooldown enforcement: refresh within 1h cooldown → channel skipped; refresh after cooldown → channel fetched in `test/features/discover/discover_repository_test.dart`
- [ ] T025 [P] [US2] Unit test append-only cache: refresh returns mix of old + new videos → old entries updated, new entries inserted, no entries deleted in `test/features/discover/discover_repository_test.dart`

### Implementation for User Story 2

- [ ] T026 [US2] Implement `refreshFeeds()` in `DiscoverRepository` — iterates subscriptions, skips those within cooldown, fetches each source's feed URL via `WorkerFeedClient`, parses JSON Feed, upserts entries (append-only), touches lastFetchedAt. Preserves 4-way concurrency cap (`_kRefreshChannelConcurrency = 4`) in `lib/features/discover/data/discover_repository.dart`
- [ ] T027 [US2] Implement `refreshChannel()` (single-source refresh) — fetch feed URL, parse, upsert, handle 404/410/429 errors, return success/failure per source in `lib/features/discover/data/discover_repository.dart`
- [ ] T028 [US2] Wire refresh into `discoverProviders` — Riverpod notifier for refresh trigger (pull-to-refresh + launch + periodic timer), exposes `DiscoverRefreshResult` with `refreshedChannelIds` and `failedChannelIds` in `lib/features/discover/application/discover_providers.dart`
- [ ] T029 [US2] Update `DiscoverScreen` — wire `RefreshIndicator` to new refresh provider, show per-source failure notices via `AppNotice.error`, show `last updated` timestamp in `lib/features/discover/presentation/discover_screen.dart`
- [ ] T030 [US2] Remove legacy refresh code — `_refreshChannelViaRss()`, `_persistBrowseOutcome()`, `_enrichMissingDurations()`, InnerTube → RSS fallback logic from `lib/features/discover/data/discover_repository.dart`
- [ ] T031 [US2] Remove `YoutubeBrowseClient` and its test — `lib/features/discover/data/youtube_browse_client.dart`, `test/features/discover/youtube_browse_client_test.dart`
- [ ] T032 [US2] Remove `YoutubeRssParser` and its test — `lib/features/discover/data/youtube_rss_parser.dart`, `test/features/discover/youtube_rss_parser_test.dart`
- [ ] T033 [US2] Remove `YoutubeVideoDuration` and its test — `lib/features/discover/data/youtube_video_duration.dart`, `test/features/discover/youtube_video_duration_test.dart`
- [ ] T034 [US2] Remove `YoutubeFetch` — `lib/features/discover/data/youtube_fetch.dart`
- [ ] T035 [US2] Remove `catalog_channel_ids.dart` — `lib/features/discover/data/catalog_channel_ids.dart`
- [ ] T036 [US2] Remove legacy refresh imports and dead code references from `discover_repository.dart`
- [ ] T037 [US2] Integration test: refresh with 3 subscriptions, 1 fails → partial failure returned, other 2 update, cooldown honored in `test/features/discover/discover_repository_test.dart`
- [ ] T038 [US2] Regenerate `discover_providers.g.dart` via `dart run build_runner build`

**Checkpoint**: User Stories 1 AND 2 complete — subscribe works, automatic refresh works, all legacy discovery code removed.

---

## Phase 5: User Story 3 - Manage subscriptions (list, unsubscribe, re-subscribe) (Priority: P3)

**Goal**: User can view all subscriptions in a management list, see last-refreshed timestamps, unsubscribe (removes videos from timeline), and re-subscribe later. All local — no worker calls for management.

**Independent Test**: Create 2 subscriptions → open management screen → unsubscribe 1 → videos removed → re-subscribe → videos re-populated.

### Tests for User Story 3

- [ ] T039 [P] [US3] Widget test subscription management screen — list all subscriptions, show source type indicator (channel/playlist icon), show last-refreshed timestamp in `test/features/discover/discover_subscription_ui_test.dart`

### Implementation for User Story 3

- [ ] T040 [US3] Update `DiscoverManageChannelsView` — display `sourceType` (channel vs playlist icon), show `feedUrl` in detail, show last-refreshed timestamp per subscription in `lib/features/discover/presentation/discover_manage_channels.dart`
- [ ] T041 [US3] Update `DiscoverSubscriptionRow` — add source type icon (channel/playlist), show last-refreshed time, wire unsubscribe action (local-only, no worker call) in `lib/features/discover/presentation/discover_subscription_row.dart`
- [ ] T042 [US3] Update `discover_actions.dart` — unsubscribe: delete subscription row + all cached feed entries for that channelId. Re-subscribe: re-fetch feed URL, re-create subscription, re-populate entries in `lib/features/discover/presentation/discover_actions.dart`
- [ ] T043 [US3] Update `DiscoverChannelFilterStrip` — playlist sources show playlist icon in channel filter chips in `lib/features/discover/presentation/discover_channel_filter_strip.dart`
- [ ] T044 [US3] Update `unsubscribeDiscoverChannel()` — ensure cascade delete of `youtube_feed_entries` rows for the unsubscribed source in `lib/features/discover/presentation/discover_actions.dart`
- [ ] T045 [US3] Add ARB localization strings: "Already subscribed", "Unsubscribed", source type labels ("Channel", "Playlist"), source-unavailable notice in `lib/l10n/app_en.arb`
- [ ] T046 [US3] Integration test: unsubscribe deletes entries, re-subscribe re-populates in `test/features/discover/discover_repository_test.dart`

**Checkpoint**: All three core stories complete — subscribe, refresh, and manage subscriptions all work with local-first data.

---

## Phase 6: User Story 4 - Multi-device subscription sync (Priority: P4)

**Goal**: Subscriptions sync between devices via existing cloud sync infrastructure (ADR-0010/ADR-0013). No new sync mechanism.

**Independent Test**: Sign in on 2 devices → subscribe on device A → sync on device B → subscription appears → feed loads independently on B.

### Implementation for User Story 4

- [ ] T047 [US4] Add `youtube_subscription` to `SyncEntityType` enum in `lib/features/sync/domain/sync_types.dart`
- [ ] T048 [US4] Implement sync serialization for `YoutubeChannelSubscriptionRow` — serialize subscription fields (channelId, displayName, thumbnailUrl, source, sourceType, feedUrl, language, subscribedAt) to JSON payload in `lib/features/sync/data/sync_serializers.dart`
- [ ] T049 [US4] Add subscription sync trigger — enqueue sync action on subscribe/unsubscribe in `lib/features/discover/data/discover_repository.dart`
- [ ] T050 [US4] Implement subscription sync pull — on sync download, upsert subscription row + trigger initial feed refresh in `lib/features/sync/data/sync_download_service.dart`
- [ ] T051 [US4] Unit test subscription sync — serialize/deserialize subscription payload, enqueue/dequeue sync actions in `test/features/sync/sync_serializers_test.dart` or `test/features/discover/discover_repository_test.dart`

**Checkpoint**: All user stories complete — subscriptions sync across devices via existing cloud infrastructure.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, verification, and cleanup

- [ ] T052 [P] Write ADR `0049-youtube-worker-discovery.md` in `docs/decisions/0049-youtube-worker-discovery.md` — document RSSHub proxy decision, JSON Feed contract, local-first subscriptions, removed legacy code
- [ ] T053 [P] Rewrite `docs/features/discover.md` — describe worker RSSHub proxy architecture, three source types, local-first subscriptions, data flow in `docs/features/discover.md`
- [ ] T054 [P] Remove `YoutubeChannelResolver` and its test — `lib/features/discover/data/youtube_channel_resolver.dart`, `test/features/discover/youtube_channel_resolver_test.dart`
- [ ] T055 [P] Update `lib/features/discover/data/recommended_channels_loader.dart` — ensure recommended channels use `sourceType: channel` and construct `feedUrl`
- [ ] T056 Remove `client_profile.dart` discover usage — remove InnerTube profile rotation from Discover (keep for transcript fetcher) — check `lib/features/discover/data/discover_repository.dart` for profile references
- [ ] T057 Update `FeedEntry` domain model — remove `viewCount` reference (not available from JSON Feed) in `lib/features/discover/domain/feed_entry.dart`
- [ ] T058 Update `DiscoverFeedTile` — remove view count display, adapt to any new field names in `lib/features/discover/presentation/discover_feed_tile.dart`
- [ ] T059 Run `dart run build_runner build` to regenerate all Drift + Riverpod code
- [ ] T060 Run `flutter analyze` — fix all warnings and errors
- [ ] T061 Run `flutter test` — all tests pass
- [ ] T062 Run `bash .github/scripts/check_dart_format.sh` — verify formatting
- [ ] T063 Run full `bash .github/scripts/validate_ci_gates.sh` — all CI gates pass
- [ ] T064 Run quickstart validation — execute all 7 manual verification scenarios from `quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup (T001–T007) — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational — delivers MVP
- **User Story 2 (Phase 4)**: Depends on US1 (refresh pipeline builds on subscribe + feed client)
- **User Story 3 (Phase 5)**: Depends on US1 (management UI lists subscriptions created in US1)
- **User Story 4 (Phase 6)**: Depends on US1 (sync requires subscription data model)
- **Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

- **US1 (P1)**: Blocks US2 (refresh needs subscribe pipeline) and US3 (manage needs subscriptions)
- **US2 (P2)**: Can start after US1 subscribe flow is complete; removes legacy code
- **US3 (P3)**: Can start after US1 (subscription data model exists)
- **US4 (P4)**: Can start after US1 (subscription data available for sync)

### Within Each User Story

- Tests written FIRST and verified FAILING before implementation
- Foundational classes (exceptions, models) before services
- Services before UI wiring
- Story complete (tests passing + independently functional) before moving to next

### Parallel Opportunities

- T001, T002, T004, T006, T007 in Phase 1 can run in parallel (different files)
- T008, T009, T011, T012, T013, T014 in Phase 2 can run in parallel
- T015, T016 (US1 tests) can run in parallel
- T024, T025 (US2 tests) can run in parallel
- Once Phase 2 completes, US3 and US4 could theoretically start in parallel with US2 (if staffed)

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Launch all Phase 2 tasks marked [P] together:
Task: "Create YoutubeUrlParser in lib/features/discover/data/youtube_url_parser.dart"
Task: "Create JsonFeedParser in lib/features/discover/data/json_feed_parser.dart"
Task: "Create WorkerFeedException in lib/features/discover/data/worker_feed_exception.dart"
Task: "Unit test YoutubeUrlParser in test/features/discover/youtube_url_parser_test.dart"
Task: "Unit test JsonFeedParser in test/features/discover/json_feed_parser_test.dart"
Task: "Unit test WorkerFeedClient in test/features/discover/worker_feed_client_test.dart"

# Then sequential (depends on classes above):
Task: "Create WorkerFeedClient in lib/features/discover/data/worker_feed_client.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T007) — schema migration, domain types
2. Complete Phase 2: Foundational (T008–T014) — worker feed client + parsers + tests
3. Complete Phase 3: User Story 1 (T015–T023) — subscribe flow
4. **STOP and VALIDATE**: Subscribe to channels, handles, and playlists; videos render; errors handled
5. Run `flutter test` and verify MVP independently

### Incremental Delivery

1. Setup + Foundational → foundation ready
2. Add US1 → Test independently → **MVP!**
3. Add US2 → Test independently → auto-refresh + legacy code removed
4. Add US3 → Test independently → full subscription management
5. Add US4 → Test independently → multi-device sync
6. Polish → documentation, CI gates, validation

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (T001–T014)
2. Once Foundational is done:
   - Developer A: US1 (T015–T023) — subscribe flow
   - Developer B: US2 (T024–T038) — refresh + legacy removal (can start after US1 subscribe pipeline exists)
   - Developer C: US3 (T039–T046) + US4 (T047–T051) — management + sync
3. Stories complete and integrate

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Remove legacy files (T031–T035, T054) after new code is stable and tests pass
- Run `dart run build_runner build` after any Drift or Riverpod annotation changes
- All logging uses `logNamed` — never `print()`
