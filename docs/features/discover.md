# Discover (YouTube feeds)

## Summary

**Discover** helps users find YouTube videos to practice with when they do not already have a URL. Browse **recommended channels** (bundled catalog), **subscribe** to YouTube channels, handles, and playlists locally, view a merged **timeline** of recent uploads (fetched via a server-side RSSHub proxy), and **Add to library** to start echo / transcript workflows.

Discover feeds are **not** library items until imported. Subscriptions are **Enjoy-local** — not YouTube account subscriptions. Multi-device sync uses the existing cloud sync infrastructure (ADR-0010, ADR-0013).

## Navigation

- Shell tab **Discover** → `/discover`
- Channel feed → `/discover/channel/:channelId`
- Home empty state → secondary **Browse Discover** action

## Main screen (videos-first)

The Discover tab shows a **merged video feed** only (responsive grid of recent uploads). A horizontal **filter strip** sits below the header:

- **All** — timeline across all subscribed channels
- **Channel avatars** — filter the feed to one subscription
- **Manage channels** — opens subscription management (see below)

Desktop: header **Refresh** button. No inline subscription or recommended lists on the main scroll.

## Manage channels

Opened from the filter strip (bottom sheet on narrow layouts, centered dialog at `breakpointRail` and wider):

- **Subscribe** (paste URL / `@handle` / channel ID / playlist ID)
- **Your channels** — list with **Unsubscribe** (does not navigate away from the modal)
- **Recommended** — bundled catalog (`assets/discover/recommended_channels.json`) with **Subscribe** / **Subscribed** badges; channels are **language-tagged** (English, Japanese, Korean, Spanish, French in the first wave). The list is filtered to the user's focus learning language by default, with **All languages** to browse everything.

Empty Discover state (no subscriptions) prompts **Manage channels** so users can add recommended channels first.

## Subscriptions (elsewhere)

- Tap a subscription from **channel feed** app bar row context, or navigate to `/discover/channel/:channelId` from library flows as before
- **Unsubscribe** in Manage channels or channel feed app bar removes the subscription and cached feed entries
- Filter selection resets to **All** if the active channel is unsubscribed

## Feed refresh

| Trigger | Behavior |
|---------|----------|
| App launch | Debounced refresh for eligible sources |
| Pull-to-refresh (mobile) | Force refresh all subscriptions |
| Header refresh button (desktop) | Same as pull-to-refresh |
| Periodic (8 h) | Background refresh while app runs |
| Per-source skip | Skip if last fetch < 1 h unless forced |

### Data source (single-source RSSHub proxy)

The per-source refresh path is **single-source** ([ADR-0051](../decisions/0051-youtube-worker-discovery.md)):

All video discovery requests go through a **server-side RSSHub proxy**, never directly to YouTube. The worker exposes three RSSHub YouTube routes:

| Route | Example | Returns |
|-------|---------|---------|
| `GET /youtube/channel/{id}` | `/youtube/channel/UC...` | Channel feed (reverse-chronological) |
| `GET /youtube/user/{handle}` | `/youtube/user/@TED` | Handle feed (resolves to channel) |
| `GET /youtube/playlist/{id}` | `/youtube/playlist/PL...` | Playlist feed (playlist order) |

The client requests JSON Feed v1.1 format (via `?format=json`). See the [worker feed API contract](../../specs/018-youtube-worker-discovery/contracts/worker-feed-api.md) for the full response schema.

**Feed-level fields** from JSON Feed v1.1:
- `title` — source display name (the client strips " - YouTube" suffix)
- `home_page_url` — YouTube source URL (contains canonical channel/playlist ID)
- `icon` — avatar URL

**Item-level fields** from JSON Feed v1.1:
- `id` — video ID (extracted from YouTube watch URL)
- `url` — YouTube watch URL
- `title` — video title
- `image` — thumbnail URL
- `date_published` — published timestamp (ISO 8601)
- `attachments[].duration_in_seconds` — video duration

The refresh client ([`YoutubeFeedClient`](../../lib/data/api/services/ai/youtube_feed_api.dart), provided by `youtubeFeedClientProvider` with bearer auth from `SecureTokenStore.readAccessToken`) handles:
- HTTP status codes → typed exceptions (404 → notFound, 410 → sourceUnavailable, 429 → rateLimited, 502 → upstreamFailure)
- Handle-to-ID canonicalization: when subscribing via @handle, the client extracts the canonical channel ID from `home_page_url` and uses `/youtube/channel/{id}` for subsequent refreshes
- Network errors → networkError exception
- Runtime repair: if a subscription's `feed_url` is missing, regenerate it before fetch (covers pre-v13 rows that missed the backfill)

### Cache semantics (append-only)

The `youtube_feed_entries` cache is **append-only between unsubscribe events** ([ADR-0046](../decisions/0046-discover-feed-append-only.md)). A refresh:

- Inserts feed entries that are new to the cache (new uploads since the last refresh).
- Updates mutable metadata (`title`, `thumbnailUrl`, `publishedAt`) and `fetchedAt` on entries the source re-presented.
- **Does not delete** cached entries that fell out of the source's most-recent window (~15–50 entries).
- Uses video ID deduplication — if all returned entries are already cached, no changes are made and `lastFetchedAt` is still updated.
- Writes each source's upserts in **one Drift `batch` / transaction** (`YoutubeFeedEntryDao.upsertEntries`). Non-empty refreshes therefore emit a **single** `watchTimeline` update; empty responses are a no-op (no watcher churn).

The user-visible way to bound cache growth is to **unsubscribe** from a source — `DiscoverRepository.unsubscribe(channelId)` deletes every cached entry for that channel.

Duration: Comes from `attachments[].duration_in_seconds` in the JSON Feed response. No legacy watch-page HTML duration enrichment is performed.

### Handle-to-ID canonicalization

When a user subscribes via @handle (e.g., `https://youtube.com/@TED`):
1. The client fetches `GET /youtube/user/@TED?format=json`
2. The response `home_page_url` contains the canonical channel URL: `https://www.youtube.com/channel/UCAuUUnT6oDeKwE6v1NGQxug`
3. The client extracts the channel ID (`UCAuUUnT6oDeKwE6v1NGQxug`) from this URL
4. All subsequent refreshes use `GET /youtube/channel/UCAuUUnT6oDeKwE6v1NGQxug?format=json`

This prevents duplicate subscriptions (handle + channel ID pointing to the same source) and avoids redundant handle resolution on every refresh.

### YT source language removal

Subscription rows may still store a catalog `language` column (schema v10) for recommended-channel bookkeeping, but the **DiscoverChannel** domain model and UI no longer expose a per-subscription language:

- There is no **Language scope** toggle on the filter strip and no language label / editor on subscription rows.
- **Add to library** does not infer media content language from a subscription; callers pass an explicit `contentLanguage` or default to `und` (`kUnknownMediaLanguageTag`).
- Recommended-catalog filtering by the learner's focus language remains (catalog tags on bundled channels only).

### Scheduler gating

The periodic refresh is intentionally **passive**:

- **Subscription-gated** — the 8 h `Timer` is only armed while the subscription list is non-empty.
- **Lifecycle-gated** — periodic ticks and the post-launch initial refresh are skipped while the app is not in the foreground.
- **Idempotent launch** — only one post-frame launch refresh is scheduled per provider instance.

### Concurrency

Per-source worker feed fetches run with a bounded concurrency cap of 4 (`_kRefreshChannelConcurrency`), so a user with many subscriptions refreshes in ~`ceil(N / 4)` round-trips instead of N.

### Partial-failure surfacing

`DiscoverRepository.refreshFeeds` returns `DiscoverRefreshResult { refreshedChannels, failedChannelIds }`. The UI consults `hasFailures` and surfaces per-source failures via `AppNotice.error`:

- One failed source → `Could not refresh {name}.`
- Many → `Could not refresh {count} sources: {names}`

Successful sources keep their updated entries; only the failed ones' feed entries are left untouched.

## Channel avatar cache

Recommended row and subscription avatars are stored in the Drift `youtube_channel_subscriptions.thumbnailUrl` column (set from the feed's `icon` field on subscribe/refresh). An in-memory LRU cache (`L1Store`) provides fast lookup:

- Capacity: **256 entries**
- **TTL: 6 hours**
- Lifecycle: lives for the lifetime of the repository instance

Failures during avatar fetch return `null`, so the caller can fall back to a placeholder.

## Sliver performance

The merged feed grid and the channel feed grid both use stable `ValueKey<String>` — `discover-feed-<videoId>` on the merged feed, `channel-feed-<videoId>` on the channel feed — plus `findChildIndexCallback` via `findSliverIndexByPrefixedId` so a refresh that only prepends new entries reuses existing tile `Element`s.

## Add to library

Uses the same path as **Import → From YouTube URL**: oEmbed metadata, `videos` row with `provider: youtube`, optional sync enqueue when signed in. Duplicate video ids show **In library** instead of add. Media content language comes from an explicit import choice (or `und`), not from the subscription row.

## Transcripts

No caption availability in the worker feed. After import, transcript loading follows [`transcript.md`](transcript.md) and [`youtube.md`](youtube.md).

## Limitations

- **Fixed feed size.** The RSSHub proxy returns a fixed set of entries (~15–50 per feed). Pagination and `since`-based incremental refresh are deferred to a follow-up enhancement.
- **View count not available.** JSON Feed v1.1 does not expose view counts; the client cannot display per-video view counts from the worker feed.
- **Worker dependency.** Initial subscription requires worker connectivity for feed fetching. Cached entries remain fully browsable offline.
- Subscriptions and feed cache live in the signed-in per-user SQLite file (`enjoy_player_<userId>`)
- No hard upper bound on per-channel cache size in v1; users bound growth by unsubscribing (see [ADR-0046](../decisions/0046-discover-feed-append-only.md))

## Related

- [ADR-0051](../decisions/0051-youtube-worker-discovery.md) — moved YouTube discovery to server-side RSSHub proxy
- [ADR-0021](../decisions/0021-youtube-discover-rss.md) — original RSS-only discovery (superseded by 0051)
- [ADR-0046](../decisions/0046-discover-feed-append-only.md) — append-only feed cache
- [ADR-0047](../decisions/0047-youtube-discover-innertube.md) — InnerTube primary source (superseded by 0051)
- [Worker feed API contract](../../specs/018-youtube-worker-discovery/contracts/worker-feed-api.md)
- [youtube.md](youtube.md)
