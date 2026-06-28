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

- **All** — timeline across all subscribed channels
- **Channel avatars** — filter the feed to one subscription
- **Manage channels** — opens subscription management (see below)

Desktop: header **Refresh** button. No inline subscription or recommended lists on the main scroll.

## Manage channels

Opened from the filter strip (bottom sheet on narrow layouts, centered dialog at `breakpointRail` and wider):

- **Subscribe** (paste URL / `@handle`) — same resolver as before
- **Your channels** — list with **Unsubscribe** (does not navigate away from the modal)
- **Recommended** — bundled catalog (`assets/discover/recommended_channels.json`) with **Subscribe** / **Subscribed** badges

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

RSS URL: `https://www.youtube.com/feeds/videos.xml?channel_id=<id>`

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

## Add to library

Uses the same path as **Import → From YouTube URL**: oEmbed metadata, `videos` row with `provider: youtube`, optional sync enqueue when signed in. Duplicate video ids show **In library** instead of add.

## Transcripts

No caption availability in RSS. After import, transcript loading follows [`transcript.md`](transcript.md) and [`youtube.md`](youtube.md). Recommended channels are chosen partly for reliable captions, but empty transcript states remain possible.

## Limitations

- ~15 recent videos per channel per RSS fetch
- **YouTube Shorts** are excluded (RSS alternate link uses `/shorts/`)
- Handle → `channel_id` resolution may fail if YouTube HTML changes
- Subscriptions and feed cache are per local SQLite file (guest vs signed-in user DB)
- Avatar LRU cache is per-process (not per-DB); the 256-entry cap evicts
  the least-recently-used channel id on overflow

## Related

- [ADR-0021](../decisions/0021-youtube-discover-rss.md)
- [youtube.md](youtube.md)
