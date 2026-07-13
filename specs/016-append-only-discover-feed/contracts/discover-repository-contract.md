# Contracts: Discover Feed Append-Only Persistence

This feature has **no external API contracts** — it changes the persistence behavior of an internal repository. The relevant "contracts" are the public surface of `DiscoverRepository` and `YoutubeFeedEntryDao` that other features and the UI consume.

The contracts below are pinned to the *post-refactor* behavior. Anything marked **unchanged** is preserved verbatim from the existing implementation.

## C-1: `DiscoverRepository.refreshFeeds`

```dart
Future<DiscoverRefreshResult> refreshFeeds({bool force = false});
```

**Behavior**:

- `force == false` — skips channels whose `lastFetchedAt` is within `minRefreshInterval` (1 h).
- `force == true` — refreshes every subscribed channel regardless of cooldown.
- Returns `DiscoverRefreshResult { refreshedChannels, failedChannelIds }`. **Unchanged**.
- Partial failure: a failed channel's cache is left untouched and its `lastFetchedAt` is **not** advanced (per FR-008).
- Concurrency cap: `_kRefreshChannelConcurrency = 4`. **Unchanged**.
- No HTTP requests are made when the subscription list is empty. **Unchanged**.

## C-2: `DiscoverRepository._refreshChannel` (internal)

```dart
Future<void> _refreshChannel(String channelId, {required DateTime fetchedAt});
```

**Behavior (changed)**:

- Fetches `https://www.youtube.com/feeds/videos.xml?channel_id=<id>` via `YoutubeFetch.getRss`. **Unchanged**.
- Validates the response with `YoutubeRssParser.isValidFeedDocument`. **Unchanged**.
- Parses entries with `_rssParser.parse(body, channelId: channelId)`. **Unchanged**.
- **Does NOT call any RSS-driven prune** — the previous `YoutubeFeedEntryDao.deleteStaleForChannel` helper has been removed entirely (FR-003, FR-004).
- For each parsed entry, upserts a `YoutubeFeedEntryRow` keyed by `(channelId, videoId)`:
  - `title`, `thumbnailUrl`, `publishedAt`, `fetchedAt` come from the parser / `fetchedAt` argument.
  - `durationSeconds` is preserved from the existing row, copied from the matching `videos` row if the video is already in the library, or left `null` for enrichment.
- Updates the subscription `displayName` from `parseFeedTitle` if non-empty. **Unchanged**.
- Touches the subscription `lastFetchedAt` to `fetchedAt` only after a successful parse + upsert. **Behavior tightened** — see FR-008.
- Kicks off background `unawaited(_enrichMissingDurations(channelId, entries))` and `unawaited(_maybeUpdateChannelAvatar(channelId))`. **Unchanged**.

## C-3: `DiscoverRepository.unsubscribe`

```dart
Future<void> unsubscribe(String channelId);
```

**Behavior**: deletes the subscription row and every cached feed entry for that channel (via `YoutubeFeedEntryDao.deleteForChannel`). **Unchanged** — this is the user-visible way to bound cache growth.

## C-4: `DiscoverRepository.watchTimeline` / `watchChannelFeed`

```dart
Stream<List<FeedEntry>> watchTimeline();
Stream<List<FeedEntry>> watchChannelFeed(String channelId);
```

**Behavior**:

- Sort order remains `publishedAt DESC`. **Unchanged**.
- Dedupe via `distinctBy(_listEqualsFeedEntry)` so identical re-emissions do not rebuild widgets. **Unchanged**.
- Result set grows monotonically over the lifetime of the subscription; only `unsubscribe` truncates it.

## C-5: `YoutubeFeedEntryDao` (Drift accessor)

Public methods that exist today and that the implementation must respect:

| Method | Use after the refactor |
|---|---|
| `watchTimeline()` | **Used by `DiscoverRepository.watchTimeline`** (C-4). Unchanged. |
| `watchForChannel(channelId)` | **Used by `DiscoverRepository.watchChannelFeed`** (C-4). Unchanged. |
| `upsertEntry(YoutubeFeedEntryRow row)` | **Used by `DiscoverRepository._refreshChannel`** (C-2). InsertOrReplace by composite PK `(videoId, channelId)`. Unchanged. |
| `getEntry({channelId, videoId})` | **Used by `_refreshChannel` to preserve `durationSeconds` and by `_enrichMissingDurations` to skip already-enriched entries.** Unchanged. |
| `updateDurationSeconds(...)` | **Used by `_enrichMissingDurations`** to fill in durations post-refresh. Unchanged. |
| `deleteForChannel(channelId)` | **Used by `unsubscribe`** (C-3) and by `_repairLegacyCatalogChannelIds`. Unchanged. |
| _former_ `deleteStaleForChannel(channelId, keepVideoIds)` | **Removed** as part of this refactor (ADR-0046). The append-only cache no longer needs a prune helper; if a future "compact cache" affordance is introduced, it should be added back with explicit intent rather than reintroducing this name. |

## C-6: Drift schema (`youtube_feed_entries`)

Schema is **unchanged**. Composite PK `(videoId, channelId)`. The append-only behavior is a runtime invariant, not a schema invariant — keeping the schema stable avoids a forced migration for every existing install.

## C-7: UI surface

- `discover_screen.dart` (merged timeline) and `channel_feed_screen.dart` (per-channel feed) consume `watchTimeline` and `watchChannelFeed`. They render `FeedEntry` lists sorted by `publishedAt DESC`.
- The existing `ValueKey<String>('discover-feed-<videoId>')` / `'channel-feed-<videoId>'` keys plus `findChildIndexCallback` ensure that appending new entries at the head does not rebuild existing tiles. The append-only behavior makes this pattern more important, not less — no change to widget code is required.

## C-8: External (out of scope)

This refactor does **not** touch:

- The YouTube RSS endpoint contract (`feeds/videos.xml`); the same Atom feed is consumed.
- The `videos` table (library rows); library import flow is unchanged.
- The channel subscription / avatar pipeline.
- Drift schema migrations (no migration introduced).
- Any cloud-sync surface (ADR-0010); Discover is local-only.

## Verification of contracts

- C-2 is exercised by `discover_repository_test.dart` (append-only behavior matrix).
- C-3 is exercised by `discover_subscribe_actions_test.dart`.
- C-4 dedupe behavior is exercised by `discover_dedupe_test.dart` (the `watchChannelFeed` filter and `watchTimeline` dedupe tests stay green after the refactor; tests that asserted the RSS-prune path was active are updated to assert the new append-only behavior).
- C-5 (DAO contract) is exercised by `test/data/db/app_database_test.dart` and the discover repository tests.