# Data Model: InnerTube Channel Discover

**Feature**: [spec.md](spec.md) | **Date**: 2026-07-13

No schema changes are introduced. This document pins down the *observable behavior* of each touched row and column, plus the new internal projection (`BrowseVideoEntry`) used by `YoutubeBrowseClient`, so the implementation cannot drift from the spec.

## Entities

### YoutubeFeedEntryRow (existing — schema unchanged, write semantics tightened)

Cached metadata for a single (channel, video) pair that we have seen via the channel's refresh path (either InnerTube primary or RSS fallback).

| Field            | Type      | Nullable | Notes                                                                                                   |
|------------------|-----------|----------|---------------------------------------------------------------------------------------------------------|
| `videoId`        | `String`  | no       | PK (composite). YouTube 11-char video id.                                                               |
| `channelId`      | `String`  | no       | PK (composite). YouTube `UC…` 24-char channel id.                                                       |
| `title`          | `String`  | no       | From `videoRenderer.title.runs[].text` (InnerTube) or `<title>` (RSS). Mutable across refreshes.       |
| `thumbnailUrl`   | `String?` | yes      | From `videoRenderer.thumbnail.thumbnails[0].url` (InnerTube) or `<media:thumbnail url>` (RSS). Mutable. |
| `durationSeconds`| `int?`    | yes      | **Behavior change**: written immediately when the InnerTube primary path supplies `lengthText`. Otherwise filled by the legacy watch-page HTML enrichment on the RSS fallback path, or left `null`. |
| `publishedAt`    | `DateTime`| no       | From `videoRenderer.publishedTimeText.simpleText` (parsed via a tiny formatter; InnerTube) or `<published>` (RSS, parsed as ISO 8601 UTC). **Sort key** for `watchTimeline` and `watchChannelFeed`. |
| `fetchedAt`      | `DateTime`| no       | **Semantic shift (per ADR-0046)**: last time the source re-presented this entry. Same as today.        |

**Primary key**: `{videoId, channelId}` — composite. Refresh idempotency relies on this PK: re-upserting the same `(channelId, videoId)` row replaces title / thumbnail / duration / publishedAt / fetchedAt, never creating a duplicate.

**Lifecycle**:

1. **Insert** — refresh sees a `(channelId, videoId)` not yet in the table. Triggered when the channel publishes a new video since the last refresh we ran.
2. **Update** — refresh sees a `(channelId, videoId)` already in the table. We write the new `fetchedAt` and any changed metadata. The duration is overwritten if the InnerTube primary path returned a `lengthText` (or the watch-page enrichment ran on the RSS fallback path).
3. **Retained without update** — refresh runs but neither the InnerTube primary path nor the RSS fallback returned a given `(channelId, videoId)`. The row stays untouched until either a future refresh re-presents it or the user unsubscribes. (Append-only per ADR-0046.)
4. **Delete on unsubscribe** — `unsubscribe(channelId)` deletes every row with `channelId == <channelId>` (existing `deleteForChannel` behavior).

**Validation rules**:

- `videoId` and `channelId` MUST match the YouTube id shapes (`videoId` 11 chars, `channelId` matches `^UC[\w-]{22}$`).
- `publishedAt` MUST be a UTC `DateTime`; the InnerTube parser converts `publishedTimeText.simpleText` (a relative string like "3 days ago") to an approximate UTC `DateTime` by subtracting the relative duration from the refresh's `fetchedAt` timestamp. The RSS parser already produces UTC.
- `fetchedAt` MUST equal the timestamp at which the refresh wrote the row; it is never `null` once the row exists.

### YoutubeChannelSubscriptionRow (existing — schema unchanged)

The source of truth for which channels the user follows. Untouched by this feature.

| Field            | Type                       | Nullable | Notes                                                              |
|------------------|----------------------------|----------|--------------------------------------------------------------------|
| `channelId`      | `String`                   | no       | PK.                                                               |
| `displayName`    | `String`                   | no       | Editable; updated from `parseFeedTitle` (RSS) or `channelMetadataRenderer.title` (InnerTube). |
| `thumbnailUrl`   | `String?`                  | yes      | Channel avatar (not video thumbnail).                             |
| `source`         | `YoutubeSubscriptionSource`| no       | `recommended` or `user`.                                          |
| `subscribedAt`   | `DateTime`                 | no       | Immutable.                                                         |
| `lastFetchedAt`  | `DateTime?`                | yes      | **Refresh cooldown driver**. Updated only on successful refresh.   |
| `language`       | `String`                   | no       | Default `'und'` (unknown).                                        |

**Lifecycle for `lastFetchedAt`**:

- Written by `_refreshChannel` only after a successful refresh on **either** source (InnerTube primary OR RSS fallback). Either path's success counts.
- **NOT written on dual failure** — failed refreshes propagate through `DiscoverRefreshResult.failedChannelIds` and the timestamp stays at its previous value so the next eligible refresh can re-attempt.

### BrowseVideoEntry (new — internal projection, never persisted directly)

In-memory projection of a single InnerTube `videoRenderer` plus the continuation token tail (when present). Used only inside `YoutubeBrowseClient.fetchChannelVideos`; never crosses into the repository's public surface.

| Field            | Type        | Nullable | Notes                                                                |
|------------------|-------------|----------|----------------------------------------------------------------------|
| `videoId`        | `String`    | no       | YouTube 11-char video id.                                            |
| `title`          | `String`    | no       | From `videoRenderer.title.runs[].text`.                              |
| `thumbnailUrl`   | `String?`   | yes      | From `videoRenderer.thumbnail.thumbnails[0].url`.                    |
| `durationSeconds`| `int?`      | yes      | From `videoRenderer.lengthText.simpleText` (e.g., `"12:34"`) or `thumbnailOverlayTimeStatusRenderer.text.simpleText`; null when omitted. |
| `publishedAt`    | `DateTime`  | no       | From `videoRenderer.publishedTimeText.simpleText` (relative).        |
| `viewCountText`  | `String?`   | yes      | From `videoRenderer.viewCountText.simpleText` (e.g., `"12K views"`). Not persisted in this plan; available to the UI as a display string if needed. |
| `nextPageToken`  | `String?`   | yes      | From `continuationItemRenderer.continuationEndpoint.continuationCommand.token` on the **last** item of the page, when the source has more entries. |

**Why a separate type**: keeps the InnerTube response shape isolated to one file (`youtube_browse_client.dart`). The repository consumes `BrowseVideoEntry` and projects it to `YoutubeFeedEntryRow` + `FeedEntry`; changes to the InnerTube renderer names do not ripple into the repository, the DAO, or the UI.

**Validation rules**:

- `videoId` MUST be an 11-char YouTube video id.
- `publishedAt` is parsed by `_parseInnerTubePublishedTimeText(simpleText, fetchedAt)` which converts strings like `"3 days ago"`, `"1 hour ago"`, `"Streamed live 2 weeks ago"`, `"Premiered 5 months ago"` into a UTC `DateTime` by subtracting the relative duration from `fetchedAt`. Unknown formats fall back to `fetchedAt` itself (and the entry is still cached).
- `durationSeconds` is parsed by `_parseInnerTubeLengthText(simpleText)` which converts `"H:MM:SS"`, `"MM:SS"`, or `"SS"` into seconds. Unparseable input → `null`.
- `nextPageToken` is the literal token from the InnerTube response — never parsed or transformed.

### DiscoverChannel (existing — domain projection)

Read-only projection of `YoutubeChannelSubscriptionRow`. Unchanged.

### FeedEntry (existing — domain projection)

Read-only projection of `YoutubeFeedEntryRow`. **Optional surface widening**: `FeedEntry.viewCountText` is **not** added in this plan. The duration widening already exists in the type today; the InnerTube primary path now writes to that field more often. No domain-model change is required.

## Relationships

- `YoutubeChannelSubscriptionRow.channelId` 1 — N `YoutubeFeedEntryRow.channelId`
  - On unsubscribe, the N entries are deleted (existing `deleteForChannel` behavior).
- `YoutubeFeedEntryRow.videoId` may match a `videos` row's YouTube provider id
  - When a feed entry is added to the library via `addFeedEntryToLibrary`, the corresponding `videos` row is created. The feed entry remains in the cache after library import.

## State transitions for the cache

Same as today (per ADR-0046):

```
                     (refresh inserts)
   [absent] ------------------------------> [present, fetchedAt = T0]
                                              |
                                              | (refresh updates metadata,
                                              |  possibly filling duration
                                              |  from InnerTube lengthText)
                                              v
                                          [present, fetchedAt = T1]
                                              |
                                              | (refresh omits it from
                                              |  both InnerTube and RSS
                                              |  payloads; user remains
                                              |  subscribed)
                                              v
                                          [present, fetchedAt = T0 still]
                                              |
                                              | (refresh re-presents it
                                              |  on either source)
                                              v
                                          [present, fetchedAt = T2 > T1]

   At any time:
     [present] -- unsubscribe --> [absent]
```

There is no other transition. Time-based retention, manual "clear cache", or per-channel TTL are deferred per the spec Assumptions.

## New constants

| Name | Default | Source file | Purpose |
|---|---|---|---|
| `_kBrowseMaxPages` | `5` | `lib/features/discover/data/youtube_browse_client.dart` | Hard cap on continuation pages per `fetchChannelVideos` call. Bounds wall-clock per channel. |
| `_kBrowsePreferredProfileOrder` | `['web', 'mweb']` | `lib/features/discover/data/youtube_browse_client.dart` | Ordered profile list for InnerTube rotation. `WEB` first, `MWEB` as fallback. |
| `_kBrowsePageSizeEstimate` | `30` | `lib/features/discover/data/youtube_browse_client.dart` | Documented estimate; not a server contract. Used only for diagnostics logging. |

## Constraints summary

- No `print()` is added anywhere that touches these rows; logging uses `logNamed('discover.repository')` and the new `logNamed('discover.browse')`.
- Writes go through `YoutubeFeedEntryDao` (no raw SQL in features).
- Tests use `AppDatabase(executor: NativeDatabase.memory())` (see `test/data/db/app_database_test.dart`) for deterministic in-memory runs.
- No new dependencies, no Drift schema migration, no codegen regeneration, no widget code.
