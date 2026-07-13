# ADR-0046: Discover feed cache is append-only between unsubscribe events

## Status

Accepted

## Context

The Discover feature fetches YouTube channel RSS feeds (`https://www.youtube.com/feeds/videos.xml?channel_id=…`) on launch, on pull-to-refresh, on header refresh, and on an 8 h lifecycle-gated timer. The per-channel refresh used to pass the ~15 video ids from the latest RSS payload to `_db.youtubeFeedEntryDao.deleteStaleForChannel(channelId, keepVideoIds)` so cached rows absent from that payload were pruned.

YouTube's RSS endpoint returns only the 15 most recent uploads per channel. With the previous "wipe and rewrite" refresh, the `youtube_feed_entries` cache was effectively truncated to those 15 newest entries on every refresh. Cached entries that fell out of the RSS window (because the channel published newer videos) were silently deleted, even though the cache row still had valid metadata (`title`, `thumbnailUrl`, `publishedAt`) and could be useful for browsing history or for re-import later.

User-visible consequence: subscribers could not browse more than the 15 newest uploads of any channel. The Discover feed did not behave like a conventional RSS reader — every refresh felt like a fresh "first paint" of the channel, not a continuously growing feed.

## Decision

1. `DiscoverRepository._refreshChannel` no longer deletes cache rows based on what is (or is not) in the latest RSS payload. The cache is **append-only** between unsubscribe events.
2. Each refresh upserts entries keyed by `(channelId, videoId)` (the composite primary key already in place). New uploads insert; previously seen entries have their mutable metadata (`title`, `thumbnailUrl`, `publishedAt`) and `fetchedAt` refreshed.
3. The previous `YoutubeFeedEntryDao.deleteStaleForChannel` helper is **removed**. It was the only path that pruned rows based on RSS omission, and the append-only decision supersedes that behavior. If a future need to prune stale rows ever arises (e.g., a manual "compact cache" affordance), a new DAO method with explicit intent should be reintroduced — do not re-add `deleteStaleForChannel` under the old contract.
4. Unsubscribing from a channel continues to delete every cached entry for that channel via `YoutubeFeedEntryDao.deleteForChannel` (existing behavior). This is the user-visible way to bound cache growth.
5. `YoutubeFeedEntryRow.fetchedAt` semantics shift: it now represents "the last time the source re-presented this entry", not "the first time we observed it". Older rows that fell out of the RSS window keep their original `fetchedAt`.
6. Failed refreshes (HTTP error, bot-block page, malformed XML) leave the cache and `lastFetchedAt` untouched. Only successful refreshes advance the cooldown clock.

No Drift schema change is required. No new dependencies are added. No widget code is touched — the existing `ValueKey` + `findChildIndexCallback` sliver pattern already supports append-at-the-head updates cleanly.

## Consequences

Positive:

- A subscribed channel's Discover feed grows monotonically over time, matching conventional RSS reader behavior. Users can scroll back through older uploads from the channel feed and the merged timeline (filtered to that channel).
- Long-lived subscriptions accumulate a richer history that the user can revisit without re-subscribing or re-importing from external sources.
- The refresh path does *less* work (no `keepVideoIds` set construction, no DELETE statement).

Negative / trade-offs:

- The `youtube_feed_entries` table grows over time. Worst-case at the spec budget (20 subscriptions × 500 cached entries) is ~10 000 rows per user database. This is well within SQLite's comfort zone but does increase storage. No hard upper bound is introduced in this change; if storage becomes a real concern, a future ADR can introduce per-channel FIFO eviction or a TTL.
- Diagnostics counters that read `youtube_feed_entries` row counts now reflect history, not "latest snapshot". The metric's interpretation changes — it goes from "videos currently in the refresh window" to "videos ever seen via RSS for any subscribed channel".
- A row whose video has been deleted by YouTube stays in the cache until the user unsubscribes. Playback will surface a separate "video unavailable" path already used elsewhere; the cache row is not a playback contract.

## References

- Spec: `specs/016-append-only-discover-feed/spec.md`
- Plan: `specs/016-append-only-discover-feed/plan.md`
- ADR-0021: YouTube discovery via RSS and local channel subscriptions — the original RSS-as-data-source decision; this ADR refines the cache semantics without changing the data source.
- Feature documentation: `docs/features/discover.md`
- Implementation:
  - `lib/features/discover/data/discover_repository.dart` (`_refreshChannel`)
  - `lib/data/db/app_database.dart` (`YoutubeFeedEntryDao.deleteStaleForChannel` removed)
  - `test/features/discover/discover_repository_test.dart` (new append-only tests; flipped prune test)