# Data Model: Discover Feed Append-Only Persistence

**Feature**: [spec.md](spec.md) | **Date**: 2026-07-13

No schema changes are introduced. This document pins down the *observable behavior* of each touched row and column so the implementation cannot drift from the spec.

## Entities

### YoutubeFeedEntryRow (existing — schema unchanged)

Cached metadata for a single (channel, video) pair that we have seen via the channel's RSS feed.

| Field            | Type      | Nullable | Notes                                                                                                   |
|------------------|-----------|----------|---------------------------------------------------------------------------------------------------------|
| `videoId`        | `String`  | no       | PK (composite). YouTube 11-char video id.                                                               |
| `channelId`      | `String`  | no       | PK (composite). YouTube `UC…` 24-char channel id.                                                       |
| `title`          | `String`  | no       | Decoded from `<title>`. Mutable across refreshes.                                                       |
| `thumbnailUrl`   | `String?` | yes      | From `<media:thumbnail url="…">`. Mutable across refreshes.                                             |
| `durationSeconds`| `int?`    | yes      | Set later by `YoutubeVideoDuration` enrichment or copied from the library row on refresh.              |
| `publishedAt`    | `DateTime`| no       | From `<published>`. **Sort key** for `watchTimeline` and `watchChannelFeed`.                            |
| `fetchedAt`      | `DateTime`| no       | **Semantic shift (see ADR-0046)**: now represents the last time the source re-presented this entry, not "first time observed". |

**Primary key**: `{videoId, channelId}` — composite. Refresh idempotency relies on this PK: re-upserting the same `(channelId, videoId)` row replaces title / thumbnail / duration / publishedAt / fetchedAt, never creating a duplicate.

**Lifecycle**:

1. **Insert** — a refresh sees a `(channelId, videoId)` that is not yet in the table. Triggered when the channel publishes a new video since the last refresh we ran.
2. **Update** — a refresh sees a `(channelId, videoId)` already in the table. We write the new `fetchedAt` and any changed `title` / `thumbnailUrl` / `publishedAt`. This is the common case for the 15 most-recent videos.
3. **Retained without update** — a refresh runs but the RSS payload does not include a given `(channelId, videoId)` (because the channel has published > 15 videos since that one was made). The row stays untouched until either a future refresh re-presents it or the user unsubscribes.
4. **Delete on unsubscribe** — `unsubscribe(channelId)` deletes every row with `channelId == <channelId>`. No time-based or count-based retention is applied to retained rows.

**Validation rules**:

- `videoId` and `channelId` MUST match the YouTube id shapes (`videoId` 11 chars, `channelId` matches `^UC[\w-]{22}$`).
- `publishedAt` MUST be a UTC `DateTime`; the RSS parser produces UTC.
- `fetchedAt` MUST equal the timestamp at which the refresh wrote the row; it is never `null` once the row exists.

### YoutubeChannelSubscriptionRow (existing — schema unchanged)

The source of truth for which channels the user follows. Untouched by this refactor.

| Field            | Type                       | Nullable | Notes                                                              |
|------------------|----------------------------|----------|--------------------------------------------------------------------|
| `channelId`      | `String`                   | no       | PK.                                                               |
| `displayName`    | `String`                   | no       | Editable; updated from the RSS feed title on refresh.              |
| `thumbnailUrl`   | `String?`                  | yes      | Channel avatar (not video thumbnail).                              |
| `source`         | `YoutubeSubscriptionSource`| no       | `recommended` or `user`.                                          |
| `subscribedAt`   | `DateTime`                 | no       | Immutable.                                                         |
| `lastFetchedAt`  | `DateTime?`                | yes      | **Refresh cooldown driver**. Updated only on successful refresh.   |
| `language`       | `String`                   | no       | Default `'und'` (unknown).                                        |

**Lifecycle for `lastFetchedAt`**:

- Written by `_refreshChannel` only after the RSS fetch + parse + upsert completes successfully.
- **NOT written on failure** — failed refreshes propagate through `DiscoverRefreshResult.failedChannelIds` and the timestamp stays at its previous value so the next eligible refresh can re-attempt.

### DiscoverChannel (existing — domain projection)

Read-only projection of `YoutubeChannelSubscriptionRow`. Unchanged.

### FeedEntry (existing — domain projection)

Read-only projection of `YoutubeFeedEntryRow`. Unchanged. `==` and `hashCode` cover every field; ordering on the UI is `publishedAt DESC`.

## Relationships

- `YoutubeChannelSubscriptionRow.channelId` 1 — N `YoutubeFeedEntryRow.channelId`
  - A subscription has zero or more feed entries.
  - On unsubscribe, the N entries are deleted (existing `deleteForChannel` behavior).
- `YoutubeFeedEntryRow.videoId` may match a `videos` row's YouTube provider id
  - When a feed entry is added to the library via `addFeedEntryToLibrary`, the corresponding `videos` row is created. The feed entry remains in the cache after library import.

## State transitions for the cache

```
                    (refresh inserts)
   [absent] ------------------------------> [present, fetchedAt = T0]
                                              |
                                              | (refresh updates metadata)
                                              v
                                          [present, fetchedAt = T1]
                                              |
                                              | (refresh omits it from payload,
                                              |  user remains subscribed)
                                              v
                                          [present, fetchedAt = T0 still]
                                              |
                                              | (refresh re-presents it)
                                              v
                                          [present, fetchedAt = T2 > T1]

   At any time:
     [present] -- unsubscribe --> [absent]
```

There is no other transition. Time-based retention, manual "clear cache", or per-channel TTL are deferred per the spec Assumptions.

## Constraints summary

- No `print()` is added anywhere that touches these rows; logging uses `logNamed('discover.repository')`.
- Writes go through `YoutubeFeedEntryDao` (no raw SQL in features).
- Tests use `AppDatabase(executor: NativeDatabase.memory())` (see `test/data/db/app_database_test.dart`) for deterministic in-memory runs.