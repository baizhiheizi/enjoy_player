# Research: YouTube Worker Discovery

**Feature**: 018-youtube-worker-discovery  
**Date**: 2026-07-14

## R1: RSSHub JSON Feed v1.1 Output Shape

**Decision**: Parse JSON Feed v1.1 as the sole response format from the worker RSSHub proxy.

**Rationale**: RSSHub's JSON output (via `?format=json`) follows the [JSON Feed v1.1 spec](https://www.jsonfeed.org/version/1.1/). The actual output shape was confirmed from RSSHub source code (`lib/views/json.ts`). Fields map as:

| JSON Feed field | Client use | RSSHub source |
|---|---|---|
| `title` | Subscription display name (strip ` - YouTube` suffix) | `data.title` |
| `home_page_url` | Canonical channel URL → extract channel ID | `data.link` |
| `icon` | Subscription avatar URL | `data.image` |
| `items[].id` | Video ID (deduplication key) | `item.link` (YouTube video URL → extract ID) or `item.guid` |
| `items[].url` | YouTube watch URL | `item.link` |
| `items[].title` | Video title | `item.title` |
| `items[].image` | Thumbnail URL | `item.image` or `item.itunes_item_image` |
| `items[].date_published` | Published timestamp (ISO 8601) | `item.pubDate` |
| `items[].authors[].name` | Channel author name | `item.author` |
| `items[].attachments[].duration_in_seconds` | Video duration (seconds) | `item.attachments[].duration_in_seconds` |
| `items[].content_html` | Video description HTML | `item.description` (if HTML) |

**Alternatives considered**: Custom JSON format — rejected because RSSHub already defines the JSON Feed format; no need to define a custom schema when the proxy provides a standard one.

**Note on `id` field**: The RSSHub YouTube route sets `item.link = "https://www.youtube.com/watch?v=<videoId>"` (from `lib/routes/youtube/utils.ts`). The JSON view maps this to `items[].id` via `item.guid || item.id || item.link`. So `items[].id` will be the YouTube watch URL. The client MUST extract the video ID from this URL using a regex: `v=([a-zA-Z0-9_-]{11})`.

**Note on `icon`**: RSSHub sets `image` from `data.image` for channel feeds and `playlistTitle.channelImage` for playlists. This maps to the JSON Feed `icon` field. Not all feeds may populate this — the client must handle missing `icon` gracefully (default avatar fallback already exists in `DiscoverChannelAvatar`).

## R2: Worker Base URL Configuration

**Decision**: Reuse the existing `aiApiBaseUrl` → `https://worker.enjoy.bot` for the RSSHub proxy. Configure a path suffix `/youtube` so the full feed URL is `{workerBaseUrl}/youtube/channel/{id}?format=json`.

**Rationale**: The worker is deployed alongside the existing Enjoy worker at `worker.enjoy.bot`. The existing `aiApiClientProvider` already provides an `ApiClient` pointed at the worker base URL. However, the current feed endpoints don't need bearer auth (they're public RSSHub routes proxied through the worker). A new lightweight HTTP client (using `package:http` directly) is simpler than reusing `ApiClient` with all its JSON response conventions.

Alternative considered: Reuse `ApiClient` from `api_client.dart` — rejected because the RSSHub proxy returns JSON Feed (not the Rails-style snake_case JSON `ApiClient` expects), and feed requests may not always need auth tokens (public route proxy). A dedicated feed client (`YoutubeFeedClient`, originally `WorkerFeedClient`) with `package:http` is more maintainable.

**Configuration**:
```dart
// lib/features/discover/data/worker_feed_client.dart
static const _kDefaultWorkerBaseUrl = 'https://worker.enjoy.bot';
final _workerBaseUrlProvider = Provider<String>((ref) => _kDefaultWorkerBaseUrl);
```

## R3: URL Parsing and Canonical ID Extraction

**Decision**: Implement a pure `YoutubeUrlParser` class that takes a raw user input string and returns a `ParsedYoutubeUrl` with source type + canonical ID.

**Rationale**: The current `YoutubeChannelResolver` does HTML-scraping to resolve handles → channel IDs. With the worker RSSHub proxy, handle resolution happens server-side — the client just constructs the correct feed URL. URL validation and canonical ID extraction must be fast (no network) and comprehensive.

**Input formats supported**:

| Input | Source type | Extracted ID | Worker URL |
|---|---|---|---|
| `https://youtube.com/@Handle` | `user` | `@Handle` | `/youtube/user/@Handle?format=json` |
| `https://youtube.com/channel/UC...` | `channel` | `UC...` | `/youtube/channel/UC...?format=json` |
| `https://youtube.com/playlist?list=PL...` | `playlist` | `PL...` | `/youtube/playlist/PL...?format=json` |
| `@Handle` | `user` | `@Handle` | `/youtube/user/@Handle?format=json` |
| `UC...` (raw channel ID) | `channel` | `UC...` | `/youtube/channel/UC...?format=json` |
| `PL...` (raw playlist ID) | `playlist` | `PL...` | `/youtube/playlist/PL...?format=json` |

**Regex patterns**:
- Channel ID: `^UC[a-zA-Z0-9_-]{22}$`
- Playlist ID: `^PL[a-zA-Z0-9_-]{16,}$` (also `OL`, `FL`, `RD`, `UL` prefixes)
- Handle: `^@[a-zA-Z0-9_.-]+$`
- URL extraction: parse with `Uri.parse()`, extract path/host/query params

**Alternatives considered**: Keep using `YoutubeChannelResolver` and add query-param scraping — rejected because HTML scraping is the exact problem being eliminated by the server-side approach. Pure string parsing is simpler and never fails.

## R4: Drift Schema Migration

**Decision**: Add new columns to `youtube_channel_subscriptions` table via an incremental Drift migration.

**New columns for `youtube_channel_subscriptions`**:
- `source_type` TEXT NOT NULL DEFAULT 'channel' — enum: `channel`, `playlist`
- `feed_url` TEXT — the constructed worker feed URL (e.g., `https://worker.enjoy.bot/youtube/channel/UC...?format=json`)

**Schema migration strategy**:
1. Bump schema version from current to next
2. Add columns via `ALTER TABLE youtube_channel_subscriptions ADD COLUMN ...`
3. Backfill `feed_url` for existing subscriptions using `channelId` + default worker base URL
4. Existing `source` column renamed or kept — `recommended`/`user` describes how the sub was added, `source_type` describes what it is (channel/playlist)

**`youtube_feed_entries` table**: No schema changes needed. Existing columns (`videoId`, `channelId`, `title`, `thumbnailUrl`, `durationSeconds`, `publishedAt`, `fetchedAt`) fully cover JSON Feed fields. `durationSeconds` already nullable.

**`YoutubeSubscriptionSource` enum**: Keep existing. Add `YoutubeSourceType` enum separately for `channel`/`playlist`.

**Alternatives considered**: Create entirely new tables — rejected because it would lose existing subscription data and require a complex migration. Altering existing tables is simpler and preserves user data.

## R5: Handle-to-ID Canonicalization

**Decision**: When subscribing via `/youtube/user/@Handle`, the worker returns a JSON Feed response where `home_page_url` is `https://www.youtube.com/channel/UC...`. The client extracts the channel ID from `home_page_url`, stores it as the canonical ID, and constructs the canonical feed URL (`/youtube/channel/UC...`). All subsequent refreshes use the channel feed URL.

**Rationale**: This prevents duplicate subscriptions when a user subscribes via both `@Handle` and `UC...` URLs, and avoids redundant handle resolution on every refresh. The canonical ID is the channel ID (or playlist ID). Handles are an input alias, not a persistent identifier.

**Implementation**:
```dart
String? extractChannelIdFromUrl(String homePageUrl) {
  final match = RegExp(r'youtube\.com/channel/(UC[a-zA-Z0-9_-]{22})').firstMatch(homePageUrl);
  return match?.group(1);
}
```

**Test**: Subscribing via `@TED` → response `home_page_url = "https://www.youtube.com/channel/UCAuUUnT6oDeKwE6v1NGQxug" → canonical ID `UCAuUUnT6oDeKwE6v1NGQxug` → feed URL becomes `/youtube/channel/UCAuUUnT6oDeKwE6v1NGQxug?format=json`.

## R6: Error Handling Strategy

**Decision**: Map worker HTTP status codes to user-facing localized errors using a dedicated exception class.

**Error mapping**:

| HTTP Status | Exception type | User message |
|---|---|---|
| 200 | — | Success |
| 404 | `WorkerFeedException.notFound` | "This source could not be found." |
| 410 | `WorkerFeedException.sourceUnavailable` | "This source is no longer available." |
| 429 | `WorkerFeedException.rateLimited` | "Too many requests. Try again later." |
| 502 | `WorkerFeedException.upstreamFailure` | "Could not reach YouTube. Try again later." |
| Other 4xx/5xx | `WorkerFeedException.httpError` | "Something went wrong. Try again." |
| Network error | `WorkerFeedException.networkError` | "No internet connection." |
| Parse error | `WorkerFeedException.parseError` | "Could not parse the feed. The worker might be experiencing issues." |

**Rationale**: The existing `DiscoverRefreshResult.failedChannelIds` pattern is preserved — errors are per-source, not global. The `WorkerFeedException` carries the channel/playlist ID so the refresh loop can report which source failed.

## R7: Cloud Sync Integration for Subscriptions

**Decision**: YouTube channel/playlist subscriptions are INCLUDED in the existing sync queue, synced with entity type `youtube_subscription`. This enables multi-device subscription sync (User Story 4).

**Rationale**: The existing cloud sync infrastructure (ADR-0010/ADR-0013) already syncs library items. Extending it to include YouTube subscriptions requires:
1. Adding `youtube_subscription` to `SyncEntityType` enum
2. Serializing subscription rows as JSON payloads in the sync queue
3. On sync pull, upserting subscriptions from sync payloads

This is additive and follows the existing pattern. Subscriptions use the canonical source ID as the entity ID for deduplication.

**Alternatives considered**: New custom sync endpoint — rejected because the existing sync queue handles this cleanly.

## R8: Concurrency and Cooldown Preservation

**Decision**: Preserve the exact same concurrency caps and cooldown contracts from ADR-0021.

**Preserved constants**:
- `_kRefreshChannelConcurrency = 4` — max parallel worker feed fetches
- `minRefreshInterval = Duration(hours: 1)` — per-channel cooldown
- `_kPeriodicRefreshInterval = Duration(hours: 8)` — background timer (if kept, or reduced to 1h)

**Change**: The periodic timer interval can be reduced from 8h to 1h (or removed entirely in favor of pull-to-refresh + app-launch refresh) since worker feed fetches are cheap (simple GET, no multi-phase pipeline). The 1h per-channel cooldown is sufficient for freshness.

**Note**: `_kEnrichDurationConcurrency = 4` is REMOVED — no more HTML watch-page duration enrichment. Duration comes from the JSON Feed `attachments[].duration_in_seconds` and is persisted on upsert.
