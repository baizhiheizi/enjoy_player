# Feature Specification: YouTube Worker Discovery

**Feature Branch**: `018-youtube-worker-discovery`

**Created**: 2026-07-14

**Status**: Draft

**Input**: User description: "The discovery of fetching YT videos from channel on the client side is buggy. Let's move it into the server side, use the worker to do the job. Let's redesign the discovery from zero, make YT channel/user and playlist subscribable, fetch from worker API. The subscription stays in client, the worker API just replace the client-side RSS fetching. The worker API would only provide the similar API like RSS, like `/youtube/user/@TED`, `/youtube/channel/:id`, `/youtube/playlist/:id`. The video entries live in local."

## Clarifications

### Session 2026-07-14

- Q: Where do subscriptions live — client-side or worker-side? → A: Subscriptions stay client-side (local-first). The worker API only replaces the client-side RSS/InnerTube fetching. The worker is a stateless video-fetch proxy; it does not store user subscription lists.
- Q: What API patterns does the worker expose? → A: RSS-like URL-path-based GET endpoints: `/youtube/user/@handle`, `/youtube/channel/:id`, `/youtube/playlist/:id`. The client constructs the URL from the parsed source type and canonical ID. Video entries live locally — the worker returns a feed, the client stores everything.
- Q: What backend does the worker use? → A: The worker proxies RSSHub (https://docs.rsshub.app/routes/youtube). The URL patterns and feed semantics follow RSSHub's YouTube routes.
- Q: What feed format does the client consume? → A: JSON (RSSHub supports JSON output via `?format=json` or Accept header). Structured JSON parsing is simpler than RSS XML and replaces the legacy `YoutubeRssParser`.
- Q: What is the exact JSON output format? → A: RSSHub outputs [JSON Feed v1.1](https://www.jsonfeed.org/version/1.1/). The top-level fields are `version`, `title`, `home_page_url`, `icon`, `items[]`. Items use `id`, `url`, `title`, `content_html`, `image`, `date_published`, `authors[]`, `attachments[]`. Duration lives in `attachments[].duration_in_seconds`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Subscribe to a YouTube source and browse recent uploads (Priority: P1)

A learner discovers a YouTube channel, user handle, or playlist they want to follow for language learning. They paste the YouTube URL (channel, @handle, or playlist) into the app's Discover screen. The app validates the URL locally, extracts the source type and canonical ID, creates a local subscription record, then fetches the corresponding worker feed URL (which proxies RSSHub). The JSON feed response contains source metadata (display name, avatar) and video entries with title, thumbnail, duration, and published date. The client stores these entries locally and renders them in the timeline. The learner can scroll the timeline, tap any video to play it, and trust that the feed will stay current without manual intervention.

**Why this priority**: This is the entire product surface. Moving to a server-side RSSHub proxy eliminates the primary reliability failure (client-side RSS bot-blocks and InnerTube shape drift) while keeping subscriptions local-first.

**Independent Test**: Using a stub worker that serves RSSHub-format JSON at `GET /youtube/channel/UC_test`, enter `https://youtube.com/channel/UC_test` on the Discover screen. Assert the local subscription is created from the feed's channel metadata, the timeline renders video entries from the feed, and pulling-to-refresh re-fetches the feed URL without error.

**Acceptance Scenarios**:

1. **Given** the Discover screen is empty (no subscriptions), **When** the user enters a valid `https://youtube.com/@LearningEnglish` URL and confirms, **Then** the app extracts the handle `@LearningEnglish`, fetches `GET /youtube/user/@LearningEnglish?format=json`, creates a local subscription (extracting display name from `title` and avatar from `icon`), stores the returned `items[]` locally, and renders them in the timeline.
2. **Given** the user enters a valid `https://youtube.com/playlist?list=PL...` URL, **When** they confirm, **Then** the app fetches `GET /youtube/playlist/PL...` (JSON), creates a local playlist subscription, and the playlist's videos are displayed in playlist order.
3. **Given** the user enters a vanity `/channel/UC...` URL, **When** they confirm, **Then** the app fetches `GET /youtube/channel/UC...` (JSON) directly — no URL resolution needed since the canonical ID is already in the URL.
4. **Given** the user enters an invalid or unsupported URL (e.g., a single video link, a non-YouTube domain), **When** they confirm, **Then** a localized validation error is shown inline and no subscription is created. No worker call is made.
5. **Given** the worker feed URL returns an error (e.g., 404 source not found, 410 source unavailable), **When** the user tries to subscribe, **Then** a localized error is shown and the subscription is not created.

---

### User Story 2 - Automatic background refresh keeps the feed current (Priority: P2)

The learner does not need to remember to refresh. Once per hour (cooldown-gated), the app re-fetches the worker feed URL for each locally-subscribed source. A pull-to-refresh gesture also triggers an immediate refresh, bypassing the cooldown. When new videos arrive, they appear at the top of the timeline without replacing or removing previously cached entries. If a source has no new videos, the feed simply stays as-is. The learner never sees a "fetch failed" notice caused by YouTube bot-blocking or response-shape changes — those problems are handled by the RSSHub proxy.

**Why this priority**: Automatic refresh is the "set and forget" promise. With server-side reliability via RSSHub, background refresh becomes the dependable default.

**Independent Test**: Seed a worker stub for `GET /youtube/channel/UC_test?format=json` with JSON Feed v1.1 output containing an initial video set, create a local subscription, then update the stub to return one additional video. Wait for the refresh timer (or fast-forward it in test), then assert the timeline contains all original videos plus the new one. Assert no HTTP requests were made directly to YouTube domains from the client.

**Acceptance Scenarios**:

1. **Given** the user has 3 active local subscriptions, **When** the periodic refresh timer fires (1 h after the last successful refresh), **Then** the app fetches each source's worker feed URL (JSON), appends any new video entries not already in the local cache, and updates the per-source `lastRefreshedAt` timestamp.
2. **Given** the user pulls to refresh on the Discover timeline, **When** the gesture completes, **Then** all sources are refreshed immediately (cooldown bypassed), the spinner dismisses when all feed fetches complete or fail, and any per-source failures are reported individually.
3. **Given** a worker feed URL returns an error for one source, **When** the refresh runs, **Then** only that source's `lastRefreshedAt` is left unchanged and the source is marked for retry on the next eligible tick; all other sources proceed normally.
4. **Given** the app is in the background, **When** the periodic refresh timer would have fired, **Then** the refresh is deferred until the next foreground event (no background fetch).

---

### User Story 3 - Manage subscriptions (list, unsubscribe, re-subscribe) (Priority: P3)

The learner builds a collection of YouTube sources over time and occasionally wants to clean up. They can view all their subscriptions in a management list, see when each was last refreshed, unsubscribe from sources they no longer need, and re-subscribe later using the same URL. All subscription management happens locally — the worker is not involved. Unsubscribing removes the source from the local list and hides its videos from the timeline. Re-subscribing recreates the local record and immediately fetches the feed.

**Why this priority**: Subscription management is table-stakes UX. Since subscriptions are local-only, it is simpler than a distributed state model.

**Independent Test**: With two local subscriptions in the test database, open the subscription management screen, unsubscribe from one, and assert that source's videos are removed from the timeline. Re-subscribe using the same URL (re-fetching the feed), assert the source reappears with freshly stored videos.

**Acceptance Scenarios**:

1. **Given** the user is viewing the Discover screen, **When** they navigate to subscription management, **Then** they see a list of all locally-subscribed sources with name, avatar, source type (channel/user/playlist), and last-refreshed timestamp — all read from the local database.
2. **Given** the user unsubscribes from a source, **When** they confirm, **Then** the source is removed from the local subscription list and its cached videos are removed from the timeline. No worker call is made.
3. **Given** the user re-subscribes to a previously unsubscribed source, **When** they enter the same URL, **Then** the feed is re-fetched, a new local subscription is created from the feed metadata, and the timeline is populated.

---

### User Story 4 - Multi-device subscription sync via cloud account (Priority: P4)

The learner uses Enjoy Player on both their desktop and mobile device, signed into the same account. When they subscribe to a YouTube channel on their desktop, the subscription record syncs to their mobile device via the existing cloud sync infrastructure (ADR-0010, ADR-0013). The worker is not involved in subscription sync; it remains a stateless feed provider. Video entries are fetched independently on each device from the worker feed after the local subscription appears via sync.

**Why this priority**: Cross-device sync leverages existing infrastructure and is not dependent on new worker capabilities. It amplifies value but is not required for single-device use.

**Independent Test**: With two test clients signed into the same account, add a subscription locally on client A. After a cloud sync interval, assert client B's local subscription list includes the new source. Trigger a refresh on client B, assert feed is fetched from the worker URL and video entries are stored locally. Unsubscribe on client B, sync, assert the source is gone on client A.

**Acceptance Scenarios**:

1. **Given** the user is signed in on two devices, **When** they subscribe to a source on device A and cloud sync propagates to device B, **Then** the subscription appears on device B's local list and the timeline populates after a worker feed fetch.
2. **Given** a subscription exists only in the cloud sync state (e.g., after a reinstall), **When** the user signs in and opens Discover, **Then** the subscription list is restored from cloud sync and all sources are refreshed from their worker feed URLs.
3. **Given** the user is not signed in (offline/guest mode), **When** they subscribe on a single device, **Then** the subscription is stored locally and syncs to other devices when the user signs in via existing cloud sync mechanisms.

---

### Edge Cases

- **Duplicate subscriptions**: What happens when a user subscribes to the same channel via both its @handle URL and its `/channel/UC...` URL? The app MUST normalize to a canonical source identifier (channel ID from `home_page_url` for handles, URL path for direct channel IDs, or playlist ID from request path) and MUST reject duplicate subscriptions by canonical ID with a localized message.
- **Handle-to-ID resolution**: When a user enters `https://youtube.com/@Handle`, the app fetches `GET /youtube/user/@Handle?format=json`. The feed's `home_page_url` contains the canonical channel URL (e.g., `https://www.youtube.com/channel/UC...`). The app MUST extract the canonical channel ID from this URL and use it for deduplication and for `/youtube/channel/{id}` on all subsequent refreshes.
- **Very large feeds**: RSSHub returns a fixed number of entries per feed (~15–50). If this proves insufficient for fast-publishing channels or large playlists, RSSHub supports pagination parameters. Pagination support is deferred to a follow-up enhancement.
- **Deleted or private sources**: What happens when a subscribed YouTube channel is terminated or made private? The RSSHub proxy returns an HTTP 404 or 410. The client marks the source as "unavailable" with a localized notice, keeps the existing cached videos visible, and disables further automatic refreshes until the user manually unsubscribes.
- **Rate limiting**: What happens when the worker is rate-limited? The client backs off exponentially per source and surfaces a "try again later" notice after a configurable number of retries.
- **Offline use**: What happens when the user opens Discover with no network? The app displays the cached timeline from the last successful refresh with a "last updated [timestamp]" header. Subscription management operates on the local database without network access; feed refresh skips until connectivity returns.
- **Network-constrained environments**: What happens on metered or slow connections? The client MUST respect the platform's connectivity awareness (no forced background fetches on metered connections) and MUST use thumbnail dimensions appropriate to the display density.
- **Worker returns stale/incomplete data**: What happens when the RSSHub proxy's upstream is delayed and returns entries older than the client's cache? The client MUST use video ID deduplication — if all returned entries are already cached, no changes are made and `lastRefreshedAt` is still updated.
- **Playlist reordering**: What happens when a playlist owner reorders videos? On the next client feed fetch, the RSSHub proxy returns the current playlist order. The client appends new entries not already cached and respects the new playlist order for display.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The client MUST allow users to subscribe to three YouTube source types: channels (via `/channel/UC...` URL), users/handles (via `/@handle` URL), and playlists (via `/playlist?list=PL...` URL).
- **FR-002**: The client MUST validate submitted URLs locally as belonging to one of the three supported YouTube source types; unsupported URLs (single video, non-YouTube domains) MUST be rejected with a localized error before any worker call is made.
- **FR-003**: The client MUST extract the source type and identifier from the user's URL and construct a worker feed URL corresponding to RSSHub's YouTube routes:
  - `GET /youtube/channel/{channel_id}` for `/channel/UC...` URLs
  - `GET /youtube/user/{handle}` for `/@handle` URLs (e.g., `/youtube/user/@TED`)
  - `GET /youtube/playlist/{playlist_id}` for `/playlist?list=PL...` URLs (e.g., `/youtube/playlist/PL...`)
- **FR-004**: The client MUST request JSON format from the worker feed via `?format=json` query parameter, per RSSHub's API conventions. The response is [JSON Feed v1.1](https://www.jsonfeed.org/version/1.1/).
- **FR-005**: The worker (RSSHub proxy) MUST serve YouTube feeds at the three RSSHub URL patterns: `GET /youtube/channel/:id`, `GET /youtube/user/:handle`, `GET /youtube/playlist/:id`.
- **FR-006**: Each JSON feed response follows the [JSON Feed v1.1](https://www.jsonfeed.org/version/1.1/) format. Feed-level fields include `title` (channel/playlist display name), `home_page_url` (source URL), and `icon` (avatar URL). The `items[]` array contains video entries, each with: `id` (video ID), `url` (YouTube watch URL), `title`, `image` (thumbnail URL), `date_published` (ISO 8601), `authors[]` (array of `{name}`), and `attachments[]` (array with `duration_in_seconds`).
- **FR-007**: The client MUST extract the canonical source ID from the feed response. For `/youtube/channel/{id}`, the ID is the URL path parameter. For `/youtube/user/{handle}`, the client MUST parse the `home_page_url` or item `url` fields to derive the canonical channel ID (e.g., extracting `UC...` from `https://www.youtube.com/channel/UC...` in `home_page_url`). The client MUST use the canonical channel ID for deduplication and switch to `/youtube/channel/{id}` for all subsequent refreshes.
- **FR-008**: The client MUST cache fetched video entries locally, append new entries to the existing cache (append-only by video ID), and never remove cached entries unless the user unsubscribes from the source.
- **FR-009**: The client MUST implement a 1-hour per-source refresh cooldown for automatic background refreshes; pull-to-refresh MUST bypass the cooldown.
- **FR-010**: The client MUST deduplicate video entries by video ID — if the feed returns videos already in local cache, they are skipped (no duplicate rows).
- **FR-011**: The client MUST NOT trigger background refreshes while the app is in the background state; refreshes MUST be deferred to the next foreground event.
- **FR-012**: All logging on the client side MUST use the project's `logNamed` / `package:logging` pattern; the new code MUST NOT introduce `print()` calls.
- **FR-013**: The client MUST NOT make any direct HTTP requests to YouTube domains (`youtube.com`, `youtubei.googleapis.com`) for discovery or video metadata purposes. All discovery HTTP requests go through the worker (RSSHub proxy).
- **FR-014**: An `ADR-0051-youtube-worker-discovery.md` MUST be created under `docs/decisions/` documenting the decision to move YouTube video discovery to a server-side RSSHub proxy, the three RSSHub YouTube feed routes, and the local-first subscription model.
- **FR-015**: `docs/features/discover.md` MUST be updated to describe the new server-side RSSHub proxy architecture, the three subscribable source types, and the local-first subscription model.
- **FR-016**: Multi-device subscription sync MUST use the existing cloud sync infrastructure (ADR-0010, ADR-0013). The worker is NOT involved in subscription synchronization between devices.

### Worker API Specification *(detailed)*

The worker is an **RSSHub proxy** providing standard RSSHub YouTube routes. It does not store user subscriptions, maintain per-user state, or track which sources each user follows. The canonical API reference is https://docs.rsshub.app/routes/youtube.

The client requests JSON output from the RSSHub proxy. The worker exposes three GET endpoints:

#### `GET /youtube/channel/{channel_id}`

Channel feed by canonical channel ID (e.g., `/youtube/channel/UC...`). Returns recent uploads in reverse-chronological order.

#### `GET /youtube/user/{handle}`

User/handle feed (e.g., `/youtube/user/@TED`). RSSHub resolves the handle to the underlying channel. The response's `source.id` contains the canonical channel ID.

#### `GET /youtube/playlist/{playlist_id}`

Playlist feed by playlist ID (e.g., `/youtube/playlist/PL...`). Returns videos in playlist order.

---

**JSON response format** — RSSHub outputs [JSON Feed v1.1](https://www.jsonfeed.org/version/1.1/). All three endpoints share this structure:

```json
{
  "version": "https://jsonfeed.org/version/1.1",
  "title": "Channel Display Name - YouTube",
  "home_page_url": "https://www.youtube.com/channel/UC...",
  "icon": "https://yt3.ggpht.com/...",
  "description": "YouTube channel Channel Display Name - Powered by RSSHub",
  "items": [
    {
      "id": "dQw4w9WgXcQ",
      "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      "title": "Video Title",
      "content_html": "<p>Video description text...</p>",
      "image": "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg",
      "date_published": "2026-07-10T08:00:00.000Z",
      "authors": [
        { "name": "Channel Display Name" }
      ],
      "attachments": [
        {
          "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
          "mime_type": "text/html",
          "duration_in_seconds": 212
        }
      ]
    }
  ]
}
```

**Error responses**:
- `404` — source not found (invalid handle, channel ID, or playlist ID)
- `410` — source unavailable (deleted, private, or terminated on YouTube)
- `429` — rate limited
- `502` — YouTube upstream failure (RSSHub could not reach YouTube)

**Notes**:
- The client requests JSON via `?format=json` query parameter, per RSSHub's API conventions.
- `title` contains the channel/playlist display name suffixed with ` - YouTube`. The client strips this suffix and uses it for local subscription display name.
- `home_page_url` is the YouTube source URL. For channel feeds it contains `https://www.youtube.com/channel/UC...`; the client extracts the canonical channel ID from this path.
- `icon` is the channel/playlist avatar. The client stores this as the subscription avatar URL.
- `items[].id` is the YouTube video ID — used for client-side deduplication.
- `items[].attachments[0].duration_in_seconds` is the video duration in seconds. Omitted if unavailable.
- When a user subscribes via handle (`/youtube/user/@Handle`), the client MUST extract the canonical channel ID from the feed's `home_page_url` (or construct it from item IDs), then use `/youtube/channel/{id}` for all subsequent refreshes.
- For channel/user feeds, `items[]` are ordered reverse-chronologically (newest first). For playlist feeds, items are in playlist order.
- The feed returns a fixed set of the most recent items (RSSHub default: ~15–50). Pagination parameters are available via RSSHub but deferred to a follow-up enhancement.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST live under `lib/features/discover/` and reuse existing architectural patterns (feature-first layout, Riverpod providers, Drift DAOs). No new global singletons or cross-feature shortcuts.
- **QR-002**: The change MUST include automated tests covering: (a) URL parsing and validation for all three source types, (b) worker feed URL construction from parsed source type + ID, (c) JSON feed response parsing and local storage of entries, (d) canonical ID extraction from handle feeds and URL migration, (e) append-only cache behavior with deduplication, (f) refresh cooldown enforcement, (g) error state rendering for each HTTP error code, (h) offline/local-only subscription management.
- **QR-003**: User-facing strings MUST be added to ARB localization files. New strings include: URL validation errors, subscription duplicate notice, source-unavailable notice, retry prompts, and "last updated" timestamp formatting.
- **QR-004**: The merged Discover timeline MUST remain responsive (no jank on scroll) with up to 500 cached entries per source and up to 20 active subscriptions, reusing or adapting the existing `ValueKey` + `findChildIndexCallback` sliver pattern.
- **QR-005**: Video metadata from the worker JSON feed MUST be persisted to the local database for offline access; thumbnail images MUST be cached using the existing image caching strategy.
- **QR-006**: The existing `YoutubeChannelResolver`, `YoutubeRssParser`, and InnerTube browse client (`YoutubeBrowseClient`) code paths MUST be deprecated and eventually removed, with a clear migration path for any cached data from the legacy system.

---

### Key Entities *(include if feature involves data)*

- **Subscription** (local): Represents a user's subscription to a YouTube source, stored locally. Attributes: local ID, source type (channel/playlist), canonical source ID (extracted from feed URL path or `home_page_url`), display name (from feed `title`), avatar URL (from feed `icon`), worker feed URL, status (active/unavailable), created timestamp, last-refreshed timestamp.
- **FeedEntry (Video)** (local): A video entry from a JSON Feed response, stored locally. Attributes: video ID (from `items[].id`), subscription local ID (foreign key), title (from `items[].title`), thumbnail URL (from `items[].image`), duration (from `items[].attachments[].duration_in_seconds`), published timestamp (from `items[].date_published`), YouTube watch URL (from `items[].url`). Note: view count is not available in RSSHub's JSON Feed output.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can subscribe to a YouTube source and see video entries within 5 seconds of confirming the URL (on a typical broadband connection), with the worker feed responding in under 2 seconds.
- **SC-002**: 100% of video discovery HTTP requests go to the worker (RSSHub proxy), not to YouTube domains directly (zero `youtube.com`/`youtubei.googleapis.com` outbound requests from the client for discovery).
- **SC-003**: The Discover timeline remains scrollable at 60 fps with up to 20 active subscriptions and 500 cached entries per source on a reference device (mid-range Android/iOS from 2023 or later).
- **SC-004**: Automatic background refresh succeeds for ≥95% of subscribed sources per tick under normal RSSHub availability, compared to the current client-side approach where RSS bot-blocking causes frequent failures.
- **SC-005**: When the worker is unreachable, cached video entries remain fully browsable offline, and the local subscription list is fully manageable without network access.
- **SC-006**: Users with the same account on two devices see subscription changes propagate between devices within the existing cloud sync latency window (per ADR-0010/ADR-0013), and each device fetches feeds independently from the worker.
- **SC-007**: Automated tests cover: all three feed URL patterns, all HTTP error codes, handle-to-ID canonicalization via `home_page_url` parsing, JSON Feed v1.1 parsing, deduplication by `items[].id`, and cooldown enforcement.

## Assumptions

- A server-side worker (`baizhiheizi/enjoy` repo) will be deployed as an RSSHub proxy, serving the standard RSSHub YouTube routes. The canonical API reference is https://docs.rsshub.app/routes/youtube.
- RSSHub handles all YouTube API communication, rate limiting, and response-shape resilience — concerns that previously lived client-side.
- The worker may optionally add authentication, rate limiting, or caching on top of RSSHub, but these are deployment details transparent to the client contract.
- The worker authenticates client requests using the existing Enjoy account system (same auth tokens already used for cloud sync). Authentication is for abuse prevention; the worker does not use user identity for subscription management.
- The existing Drift database schema for `youtube_feed_entries` and `youtube_channel_subscriptions` will be adapted or replaced as needed. A schema migration is acceptable since the discovery system is being redesigned from zero.
- The legacy client-side discovery code (`YoutubeChannelResolver`, `YoutubeRssParser`, InnerTube browse client from the 017 feature) will be deprecated and removed in a follow-up cleanup after the worker-based system is stable.
- Multi-device subscription sync uses the existing cloud sync infrastructure (ADR-0010, ADR-0013). No new sync mechanism is introduced.
- Playlist video ordering is playlist-defined (not reverse-chronological). The client timeline preserves playlist order for playlist sources.
- Thumbnail dimensions and image caching follow existing app patterns; no new image pipeline is introduced.
- The client refresh cooldown (1 hour) applies per-source and is identical to the contract established in ADR-0021. The worker has no cooldown concept — it fetches on demand per request.
- The feed returns a fixed set of most recent entries (RSSHub default). If pagination becomes necessary (large playlists, fast-publishing channels), it will be added as a follow-up enhancement using RSSHub's pagination parameters.
- Initial release scope is single-user subscriptions managed per-device. Shared/family subscription lists and collaborative feeds are out of scope.
- YouTube Shorts, live streams, and membership-only videos: RSSHub returns whatever YouTube makes available. The client does not filter by video type.

## Out of Scope

- Worker-side subscription management. Subscriptions are local-first, managed by the client, and synced across devices via existing cloud sync — not via worker endpoints.
- Worker-side per-user state of any kind. The RSSHub proxy has no knowledge of which users follow which sources.
- Playlist creation, editing, or collaborative curation.
- Fetching single video metadata (not a source). The feed endpoints work on sources, not individual video IDs.
- Feed pagination and `since`-based incremental refresh (fixed-size feed only for initial release).
