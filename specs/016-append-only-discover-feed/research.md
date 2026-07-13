# Research: Discover Feed Append-Only Persistence

**Feature**: [spec.md](spec.md) | **Date**: 2026-07-13

This research consolidates the confirmations needed before design. No external integrations are introduced; all unknowns were resolved against the existing codebase (`lib/features/discover/`, `lib/data/db/`, ADR-0021) and the public YouTube Atom RSS behavior already documented in `docs/features/discover.md` and `docs/decisions/0021-youtube-discover-rss.md`.

## Decision 1: Use the existing Drift upsert, do not change the schema

- **Decision**: The refresh path keeps using `YoutubeFeedEntryDao.upsertEntry(YoutubeFeedEntryRow)` with composite PK `(videoId, channelId)`. No Drift migration is introduced.
- **Rationale**: The schema is already correct for the desired behavior — composite PK means concurrent upserts of the same `(channelId, videoId)` are idempotent, and new entries simply insert. Changing the schema would force a migration on every install for no behavior gain.
- **Alternatives considered**:
  - **Soft-delete column (`is_stale`)** — rejected: adds schema complexity, requires periodic GC, and the user already has an unsubscribe path for "I no longer want this".
  - **Separate `feed_history` table** — rejected: doubles the write surface, complicates `watchChannelFeed` ordering, and gains nothing the current schema doesn't already give us.

## Decision 2: Remove the `deleteStaleForChannel` prune path entirely

- **Decision**: `DiscoverRepository._refreshChannel` no longer deletes rows based on the latest RSS payload. The `YoutubeFeedEntryDao.deleteStaleForChannel` helper is removed from the DAO because it had no other callers after the refresh path stopped routing through it, and re-introducing a "maintenance-only" prune would silently re-open the data-loss mode the spec is closing.
- **Rationale**: The previous `deleteStaleForChannel(channelId, keepVideoIds)` was the single source of the "wipe on refresh" behavior. Removing the call from production AND the helper from the DAO is the smallest change that produces the correct user-facing behavior and leaves no easy way back to the buggy contract.
- **Alternatives considered**:
  - **Keep the call but only fire on explicit "Compact cache" action** — deferred: out of scope for this refactor; the spec explicitly defers manual cache management to a follow-up. If/when added, that affordance should introduce a new DAO method with explicit intent rather than re-adding `deleteStaleForChannel`.
  - **Use a TTL on each row** — rejected: the spec scopes the fix to "until unsubscribe"; a TTL would silently re-introduce data loss.

## Decision 3: Preserve the existing 4-way concurrency and 1-hour cooldown

- **Decision**: `_kRefreshChannelConcurrency = 4`, `minRefreshInterval = 1 h`, and the 8 h periodic lifecycle-gated timer in `discover_providers.dart` are unchanged.
- **Rationale**: These were tuned in ADR-0021 and the subsequent Discover tuning notes. They are orthogonal to whether the cache is append-only or replace-on-refresh.
- **Alternatives considered**:
  - **Add a refresh budget per cache size** — rejected: RSS payloads are bounded (~15 entries per channel) so the per-channel work is bounded regardless of cache size.

## Decision 4: Failed refreshes must not touch `lastFetchedAt`

- **Decision**: `_refreshChannel` writes `lastFetchedAt` only on a successful refresh. A failure (HTTP error, bot-block page, malformed XML) propagates to `DiscoverRefreshResult.failedChannelIds` without writing the timestamp.
- **Rationale**: This preserves the existing back-off semantics: a transient failure must not block the next eligible retry. This rule is implied by the current code (the write happens after the parse step), but it becomes observable contract once we are append-only — otherwise a failure could lose the appended-but-never-`lastFetchedAt`-confirmed state.
- **Alternatives considered**:
  - **Write `lastFetchedAt` on every attempt** — rejected: would defeat the cooldown, since failed retries would push the next eligible refresh further out.

## Decision 5: Per-channel unbounded cache, governed by unsubscribe only

- **Decision**: No hard upper bound on entries per channel. Users control growth by unsubscribing. Diagnostics surface continues to report `youtube_feed_entries` row counts.
- **Rationale**: RSS publishes roughly 1–10 entries per channel per week; a 6-month subscription yields ~30–250 entries. A 500-entry-per-channel ceiling is a comfortable margin and is the worst case tested in SC-006. Hard limits are deferred (per the spec Assumptions) and can be added later without changing the user-visible behavior the spec describes.
- **Alternatives considered**:
  - **Cap at e.g. 500 entries per channel with FIFO eviction** — rejected for v1: introduces a new failure mode ("why did an old video disappear?") that the user did not ask for. Available as a follow-up if storage becomes a real concern.

## Decision 6: Render path stays sliver-keyed

- **Decision**: `discover_screen.dart` and `channel_feed_screen.dart` continue to use `ValueKey<String>('discover-feed-<videoId>')` / `'channel-feed-<videoId>'` plus `findChildIndexCallback`. No new widget code is added.
- **Rationale**: The existing pattern already supports `O(visible window)` diffing. With the cache now growing beyond 15 entries per channel, the stable keys become even more valuable (insertions at the head no longer force a rebuild of the entire list — only the new tile mounts).
- **Alternatives considered**:
  - **Pagination or virtual scrolling** — rejected for v1: needed only when the visible window meaningfully exceeds 500 entries; the spec budget is 500.

## Decision 7: `fetchedAt` semantics shift (documented in spec + ADR)

- **Decision**: `YoutubeFeedEntryRow.fetchedAt` is documented as "the last time the source re-presented this entry". The column itself does not move.
- **Rationale**: The semantic shift is necessary because the cache can now retain rows whose `fetchedAt` is much older than `lastFetchedAt` of the channel (the entry fell out of the RSS window). Existing readers (e.g., duration-enrichment ordering) are not affected because none of them order by `fetchedAt`.
- **Alternatives considered**:
  - **Add a separate `firstSeenAt` column** — rejected: schema churn for no functional gain; the spec already covers the observable behavior in FR-005.

## Decision 8: New ADR

- **Decision**: Add `docs/decisions/0046-discover-feed-append-only.md` to record the change, link it from `docs/features/discover.md`, and reference it from any future refresh-flow work.
- **Rationale**: ADR-0021 currently states "feed cache in Drift (`youtube_feed_entries`), separate from library `videos`" but does not pin down the append-vs-replace behavior. A new ADR keeps the decision discoverable and supersedes any older wording.
- **Alternatives considered**: Update ADR-0021 in place — rejected: ADRs are append-only by convention; a new entry preserves the history of why we changed our mind.

## Summary

The refactor is a one-call deletion (`deleteStaleForChannel`) plus removing the now-dead DAO helper, plus a doc/ADR/test sweep. No new dependencies, no Drift schema change, no codegen regeneration, no UI rewrite. The performance budget, refresh gating, and sliver pattern are all preserved.