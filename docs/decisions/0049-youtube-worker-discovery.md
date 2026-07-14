# ADR-0049: YouTube Worker Discovery via RSSHub Proxy

**Date**: 2026-07-14  
**Status**: Accepted  
**Deciders**: Engineering team  

## Context

The Enjoy Player app previously performed YouTube channel/video discovery entirely on the client side using a dual-source pipeline:

1. **Primary**: InnerTube `browse` endpoint via `youtubei.googleapis.com` (anonymous, no API key)
2. **Fallback**: Public Atom RSS endpoint (`youtube.com/feeds/videos.xml?channel_id=...`)

Both sources were unreliable in practice:
- The Atom RSS endpoint frequently returns bot-block pages, consent-wall HTML, or empty payloads, causing refresh failures that were surfaced as generic errors to users.
- The InnerTube `browse` endpoint is an undocumented reverse-engineered surface that can change shape or return 401 without notice, requiring client-side profile rotation and response-shape drift handling.
- Client-side HTTP scraping (`YoutubeChannelResolver` for handle→ID resolution, `YoutubeVideoDuration` for watch-page HTML scraping) is fragile, rate-limit sensitive, and consumes user bandwidth on every refresh.

The decision was made to move YouTube discovery to a server-side worker, keeping only subscription management local to the client (local-first pattern).

## Decision

**Move YouTube video discovery to a server-side RSSHub proxy.** The client no longer makes direct YouTube HTTP requests. Instead:

1. The worker deploys an **RSSHub instance** (https://docs.rsshub.app/routes/youtube) serving the three standard RSSHub YouTube routes.
2. The client constructs feed URLs from user input (channel ID, @handle, playlist ID) and fetches them via simple HTTP GET.
3. RSSHub returns **JSON Feed v1.1** format (via `?format=json`), which the client parses and caches locally.
4. **Subscriptions remain client-side** — stored in Drift `youtube_channel_subscriptions`, synced across devices via existing cloud sync infrastructure (ADR-0010, ADR-0013).
5. The worker is **stateless with respect to user subscriptions** — it does not store per-user state or track which users follow which sources.

### Worker API Contract

Three GET endpoints, proxied from RSSHub:

| Endpoint | Example | Purpose |
|----------|---------|---------|
| `GET /youtube/channel/{channel_id}?format=json` | `/youtube/channel/UC...?format=json` | Channel feed |
| `GET /youtube/user/{handle}?format=json` | `/youtube/user/@TED?format=json` | Handle feed (resolves to channel) |
| `GET /youtube/playlist/{playlist_id}?format=json` | `/youtube/playlist/PL...?format=json` | Playlist feed |

Response: JSON Feed v1.1 (https://www.jsonfeed.org/version/1.1/)

## Consequences

### Positive

- **Eliminates client-side YouTube scraping completely.** No more InnerTube `browse`, Atom RSS, HTML scraping, or watch-page duration enrichment.
- **Improved reliability.** RSSHub handles YouTube API communication, rate limiting, and response-shape resilience server-side.
- **Simplified client architecture.** Replaces 5 data files (YoutubeBrowseClient, YoutubeRssParser, YoutubeChannelResolver, YoutubeFetch, YoutubeVideoDuration) + a legacy ID correction map (~1500 LOC) with 3 new files (YoutubeUrlParser, JsonFeedParser, WorkerFeedClient) (~400 LOC).
- **Adds playlist subscription support.** Previously deferred as out-of-scope, now a first-class source type alongside channels and handles.
- **Standard feed format.** JSON Feed v1.1 is a well-defined standard; no custom API schema needed.

### Negative

- **Worker dependency.** Feed fetching now depends on a server-side RSSHub proxy being available. The app handles offline gracefully (shows cached entries), but initial subscription requires worker connectivity for URL resolution.
- **RSSHub configuration.** The worker team needs to deploy and maintain an RSSHub instance with the YouTube routes enabled and a YouTube API key configured.
- **Fixed feed size.** RSSHub returns a fixed number of entries per feed (~15–50). Pagination support is deferred to a follow-up enhancement.
- **View count not available.** JSON Feed v1.1 does not expose view counts; RSSHub's YouTube implementation does not include them in the output. Previously available via InnerTube but not reliably.

### Migration

The legacy client-side discovery code is completely removed in this change. No dual-source fallback — the worker feed is the sole source. Existing cached feed entries in the local database remain visible offline.

## Rejected Alternatives

1. **Keep dual-source client-side pipeline.** Rejected — the core reason for this feature is the unreliability of client-side YouTube fetching. Adding more client profiles or response-shape handlers would only increase complexity without addressing the fundamental bot-block problem.

2. **Custom worker API (JSON RPC-style POST endpoints).** Rejected in favor of RSSHub's well-defined URL patterns. Using RSSHub standardizes the API and reduces worker implementation effort.

3. **Cloud-sync subscriptions through worker.** Rejected per user direction: "The subscription stays in client, the worker API just replace the client-side RSS fetching." Subscriptions remain local-first and sync via existing cloud sync infrastructure.

## References

- Spec: `specs/018-youtube-worker-discovery/spec.md`
- Plan: `specs/018-youtube-worker-discovery/plan.md`
- RSSHub YouTube routes: https://docs.rsshub.app/routes/youtube
- JSON Feed v1.1: https://www.jsonfeed.org/version/1.1/
- ADR-0010 Cloud sync MVP: `docs/decisions/0010-cloud-sync-mvp.md`
- ADR-0013 Local-first sync: `docs/decisions/0013-local-first-sync.md`
- ADR-0021 YouTube Discovery RSS: `docs/decisions/0021-youtube-discover-rss.md`
- ADR-0046 Append-only feed cache: `docs/decisions/0046-discover-feed-append-only.md`
