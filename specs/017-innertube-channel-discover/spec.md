# Feature Specification: InnerTube Channel Discover

**Feature Branch**: `017-innertube-channel-discover`

**Created**: 2026-07-13

**Status**: Draft

**Input**: User description: "Let's make it happen. Make the playlist as follow-up."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Channel refreshes succeed when the public RSS source is blocked (Priority: P1)

A learner subscribes to several YouTube channels and leaves the Discover screen open throughout the day. Behind the scenes, Enjoy Player refreshes each channel's latest uploads on launch, on pull-to-refresh, and on an 8 h lifecycle-gated timer. Today the refresh routinely fails because the public Atom RSS endpoint returns a bot-block / consent page instead of an Atom payload; the failure is surfaced to the user as a generic error notice and the channel feed does not update. After this change, refreshes succeed under the same conditions for the majority of subscribed channels, and only fall back to the legacy source when the new path itself fails. From the user's point of view, the Discover feed simply keeps working without "RSS unavailable" errors most of the time, and individual channels that fail both paths still report failure for that channel only — not for the whole refresh.

**Why this priority**: This is the core motivation. The current behavior undermines the entire Discover feature: the user cannot rely on the channel feed updating, and the error noise erodes trust. Until refresh reliability is restored, no other Discover improvement lands on a stable foundation.

**Independent Test**: With a stubbed primary source that returns a valid browse response for the test channel, run `refreshFeeds()` against two channels: one whose primary response is valid (success path), one whose primary response is a 401 (fallback path) and whose fallback source returns a valid RSS payload. After the refresh: the success-path channel's cache has new entries from the primary source, the fallback-path channel's cache has new entries from the legacy RSS source, and `DiscoverRefreshResult.failedChannelIds` is empty (both succeeded via either path). Repeat the test with both sources failing — assert the channel id is reported in `failedChannelIds` and the cache is left untouched.

**Acceptance Scenarios**:

1. **Given** a user is subscribed to 10 channels, **When** a refresh tick runs against a primary source that returns valid data for all 10 channels, **Then** all 10 channels receive new entries (or upserts of seen entries), `failedChannelIds` is empty, and `lastFetchedAt` advances for all 10 channels.
2. **Given** the primary source returns an HTTP 401 for one channel and valid data for the other nine, **When** the refresh tick runs, **Then** the failed channel falls back to the legacy source for that tick, the legacy source's payload is written to its cache, and the other nine channels are unaffected by the fallback attempt.
3. **Given** both the primary source and the legacy source fail for a channel (401 + bot-block HTML), **When** the refresh tick runs, **Then** that channel id appears in `failedChannelIds`, its cache is unchanged, and its `lastFetchedAt` is not updated (the 1 h cooldown still applies to failures).
4. **Given** the user is on the Discover screen, **When** a partial-failure refresh tick completes, **Then** the per-channel refresh notice shown in the UI lists exactly the channel ids that failed (not the whole batch) and uses the existing localized error string.

---

### User Story 2 - Channel uploads include richer per-video metadata without a second HTTP round-trip (Priority: P2)

Today the Discover timeline shows a video title, channel name, thumbnail, and published date. After the channel refreshes, the player eventually learns the duration when the user opens the video, because the existing per-entry duration enrichment fetches the watch-page HTML. After this change, the Discover timeline surfaces the video's duration and view count directly when the channel refreshes, without a separate watch-page fetch. From the user's point of view, the channel feed shows richer information sooner (no "duration unknown" state, no second round-trip per video) and the app performs fewer background HTTP requests overall.

**Why this priority**: Removing the watch-page HTML scrape is a side effect of the primary-source swap, not a goal in itself. It is included because the new primary source returns the data in the same payload, and continuing to scrape the watch page for data that is already in hand is wasteful. Without this, the swap would carry a redundant request surface for no benefit.

**Independent Test**: With a primary source that returns one browse page containing 30 videos with `lengthText` / `viewCountText` fields populated, run `refreshFeeds()` for one channel that is empty and asserts that all 30 cache rows carry a non-null duration and view count, and that **no** HTTP request was made to `youtube.com/watch?v=…` during the refresh. Then repeat with the primary source returning entries that omit `lengthText`; assert the rows are still cached with whatever metadata the source returned (duration may be absent) and the watch-page scrape is **not** invoked.

**Acceptance Scenarios**:

1. **Given** a channel with no cached entries, **When** the primary source returns a page of 30 videos with `lengthText` populated, **Then** all 30 cache rows have a non-null duration and the refresh makes zero requests to `youtube.com/watch?v=…`.
2. **Given** the primary source returns entries that omit `lengthText` / `viewCountText` (render shape varies), **When** the refresh runs, **Then** the cache rows are still written with whatever metadata the source returned and no fallback watch-page fetch is issued for those entries.
3. **Given** the primary source is unavailable and the legacy source is used, **When** the legacy refresh runs, **Then** the legacy watch-page duration enrichment path is still used (existing behavior) so the fallback path continues to surface durations even though the primary path does not.

---

### User Story 3 - Refresh contract and the append-only cache are preserved (Priority: P3)

The public refresh contract from ADR-0021 and the append-only cache contract from ADR-0046 do not change. The 1 h per-channel cooldown still applies (failed or not), the 8 h periodic timer is still gated on the subscription list being non-empty and the app being in the foreground, the 4-way concurrency cap still bounds simultaneous channel fetches, and the cache is still append-only between unsubscribe events. The new path participates in the same client-profile rotation pipeline already in use by the YouTube caption fetcher, so a profile that YouTube has begun to throttle rotates to a fallback profile within a refresh tick rather than blocking all channels.

**Why this priority**: All of this is contract preservation, not a new feature. It is called out explicitly because it is the easiest thing to regress when changing the underlying data source, and the spec must hold the implementation to the existing behavior even when the path is new.

**Independent Test**: With both stubbed sources enabled, run two consecutive `refreshFeeds()` calls on the same channel inside the 1 h cooldown window. Assert the second call skips the channel entirely (cooldown honored). Then simulate a profile exhaustion: the primary source returns a 401 across all available client profiles for one channel. Assert the channel falls back to the legacy source for that tick, and the rotation logic does not retry the same profile twice within the tick.

**Acceptance Scenarios**:

1. **Given** a channel was fetched successfully 30 minutes ago, **When** a periodic refresh tick runs, **Then** the channel is skipped regardless of which source would otherwise serve it, and no row writes occur for that channel during the tick.
2. **Given** the primary source is configured with multiple client profiles, **When** a refresh tick encounters a profile that YouTube has begun to throttle, **Then** the per-channel request retries with the next available profile before falling back to the legacy source (no manual intervention needed).
3. **Given** a channel is eligible for refresh and the primary source returns a subset of the cached video ids, **When** the refresh completes, **Then** the cache size is preserved for entries that the primary source did not return (append-only behavior is unaffected by the source swap).
4. **Given** a refresh tick fails for a channel on both sources, **When** the next eligible refresh tick arrives, **Then** the channel is retried, its `lastFetchedAt` is still the time of its last successful refresh, and the cache has not been touched.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Discover channel refresh MUST attempt the InnerTube `browse` endpoint as the primary source for each subscribed channel, using the existing anonymous `youtubei.googleapis.com` surface and a configurable client profile (default: `WEB`).
- **FR-002**: When the InnerTube `browse` response is missing or unparseable (no `richItemRenderer` / `videoRenderer` chain, or no recognized continuation token), or returns an HTTP 401/403/5xx across all available client profiles, the refresh MUST fall back to the legacy Atom RSS path for that channel for that tick.
- **FR-003**: When the legacy RSS fallback is used, the existing 1 h cooldown, append-only cache, and 4-way concurrency cap MUST behave exactly as they do today.
- **FR-004**: The new InnerTube path MUST honor the same 1 h cooldown contract: failed InnerTube attempts that fall back to a successful RSS read MUST still update `lastFetchedAt`; attempts that fail on both paths MUST NOT update it.
- **FR-005**: The new InnerTube path MUST participate in the existing client-profile rotation pipeline (same pipeline already used by the YouTube caption fetcher), not introduce a separate key / version / rotation mechanism.
- **FR-006**: Per-video metadata surfaced by InnerTube (`lengthText`, `viewCountText`, `publishedTimeText`) MUST be persisted on the existing `youtube_feed_entries` row when present in the response; when absent, the row MUST be cached with whatever the source returned (no second-pass scrape for the new path).
- **FR-007**: When the InnerTube primary path is used and successfully returns a duration, the legacy watch-page HTML duration enrichment MUST NOT be invoked for that entry in that tick.
- **FR-008**: The existing `YoutubeChannelResolver` HTML-scrape path for handle → channel id resolution MUST remain available as a fallback when a URL cannot be parsed by the `channel_id` allowlist path; it is unchanged in this feature.
- **FR-009**: Public exception types and the `DiscoverRefreshResult.failedChannelIds` surface MUST remain stable so existing tests, diagnostics, and UI error notices continue to work.
- **FR-010**: Logs MUST go through `logNamed` / `package:logging` per existing conventions; the new path MUST NOT introduce `print()` calls.
- **FR-011**: A new ADR `0047-youtube-discover-innertube.md` MUST be added under `docs/decisions/` explaining the data-source change, the InnerTube primary + RSS fallback posture, the profile-rotation contract, and the explicit deferral of playlist support to a follow-up spec.
- **FR-012**: `docs/features/discover.md` MUST be updated to describe the dual-source posture, the metadata now surfaced earlier (duration / view count), and the playlist deferral note.
- **FR-013**: Playlist import (`https://youtube.com/playlist?list=…` and the `VL<playlistId>` InnerTube browse path) is explicitly **out of scope** for this feature and is tracked as a follow-up spec.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST live under `lib/features/discover/` and reuse `lib/core/logging/log.dart`, the existing `DiscoverRefreshResult` shape, and the existing Drift DAO contract; no new global singletons or cross-feature shortcuts.
- **QR-002**: The change MUST include automated tests covering: (a) primary-source success path writes the expected rows, (b) primary-source failure falls back to RSS and the cache reflects the RSS payload, (c) primary-source partial shape (missing `lengthText` / `viewCountText`) still writes rows with whatever metadata was returned, (d) failed refresh on both sources leaves the cache and `lastFetchedAt` untouched, (e) cooldown still skips re-fetches inside 1 h, (f) profile rotation: when one profile is throttled, the per-channel request retries with the next profile before falling back to RSS.
- **QR-003**: User-facing strings MUST reuse existing localized strings (refresh notice, empty state, channel feed). No new ARB keys are required for this feature.
- **QR-004**: User-visible performance MUST NOT regress: a refresh of 20 channels MUST complete within the existing wall-clock budget and the merged Discover timeline MUST remain responsive (no jank on scroll) with up to 500 cached entries per channel, leveraging the existing `ValueKey` + `findChildIndexCallback` sliver pattern documented in `docs/features/discover.md`.
- **QR-005**: The change MUST be additive at the persistence layer — no Drift schema migration is required, no `build_runner` regen is needed unless new annotations are introduced, and the `youtube_feed_entries` PK `(channelId, videoId)` is reused unchanged.
- **QR-006**: User-visible error reporting MUST keep the partial-failure contract: when some channels succeed and others fail, the user sees a count of failed channels and can drill in to see which ones, exactly as today. The dual-source posture MUST NOT collapse multiple per-channel failures into one "everything is broken" message.

### Key Entities *(include if feature involves data)*

- **YoutubeFeedEntryRow**: existing Drift row. Schema unchanged. New optional fields that InnerTube supplies (`durationSeconds`, `viewCount`) MAY be persisted if the table already supports them; if not, they are deferred to a follow-up migration (out of scope for this feature).
- **YoutubeChannelSubscriptionRow**: unchanged. Still the source of truth for which channels the user follows.
- **DiscoverChannel**: unchanged domain projection of the subscription row.
- **FeedEntry**: unchanged domain projection of the feed row. Optional fields (`durationSeconds`, `viewCount`) MAY be added to the domain projection if persisted; otherwise they remain `null` for entries sourced from the legacy path and may be filled lazily on playback.
- **YoutubeBrowseClient** (new internal collaborator): wraps the InnerTube `browse` POST, response parsing, and continuation pagination. Lives alongside `YoutubeRssParser` and `YoutubeFetch` in `lib/features/discover/data/`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For a user subscribed to 10 channels, a refresh tick that previously reported at least one channel in `failedChannelIds` due to RSS bot-block returns `failedChannelIds == ∅` in at least 8 of 10 trials when the InnerTube primary path is healthy.
- **SC-002**: For a channel served by the InnerTube primary path, the cache rows written by a refresh carry duration metadata for at least 90% of the returned videos (versus 0% today, since duration was filled only on playback).
- **SC-003**: A 20-channel refresh tick with both sources healthy completes within the existing wall-clock budget (≤ 2× the current baseline) and issues fewer total HTTP requests than the RSS + watch-page enrichment path (≤ 60% of the request count of the legacy path).
- **SC-004**: A channel that fails on both sources has its cache and `lastFetchedAt` left untouched, and the next eligible refresh tick picks up where the last successful refresh left off (same behavior as today).
- **SC-005**: When YouTube begins to throttle a single client profile, the per-channel InnerTube request retries with the next available profile before falling back to RSS, observable in unit tests as `expectedCalls == [profileA, profileB, legacyRss]` for one failing channel.
- **SC-006**: Automated tests cover the new contract: primary success, primary failure → RSS fallback, primary partial shape, dual failure preserves cache, cooldown still skips, profile rotation retries before fallback.
- **SC-007**: `docs/features/discover.md` and a new `docs/decisions/0047-youtube-discover-innertube.md` are merged in the same change so reviewers can verify the contract end-to-end.

## Edge Cases

- What happens when YouTube rotates the `WEB` client version and InnerTube starts returning 401s across all profiles? The per-channel request falls back to the legacy RSS source for that tick (preserves current behavior); the client-profile rotation pipeline re-fetches the next usable profile at its existing cadence. No user-visible regression beyond a temporary per-channel fallback notice.
- What happens when the InnerTube response shape changes (e.g., `richItemRenderer` is renamed)? The parser returns "no usable entries", the channel falls back to the legacy RSS path for that tick, and the failure mode is the same as a transient RSS bot-block — observable, localized, and non-destructive.
- What happens when a subscribed channel is migrated to a different `channel_id` by YouTube? The legacy `YoutubeChannelResolver` path still applies for handle resolution and would need a future update; this feature does not introduce channel-id migration detection.
- What happens when a user is offline at refresh time? The InnerTube call fails with a transport error, the legacy RSS call fails the same way, and `failedChannelIds` includes the offline channels. The cache and `lastFetchedAt` are left untouched; the user sees the standard partial-failure notice when they reconnect.
- What happens to the legacy watch-page duration enrichment? It is retained as the fallback path's metadata completion step but is not invoked when the InnerTube primary path already supplied a duration. If the InnerTube primary path succeeds but omits `lengthText` for an entry, the legacy enrichment is still skipped (we do not want a "successful InnerTube + secondary HTML scrape" hybrid that doubles the request count).
- What happens when the user has zero subscriptions? The 8 h periodic timer is gated on a non-empty subscription list (existing behavior from ADR-0021); this feature does not change that.

## Assumptions

- "Let's make it happen" in the original user description refers to the InnerTube-as-primary / RSS-as-fallback channel refresh path that the prior research turn established. The follow-up "make the playlist" is **explicitly deferred** to a separate spec (FR-013).
- The InnerTube `youtubei.googleapis.com` surface used by the existing YouTube caption fetcher is the same surface used by `browse`, so no new API key, auth flow, or platform dependency is required.
- The client-profile rotation pipeline already implemented for the YouTube caption fetcher is sufficient for the Discover refresh path; no separate rotation mechanism is needed.
- The existing append-only cache contract (ADR-0046) and the existing refresh cooldown / concurrency / lifecycle gating (ADR-0021) remain valid and are not revisited by this feature.
- The InnerTube response renderer names (`richItemRenderer`, `videoRenderer`, `continuationItemRenderer`) are stable at the time of implementation but may shift over time; the parser is isolated to a single small module so a future response-shape change can be absorbed without rippling through the repository.
- Adding a `WEB` client profile alongside the existing `IOS` / `ANDROID_VR` / `MWEB` built-ins is the right shape for the new path; whether to retire any of the existing built-ins is a separate decision tracked outside this spec.
- No new Drift tables are required. New optional columns for `durationSeconds` / `viewCount` may be added to the existing `youtube_feed_entries` table if and only if the team decides persistence is worth a schema bump; otherwise the metadata is held in-memory on the `FeedEntry` projection and filled lazily on playback.
