# Feature Specification: Discover Feed Append-Only Persistence

**Feature Branch**: `016-append-only-discover-feed`

**Created**: 2026-07-13

**Status**: Draft

**Input**: User description: "We've a problem, if user subscribe a YouTube channel, it fetch the videos frome the channel css. But the records never be persisted. When the css source update, the video list refresh totally, not append only. Not like a css client. We should refactor it."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Refresh keeps the channel history intact (Priority: P1)

A learner subscribes to a YouTube channel they want to follow over time. On the first refresh they see the channel's most recent uploads (typically the 15 newest). Over the following weeks and months the channel publishes more videos. Every time the channel refreshes, the new uploads appear in the timeline, but **the videos they already saw last week and last month stay where they were**. The Discover feed behaves like a proper feed reader: it grows monotonically as new content shows up, and never silently deletes videos just because the source no longer lists them among its 15 newest.

**Why this priority**: This is the core bug. Today the cache is wiped and rewritten on every refresh, so the user has no persistent record of what they saw and no scrollable history beyond the 15 newest. Any further discover work depends on this behavior being fixed first.

**Independent Test**: Seed the discover feed cache with 30 synthetic entries for one channel, then run `refreshFeeds()` against a stubbed RSS source that returns 15 entries, 10 of which are already in the cache. After the refresh the cache MUST contain all 30 original entries plus any genuinely new entries (none in this scenario), and the 20 entries not returned by the RSS source MUST still be present. The displayed list MUST still be sorted by `publishedAt` descending.

**Acceptance Scenarios**:

1. **Given** a channel with 30 cached feed entries, **When** an RSS refresh returns the same 15 entries that were already cached, **Then** the cache still contains 30 entries and no rows are duplicated.
2. **Given** a channel with 30 cached entries, **When** an RSS refresh returns the same 15 entries plus 2 new ones, **Then** the cache grows to 32 entries, the 17 seen entries have their metadata refreshed, and the 13 entries not returned remain untouched.
3. **Given** a channel with 30 cached entries spanning 3 months of uploads, **When** the channel's RSS only returns the 15 newest entries, **Then** the 15 oldest cached entries remain visible in the channel feed (and timeline if the user filters to that channel) instead of being pruned.
4. **Given** the Discover screen is open and a periodic 8 h refresh lands, **When** the user is mid-scroll through the timeline, **Then** only the newly added entries change the visible order; previously visible entries stay in the same `Element` slot thanks to the existing `ValueKey` + `findChildIndexCallback` mechanism.

---

### User Story 2 - Unsubscribing still clears the channel's cache (Priority: P2)

When a learner unsubscribes from a channel because they no longer want to follow it, all cached feed entries for that channel are removed from the local database. The unsubscribed channel no longer appears in any Discover view, and no background refresh re-fetches its RSS.

**Why this priority**: This preserves the existing privacy / storage expectation from `docs/features/discover.md` and keeps unsubscribed channels from reappearing after a later refresh tick. It also bounds cache growth: unsubscribing is the user-visible way to stop tracking a channel.

**Independent Test**: Seed 10 entries for channel A and 5 for channel B. Call `unsubscribe(A)`. Assert the channel A subscription row is gone, all 10 channel A feed entries are gone, channel B's subscription and 5 entries are untouched, and a subsequent periodic refresh does not touch any channel A row.

**Acceptance Scenarios**:

1. **Given** a user is subscribed to channel A with cached feed entries, **When** they tap **Unsubscribe** in the channel feed or Manage channels view, **Then** the subscription row and all of its cached feed entries are removed from the local database before the UI closes.
2. **Given** a user unsubscribes from channel A, **When** the next periodic refresh tick runs, **Then** channel A is not re-fetched (it is not in the subscription list any more) and no entries for it are written back.
3. **Given** the user re-subscribes to channel A after unsubscribing, **When** the first refresh completes, **Then** the channel feed shows only entries returned by that refresh (the prior cache was cleared and does not come back automatically).

---

### User Story 3 - Refresh stays idempotent and skips on the 1-hour cooldown (Priority: P3)

The refresh contract remains unchanged from the outside: per-channel RSS fetches still respect the 1-hour cooldown unless the user pulls to refresh, the 8 h periodic timer still gates on the subscription list and the foreground lifecycle, and concurrent channel refreshes still cap at the existing 4-way concurrency. Idempotency now extends to "the cache state after a refresh is the same whether the RSS source returned 0 entries, 5 entries, or 20 entries, **as long as the (channelId, videoId) set is the same**".

**Why this priority**: Existing tests and behavior contracts assume this; the append-only change must not regress them. Keeping the public behavior surface stable lowers review risk and avoids breaking the diagnostics and DDTB tools that already count `youtube_feed_entries`.

**Independent Test**: With a stubbed RSS source that returns 10 fixed entries, call `refreshFeeds()` twice in a row for the same channel. Assert both calls upsert the same 10 rows (no duplicates), the cache count remains 10, and `watchChannelFeed()` only emits once per actual change.

**Acceptance Scenarios**:

1. **Given** a channel is eligible for refresh (last fetch &gt; 1 h), **When** the refresh runs against a stable RSS response, **Then** `watchChannelFeed` and `watchTimeline` emit exactly once with the new state.
2. **Given** a channel was fetched less than 1 h ago, **When** a periodic refresh tick runs, **Then** the channel is skipped and its cache is left untouched.
3. **Given** a refresh throws (HTTP error, bot-block page, malformed XML), **When** the failure is reported via `DiscoverRefreshResult.failedChannelIds`, **Then** the channel's existing cache entries are left untouched and the channel's `lastFetchedAt` is **not** updated (the cooldown still applies to failed attempts to avoid hammering YouTube).

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The RSS refresh path MUST append new feed entries to the local cache instead of replacing it.
- **FR-002**: For each entry the RSS source returns, the refresh MUST upsert the row keyed by `(channelId, videoId)` so mutable metadata (title, thumbnail URL, `publishedAt`) is refreshed without losing history.
- **FR-003**: The refresh MUST NOT delete cached entries solely because they did not appear in the latest RSS response.
- **FR-004**: The refresh path MUST NOT delete cached feed entries based on whether they appear in the latest RSS response. The previous `YoutubeFeedEntryDao.deleteStaleForChannel` helper that did this was removed in this refactor (ADR-0046) so the bad contract cannot be re-introduced by accident.
- **FR-005**: The "last confirmed" timestamp on each cached entry MUST represent the last time the source re-presented that entry, not the first time we observed it. This is observable to the user as: a row that has not been in the RSS feed for a long time keeps its original "first seen" date for the actual upload, but its "last confirmed" timestamp remains stable; conversely, an entry that re-appears in a later RSS payload reflects the latest confirmation.
- **FR-006**: Unsubscribing from a channel MUST continue to delete every cached feed entry for that channel (current behavior, `YoutubeFeedEntryDao.deleteForChannel`).
- **FR-007**: Periodic, manual, and on-launch refresh behavior MUST remain unchanged in its triggers, gating, and concurrency caps (1 h cooldown unless forced, 8 h timer gated on subscription list and foreground lifecycle, 4-way concurrency per `_kRefreshChannelConcurrency`).
- **FR-008**: Failed refreshes MUST NOT update `lastFetchedAt` and MUST NOT delete or overwrite any cached entries; only successful refreshes may write.
- **FR-009**: The merged timeline (`watchTimeline`) and per-channel feed (`watchChannelFeed`) MUST continue to surface cached entries sorted by `publishedAt` descending, regardless of `fetchedAt`.
- **FR-010**: The Discover settings / diagnostics surface SHOULD reflect the new "cache size per channel" reality (e.g., show entry counts) so users understand that the list grows over time rather than resetting. Implementation may be deferred to a follow-up if not in scope for this refactor, but the data path MUST make it available.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve Enjoy Player's feature-first architecture under `lib/features/discover/` and not introduce cross-feature shortcuts.
- **QR-002**: Changed behavior MUST have automated tests covering: (a) cache grows when new entries arrive, (b) cache is preserved when RSS omits existing entries, (c) refresh is idempotent on identical RSS responses, (d) unsubscribe clears the channel's entries, (e) failed refresh leaves the cache untouched.
- **QR-003**: User-facing strings (refresh notice, empty state, channel feed) MUST follow existing localization patterns and reuse the existing ARB strings; new strings are not required for this refactor.
- **QR-004**: The merged timeline MUST remain responsive (no jank on scroll, no full-list rebuild) with up to 500 cached entries per channel, leveraging the existing `ValueKey` + `findChildIndexCallback` sliver performance pattern documented in `docs/features/discover.md`.
- **QR-005**: The first refresh after the change ships MUST NOT delete or rewrite existing cached entries for any user (the schema and DAO semantics stay the same; only the refresh flow changes).
- **QR-006**: Feature behavior change MUST update `docs/features/discover.md` (section "Limitations" and any "Feed refresh" wording that implies a full replace) and add a new ADR under `docs/decisions/` explaining why the cache is now append-only.
- **QR-007**: Diagnostics (`docs/features/diagnostics.md` and any in-app counters) MUST continue to report a meaningful "feed cache size" metric; if it is already reported, no change is required beyond the corrected column semantics.

### Key Entities *(include if feature involves data)*

- **YoutubeFeedEntryRow**: existing Drift row. Unchanged schema. `fetchedAt` semantics shift from "fetch timestamp of this row's creation" to "last refresh that re-confirmed this entry from the source". The cache is now append-only between unsubscribe events.
- **YoutubeChannelSubscriptionRow**: unchanged. Still the source of truth for which channels the user follows.
- **DiscoverChannel**: unchanged domain projection of the subscription row.
- **FeedEntry**: unchanged domain projection of the feed row. Equality and ordering are unchanged.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After a refresh whose RSS payload is a strict subset of the current cache (or equal to it), the cache size and content are preserved exactly (no row deleted, no row duplicated).
- **SC-002**: After a refresh whose RSS payload contains N entries, of which K are already cached, the cache size grows by exactly `N − K` (only genuinely new entries are added).
- **SC-003**: A subscription that has been followed for 6 months retains every video ever seen via RSS, not just the most recent 15 (assuming refresh ran successfully at least once after each upload window).
- **SC-004**: Unsubscribing from a channel reduces the `youtube_feed_entries` row count by exactly the number of entries previously cached for that channel.
- **SC-005**: A failed refresh (HTTP error, bot-block, malformed XML) leaves the cache and `lastFetchedAt` untouched, and the next eligible refresh picks up where the last successful one left off.
- **SC-006**: The merged Discover timeline continues to render in under 200 ms (first paint after a refresh) when up to 500 entries are cached per channel.
- **SC-007**: 100% of automated tests that touched the prior `deleteStaleForChannel` behavior are either updated to assert the new append-only behavior or are explicitly retired with a documented reason. (The DAO helper itself was also removed; see ADR-0046.)

## Edge Cases

- What happens when a channel is deleted by YouTube? The RSS source either returns an error (handled by FR-008) or returns an empty feed; in both cases existing entries stay in the cache. Surfacing a "channel unavailable" hint is out of scope for this refactor.
- What happens when a single video is removed by YouTube after being cached? The row stays until the user unsubscribes; playback will surface a separate "video unavailable" path already used elsewhere.
- What happens when a refresh returns an empty RSS payload (not an error)? The cache is preserved; no entries are deleted.
- What happens to the "stale-entry" deletion that some test fixtures or repair flows rely on? The previous `deleteStaleForChannel` helper has been removed (ADR-0046); any future prune-style affordance should be a new DAO method with explicit intent rather than re-introducing the old name.
- What happens with very long-lived subscriptions (years)? The cache grows monotonically per channel. Hard bounds (e.g., max entries per channel) are explicitly deferred; we assume RSS cadence and per-channel volume make this acceptable for the foreseeable horizon.
- What happens with concurrent refreshes? The existing 4-way concurrency cap and per-channel write semantics remain unchanged; append-only behavior is per-row idempotent and safe under concurrency because upserts are keyed by `(channelId, videoId)`.

## Assumptions

- "channel css" in the original user description is a typo for "channel RSS" (the existing data source). The codebase already fetches via `https://www.youtube.com/feeds/videos.xml?channel_id=...` and there is no "CSS" scraping path. The refactor keeps RSS as the source.
- "Records never be persisted" is the user's perception of the current behavior: while the entries technically reach Drift, they are wiped on the next refresh, so the user sees no durable history. This refactor makes the persistence visible.
- Users will manage long-history cache growth via unsubscribe; we are not introducing a manual "clear feed history" affordance in this refactor.
- The existing `ValueKey` + `findChildIndexCallback` sliver performance pattern is sufficient to keep the merged timeline responsive as cache sizes grow; no pagination or virtual scrolling is required for v1.
- The channel-page HTML scraping path (`YoutubeChannelResolver`, `YoutubeVideoDuration`) is unchanged and stays in use for handle resolution, avatar enrichment, and duration enrichment.
- The existing per-channel refresh cooldown (1 h), periodic refresh cadence (8 h), concurrency caps, and lifecycle gating already in `discover_repository.dart` and `discover_providers.dart` are preserved.
- The change is a behavior fix on the production refresh path; it does not require a Drift schema migration or codegen regeneration, but DOES require running `dart run build_runner build` only if new Drift annotations are introduced (which they should not be).