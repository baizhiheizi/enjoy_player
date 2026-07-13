# Research: InnerTube Channel Discover

**Feature**: [spec.md](spec.md) | **Date**: 2026-07-13

This research consolidates the confirmations needed before design. All unknowns were resolved against (a) the existing codebase (`lib/features/discover/`, `lib/features/transcript/data/`, ADR-0021, ADR-0046, ADR-0036) and (b) the prior deep-dive investigation performed during the `/speckit.specify` step.

## Decision 1: InnerTube `browse` is the primary source for channel refresh

- **Decision**: `DiscoverRepository._refreshChannel` posts to `https://youtubei.googleapis.com/youtubei/v1/browse` with `browseId: "UC<channelId>"` and parses the `richItemRenderer.content.videoRenderer` chain from the `tabs[?].tabRenderer.content.richGridRenderer.contents` array. Pagination uses the `continuationItemRenderer.continuationEndpoint.continuationCommand.token` returned at the tail of the page; the same endpoint is hit with `{ context, continuation }` for subsequent pages. A hard page cap (default 5 pages ≈ 150 entries) bounds total wall-clock per channel.
- **Rationale**: InnerTube `browse` returns the same anonymous surface used by the existing YouTube caption fetcher — no new API key, no new platform dependency. The JSON shape is materially more stable than the HTML regex patterns used by `YoutubeRssParser` and `YoutubeChannelResolver`. The path reuses the `ClientProfile` model already shipped by `client_profile.dart` and the worker rotation pipeline that refreshes the profile list every 24 h.
- **Alternatives considered**:
  - **Keep RSS as primary** — rejected: the user-facing bug is exactly that the public Atom RSS endpoint returns bot-block / consent HTML instead of a valid Atom feed, and there is no in-band signal that lets the client recover without a retry ladder. (See `specs/016-append-only-discover-feed/spec.md:117` for the original typo correction.)
  - **Use InnerTube `search`** — rejected: `search` requires opaque `params` tokens and rate-limits aggressively; it is not a "list videos on a channel" endpoint.
  - **Use InnerTube `next`** for continuation only — considered: `next` and `browse` accept the same continuation token; `browse` is the canonical entry point and is what yt-dlp targets. We stay on `browse` and treat `next` only as a fallback if `browse` ever rejects a continuation.

## Decision 2: Add a `WEB` client profile; do not retire existing built-ins

- **Decision**: Add a new built-in `ClientProfile` (`name: 'web'`, `clientName: 'WEB'`, current `clientVersion`) to `lib/features/transcript/data/client_profile.dart` alongside the existing `IOS` / `ANDROID_VR` / `MWEB`. `YoutubeBrowseClient` is configured to prefer `WEB` first and fall back to `MWEB` on per-channel 401/403. `IOS` and `ANDROID_VR` remain in the file for the caption fetcher's own rotation; they are not used by `browse` (TVHTML5-style `ANDROID_VR` is documented as rejecting `browse` with 401).
- **Rationale**: The caption fetcher already owns the profile lifecycle (worker fetch + 24 h cache + built-in fallback at `lib/features/transcript/data/client_profile.dart:1-7`). Reusing the same `ClientProfile` type and the same storage avoids splitting the rotation surface. The new `WEB` profile ships as a built-in so the path works on cold start before the worker is reachable.
- **Alternatives considered**:
  - **Define a separate `ClientProfile`-equivalent type for Discover** — rejected: would duplicate `clientProfilesFromJson`, the `isValid` check, the worker integration, and the cold-start fallback. The existing `ClientProfile` model is the right level of abstraction.
  - **Hard-code a `WEB` profile only and fetch everything else from the worker** — rejected: degrades the cold-start path; the user is offline for one extra refresh tick.
  - **Retire `ANDROID_VR`** — deferred: the caption fetcher's retry ladder depends on it. A separate decision.

## Decision 3: InnerTube-supplied durations persist on the existing `YoutubeFeedEntries.durationSeconds` column

- **Decision**: When InnerTube `browse` returns a `videoRenderer.lengthText` (or its `thumbnailOverlayTimeStatusRenderer` equivalent), the parsed `durationSeconds` is written into the existing nullable `YoutubeFeedEntries.durationSeconds` column on the cache row. When InnerTube omits `lengthText`, the row is cached with `durationSeconds = null` and **no** legacy watch-page HTML enrichment is invoked for that entry (per FR-007).
- **Rationale**: `YoutubeFeedEntries.durationSeconds` is already nullable, so no schema migration is required and no codegen drift is introduced. Skipping the watch-page HTML scrape for InnerTube-sourced rows keeps the request-count budget honest (SC-003).
- **Alternatives considered**:
  - **Add a separate `browse_duration_seconds` column** — rejected: schema churn for no functional gain.
  - **Always run the watch-page enrichment** as a second pass — rejected: would double the request count on InnerTube-sourced rows and erase the bandwidth win promised in SC-003.
  - **Drop the duration enrichment path entirely** — rejected: the legacy RSS fallback still needs it; today the RSS payload does not include duration and the enrichment is the only way the timeline shows a length on legacy-sourced rows.

## Decision 4: Fallback triggers are explicit and observable

- **Decision**: `DiscoverRepository._refreshChannel` falls back to the legacy RSS path for a channel on **any** of:
  1. InnerTube returns HTTP 401/403/404/5xx across all available profiles for that channel.
  2. InnerTube returns HTTP 200 but the response has no recognized `richGridRenderer` (channel uploader is missing or the channel was suspended/deleted).
  3. InnerTube returns HTTP 200 with `richGridRenderer.contents` empty or with no `richItemRenderer` (a non-video tab was selected by mistake — defensive against renderer-name drift).

  A successful InnerTube refresh followed by a successful RSS fallback both advance `lastFetchedAt`. A failure on both paths leaves the cache and `lastFetchedAt` untouched and reports the channel id in `DiscoverRefreshResult.failedChannelIds` (preserving FR-008 from spec 016).
- **Rationale**: The triggers are conservative — they cover the three known bot-block / shape-drift failure modes the prior research turned up. The two-path success rule preserves the cooldown clock for partial outages; the two-path failure rule preserves the existing back-off contract. Both are observable in unit tests.
- **Alternatives considered**:
  - **Cache `browse`-then-`rss` results and never fall back** — rejected: drops the legacy path's reliability story for users whose network can't reach `youtubei.googleapis.com`.
  - **Per-tick "did we already try RSS recently?" memory** — rejected: keeps the contract simple. The cooldown clock is the right gate; we don't need a second gate.

## Decision 5: Page cap (5) bounds InnerTube pagination per channel

- **Decision**: `YoutubeBrowseClient.fetchChannelVideos` stops after 5 continuation pages (~150 entries) per call, even if a `continuationItemRenderer` is still being returned. The cap is a named constant (`_kBrowseMaxPages`, default 5) and is overridable in tests.
- **Rationale**: Active channels can publish more than 30 entries a day; an unbounded continuation loop would let one channel monopolize the 4-way `_kRefreshChannelConcurrency` budget and starve the others. 150 entries is a comfortable upper bound for a refresh tick (more than 5× the RSS window) and well below the `youtube_feed_entries` per-channel budget (500) established by ADR-0046 / QR-004.
- **Alternatives considered**:
  - **Unbounded continuation** — rejected: worst-case amplification of a single channel's wall-clock cost.
  - **Per-tick quota across channels** — rejected: requires cross-channel state inside the repository; the page cap is simpler and achieves the same goal.

## Decision 6: Profile rotation is per-channel, not per-tick

- **Decision**: When a channel's InnerTube request fails on `WEB` with a profile-specific error (401/403), the same channel retries with the next profile in the configured order (`WEB` → `MWEB`). The retry happens inside `_refreshChannel`, not at the `refreshFeeds` level. Only after all profiles have been exhausted does the channel fall back to the legacy RSS path.
- **Rationale**: Per-channel retry matches the existing caption-fetcher behavior (`youtube_caption_fetcher.dart:130-198`) and limits cross-channel interference. A per-tick rotation (rotate globally after N failures) would be simpler but would mask channel-specific throttling.
- **Alternatives considered**:
  - **Rotate globally on the first failure** — rejected: a single throttled channel would push every other channel onto a degraded profile for the rest of the tick.
  - **No rotation; fail on first 401** — rejected: when YouTube begins throttling a profile, the failure mode becomes a total outage of the InnerTube path until a new version is fetched from the worker. The retry ladder is the cheap mitigation.

## Decision 7: `YoutubeChannelResolver` HTML-scrape path stays unchanged in this plan

- **Decision**: Handle / URL → `channel_id` resolution continues to use the existing HTML-scrape path in `youtube_channel_resolver.dart:80-118`. An InnerTube `navigation/resolve_url` alternative was identified during the prior deep-dive but is **not** part of this feature; it is deferred to a follow-up so this feature can stay focused on the channel refresh data-source swap.
- **Rationale**: The handle resolver already has its own failure surface (also bot-block HTML); replacing it would double the scope. The Discover refresh contract (FR-008) says "the existing `YoutubeChannelResolver` HTML-scrape path … MUST remain available as a fallback when a URL cannot be parsed by the `channel_id` allowlist path; it is unchanged in this feature."
- **Alternatives considered**: replace with `navigation/resolve_url` — deferred (see above).

## Decision 8: New ADR

- **Decision**: Add `docs/decisions/0047-youtube-discover-innertube.md` to record the data-source change, the InnerTube-primary + RSS-fallback posture, the page cap, the profile rotation contract, and the explicit playlist deferral. Reference it from `docs/features/discover.md`.
- **Rationale**: ADR-0021 pins the original RSS-as-data-source decision. ADR-0046 refines the cache semantics. The new ADR supersedes the data-source half of ADR-0021 without touching the cache half. ADRs are append-only by convention; updating ADR-0021 in place would erase the history of why we changed our mind.
- **Alternatives considered**: edit ADR-0021 — rejected, see above.

## Summary

The change is a primary-source swap inside one repository method (`_refreshChannel`), one new collaborator (`youtube_browse_client.dart`), one shared built-in client profile (`WEB` in `client_profile.dart`), and its tests + docs. No new dependencies, no Drift schema change, no codegen regeneration, no widget code. The performance budget, refresh gating, append-only cache, and sliver pattern are all preserved; the request-count budget improves when the InnerTube primary path is healthy.
