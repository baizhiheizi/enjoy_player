# ADR-0021: YouTube discovery via RSS and local channel subscriptions

## Status

Accepted

## Context

YouTube import today requires a pasted URL ([ADR-0015](0015-youtube-playback.md)). Users without a specific target must browse YouTube externally. Language learners often want curated, captioned-friendly channels (TED, BBC Learning English, etc.) and a timeline of recent uploads to add to their practice library.

YouTube exposes public Atom RSS feeds per channel (`/feeds/videos.xml?channel_id=…`) without OAuth or Data API keys. Enjoy Player is local-first (Drift) and already imports YouTube rows via oEmbed + `videos` table.

## Decision

1. **Discover feature module** (`lib/features/discover/`) with a shell route `/discover`.
2. **Local-only subscriptions** stored in Drift (`youtube_channel_subscriptions`) — not synced to Enjoy cloud or YouTube accounts in v1.
3. **Feed cache** in Drift (`youtube_feed_entries`), separate from library `videos`; library rows created only on explicit **Add to library** via existing `importYoutubeVideo()`.
4. **RSS fetch on client** using `package:http`; parse Atom entries for video id, title, thumbnail, published date.
5. **Bundled recommended catalog** (`assets/discover/recommended_channels.json`) for editorial picks; users may also subscribe via pasted channel URL/handle (best-effort HTML resolution to `channel_id`).
6. **Refresh policy**: on app launch (debounced), pull-to-refresh, and every 8 hours while running; skip per-channel refresh if fetched within the last hour unless forced. The periodic timer is **gated on the subscription list being non-empty and the app being in the foreground** so empty installations do not wake the device and backgrounded apps do not silently refresh. RSS fetches and per-entry duration enrichment both run with a bounded concurrency cap (4 each) so a 20-channel refresh completes in ~5 round-trips rather than 20. Per-channel failures are returned in `DiscoverRefreshResult.failedChannelIds` and surfaced via a localized error notice, so a partial outage does not block the rest of the feed.
7. **Explicit subscribe** for recommended channels (no auto-subscribe on first visit).

## Consequences

- Cold-start users can browse in-app content without leaving Enjoy Player.
- RSS returns ~15 recent videos per channel; no duration or caption metadata in feed — duration filled on import/play as today.
- Channel handle resolution depends on YouTube HTML patterns; may break if YouTube changes markup — recommended catalog uses hard-coded `channel_id` values as fallback.
- Schema version bump adds tables; v6→v7 uses incremental migration (adds Discover tables only). Older upgrades still follow destructive `onUpgrade` until incremental migrations land.
- Cross-device subscription sync and Worker-proxied RSS are deferred.

## References

- Feature: `docs/features/discover.md`
- YouTube playback: ADR-0015, `docs/features/youtube.md`

## Implementation notes

- Refresh tunings (concurrency caps, lifecycle gating, avatar LRU)
  live as named constants in
  `lib/features/discover/data/discover_repository.dart`
  (`_kRefreshChannelConcurrency`, `_kEnrichDurationConcurrency`,
  `_kAvatarCacheCapacity`). Adjust there when raising the per-channel
  or per-entry parallelism budget.
