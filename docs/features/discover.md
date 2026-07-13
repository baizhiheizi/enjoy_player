# Discover (YouTube feeds)

## Summary

**Discover** helps users find YouTube videos to practice with when they do not already have a URL. Browse **recommended channels** (bundled catalog), **subscribe** to channels locally, view a merged **timeline** of recent uploads (RSS), and **Add to library** to start echo / transcript workflows.

Discover feeds are **not** library items until imported. Subscriptions are **Enjoy-local** — not YouTube account subscriptions and not cloud-synced in v1.

## Navigation

- Shell tab **Discover** → `/discover`
- Channel feed → `/discover/channel/:channelId`
- Home empty state → secondary **Browse Discover** action

## Main screen (videos-first)

The Discover tab shows a **merged video feed** only (responsive grid of recent uploads). A horizontal **filter strip** sits below the header:

- **All** — timeline across all subscribed channels (optionally filtered to the focus learning language; see below)
- **Language scope** — toggle between focus-language filtering and **All languages** (recommended strip and merged feed when **All** channel filter is active)
- **Channel avatars** — filter the feed to one subscription
- **Manage channels** — opens subscription management (see below)

Desktop: header **Refresh** button. No inline subscription or recommended lists on the main scroll.

## Manage channels

Opened from the filter strip (bottom sheet on narrow layouts, centered dialog at `breakpointRail` and wider):

- **Subscribe** (paste URL / `@handle`) — same resolver as before
- **Your channels** — list with **Unsubscribe** (does not navigate away from the modal)
- **Recommended** — bundled catalog (`assets/discover/recommended_channels.json`) with **Subscribe** / **Subscribed** badges; channels are **language-tagged** (English, Japanese, Korean, Spanish, French in the first wave). The list is filtered to the user's focus learning language by default, with **All languages** to browse everything.
- **Subscription language** — each subscription stores a channel language (from the catalog or **Unknown** for pasted URLs). Tap the language label on a subscription row to correct it. **Add to library** uses subscription language as the default media content language; unknown-language subscriptions prompt for content language before import.

Empty Discover state (no subscriptions) prompts **Manage channels** so users can add recommended channels first.

## Subscriptions (elsewhere)

- Tap a subscription from **channel feed** app bar row context, or navigate to `/discover/channel/:channelId` from library flows as before
- **Unsubscribe** in Manage channels or channel feed app bar removes the subscription and cached feed entries
- Filter selection resets to **All** if the active channel is unsubscribed

## Feed refresh

| Trigger | Behavior |
|---------|----------|
| App launch | Debounced refresh for eligible channels |
| Pull-to-refresh (mobile) | Force refresh all subscriptions |
| Header refresh button (desktop) | Same as pull-to-refresh |
| Periodic (8 h) | Background refresh while app runs |
| Per-channel skip | Skip if last fetch &lt; 1 h unless forced |

### Data sources (dual-source)

The per-channel refresh path is **dual-source** ([ADR-0047](../decisions/0047-youtube-discover-innertube.md)):

1. **InnerTube `browse`** (primary) — `POST https://youtubei.googleapis.com/youtubei/v1/browse` with `browseId: "UC<channelId>"`. Returns a richer JSON payload (`videoId`, `title`, `thumbnail`, `lengthText`, `publishedTimeText`, `viewCountText`) and is materially less likely to be blocked by YouTube's bot detection than the public RSS endpoint.
2. **Atom RSS** (fallback) — `GET https://www.youtube.com/feeds/videos.xml?channel_id=<id>`. Used only when InnerTube fails (transport, shape drift, or HTTP 401/403/5xx across all configured client profiles).

`DiscoverRepository._refreshChannel` tries InnerTube first; on `YoutubeBrowseException` it falls back to RSS. Either source's success counts; both failing reports the channel id in `DiscoverRefreshResult.failedChannelIds` and leaves the cache and `lastFetchedAt` untouched.

#### Client profile rotation

The InnerTube call uses the same shared `ClientProfile` model as the YouTube caption fetcher (`lib/features/transcript/data/client_profile.dart`). The per-channel retry ladder is:

- `WEB` (desktop) — preferred primary
- `MWEB` (mobile web) — fallback

`IOS` and `ANDROID_VR` remain in `kBuiltInClientProfiles` for the caption fetcher's rotation; they are not used for `browse`. The cold-start fallback reuses the same built-in surface the caption fetcher already has, so no separate storage is required.

#### Pagination and page cap

InnerTube returns ~30 entries per page. When the page ends with a `continuationItemRenderer.continuationEndpoint.continuationCommand.token`, `YoutubeBrowseClient.fetchChannelVideos` follows the token with another POST to the same endpoint (`{ context, continuation }`). The loop is capped at **`kBrowseMaxPages = 5`** (≈ 150 entries per channel) per call, so a single very active channel cannot monopolize the 4-way concurrency budget.

#### Legacy fallback

RSS URL: `https://www.youtube.com/feeds/videos.xml?channel_id=<id>`. The fallback path is the same path that was the sole source before this feature ([ADR-0021](../decisions/0021-youtube-discover-rss.md)).

### Cache semantics (append-only)

The `youtube_feed_entries` cache is **append-only between unsubscribe events** ([ADR-0046](../decisions/0046-discover-feed-append-only.md)). A refresh:

- Inserts feed entries that are new to the cache (new uploads since the last refresh).
- Updates mutable metadata (`title`, `thumbnailUrl`, `publishedAt`) and `fetchedAt` on entries the source re-presented.
- **Does not delete** cached entries that fell out of the source's most-recent window. Whether the source is the InnerTube `browse` payload (typically ~30 newest per page) or the Atom RSS payload (~15 newest), the cache keeps older entries so users can browse and re-import them.

The user-visible way to bound cache growth is to **unsubscribe** from a channel — `DiscoverRepository.unsubscribe(channelId)` deletes every cached entry for that channel.

`YoutubeFeedEntryRow.fetchedAt` represents the last time the source re-presented the entry. Older rows that fell out of the source's window keep their original `fetchedAt`. Diagnostic counters that report `youtube_feed_entries` row counts now reflect history, not just the latest snapshot.

### InnerTube-supplied metadata

When the InnerTube primary path returns a `lengthText` for an entry, the parsed `durationSeconds` is written to `YoutubeFeedEntries.durationSeconds` immediately. The legacy watch-page HTML duration enrichment (`YoutubeVideoDuration.fetchSeconds`) is **not** invoked for InnerTube-sourced rows in that tick.

When InnerTube omits `lengthText`, the cache row carries `durationSeconds = null` and the legacy enrichment is still skipped — the row is cached as-is, with whatever metadata the source returned. The legacy enrichment runs only on the RSS fallback path, matching the pre-change behavior on that branch.

Duration preference order per upsert:

1. Library row (`videos.durationSeconds > 0`) — the user's source of truth once the video is imported.
2. InnerTube-supplied `BrowseVideoEntry.durationSeconds`.
3. Existing cache row's `durationSeconds` (preserved across refreshes per [ADR-0046](../decisions/0046-discover-feed-append-only.md)).

### Scheduler gating

The periodic refresh is intentionally **passive**:

- **Subscription-gated** — the 8 h `Timer` is only armed while the
  subscription list is non-empty. An empty list (a fresh install, or a
  user who unsubscribed from everything) does **not** wake the app.
  The arm is re-evaluated every time `discoverSubscriptionsProvider`
  emits, so a re-subscription re-arms the timer without an app restart.
- **Lifecycle-gated** — periodic ticks and the post-launch initial
  refresh are skipped while the app is not in the foreground
  (`WidgetsBinding.instance.lifecycleState != resumed`). A `null`
  lifecycle state is treated as resumed so headless / desktop contexts
  without lifecycle callbacks are not silently starved.
- **Idempotent launch** — only one post-frame launch refresh is
  scheduled per provider instance; the flag resets when the
  subscription list becomes empty again.

### Concurrency

Per-channel RSS refresh and per-entry duration enrichment both run
with a bounded concurrency cap, so a user with many subscriptions
refreshes in roughly `ceil(N / cap)` round-trips instead of `N`:

| Phase | Cap | Implementation |
|-------|-----|----------------|
| RSS refresh (per channel) | 4 | Windowed `Future.wait` over the subscription list (`_kRefreshChannelConcurrency`) |
| Duration enrichment (per entry) | 4 | Counting semaphore with a FIFO waiter queue (`_kEnrichDurationConcurrency`) |

YouTube's RSS endpoints are soft-rate-limited; 4 concurrent keeps us
well under the threshold while turning a 20-channel refresh from
~20 RTTs into ~5 RTTs.

### Partial-failure surfacing

`DiscoverRepository.refreshFeeds` returns
`DiscoverRefreshResult { refreshedChannels, failedChannelIds }`. The
UI consults `hasFailures` and surfaces per-channel failures via
`AppNotice.error`:

- One failed channel → `Could not refresh {name}.`
- Many → `Could not refresh {count} channels: {names}`

Successful channels keep their updated entries; only the failed
ones' feed entries are left untouched. The next refresh retry (manual
or the next 8 h tick) re-attempts them with the standard
1 h skip-window.

## Channel avatar cache

Recommended row and subscription avatars go through
`DiscoverRepository.fetchChannelAvatarUrl`, which keeps a bounded
**in-memory LRU cache**:

- Backing store: `LinkedHashMap<String, String>` (move-to-end on hit,
  evict from head on overflow).
- Capacity: **256 entries** (`_kAvatarCacheCapacity`).
- Lifecycle: lives for the lifetime of the repository instance
  (singleton via `discoverRepositoryProvider`).
- Scope: per-app, not per-user-DB; subscribers moving between
  accounts will see a cold avatar cache.

Failures during avatar fetch are logged at `fine` and surface as
`null`, so the caller can fall back to a placeholder.

## Sliver performance

The merged feed grid (main Discover screen) and the channel feed grid (`/discover/channel/:channelId`) both re-render their full entry list on every RSS refresh. Each tile uses a stable `ValueKey<String>` — `discover-feed-<videoId>` on the merged feed, `channel-feed-<videoId>` on the channel feed — plus `findChildIndexCallback` via [`findSliverIndexByPrefixedId`](../../lib/core/utils/sliver_key_index.dart) so a refresh that only prepends new entries reuses existing tile `Element`s instead of rebuilding the whole visible grid.

Since the cache became append-only ([ADR-0046](../decisions/0046-discover-feed-append-only.md)), the stable `ValueKey` pattern is even more important: a refresh that only adds a few new entries at the head of the timeline must not rebuild the visible window of older entries. See [conventions.md § Sliver performance](../conventions.md#sliver-performance-long-live-lists) for the shared convention.

## Add to library

Uses the same path as **Import → From YouTube URL**: oEmbed metadata, `videos` row with `provider: youtube`, optional sync enqueue when signed in. Duplicate video ids show **In library** instead of add.

## Transcripts

No caption availability in RSS. After import, transcript loading follows [`transcript.md`](transcript.md) and [`youtube.md`](youtube.md). Recommended channels are chosen partly for reliable captions, but empty transcript states remain possible.

## Limitations

- Each InnerTube `browse` page returns ~30 videos; the page cap is 5 (~150 videos) per channel per refresh tick. The Atom RSS fallback returns ~15 most recent videos per channel — a per-fetch payload cap, not a cache cap. The cache itself is append-only between unsubscribe events (see [Cache semantics (append-only)](#cache-semantics-append-only)).
- **YouTube Shorts** are excluded (RSS alternate link uses `/shorts/`)
- Handle → `channel_id` resolution may fail if YouTube HTML changes
- Subscriptions and feed cache live in the signed-in per-user SQLite file (`enjoy_player_<userId>`)
- Avatar LRU cache is per-process (not per-DB); the 256-entry cap evicts
  the least-recently-used channel id on overflow
- No hard upper bound on per-channel cache size in v1; users bound growth by unsubscribing (see [ADR-0046](../decisions/0046-discover-feed-append-only.md))
- **Playlist import is not yet supported.** Subscribing to a `https://youtube.com/playlist?list=…` URL and surfacing playlist uploads is tracked as a separate follow-up spec; the current feature scopes to channel refresh only.

## Related

- [ADR-0021](../decisions/0021-youtube-discover-rss.md)
- [ADR-0046](../decisions/0046-discover-feed-append-only.md)
- [ADR-0047](../decisions/0047-youtube-discover-innertube.md)
- [youtube.md](youtube.md)
