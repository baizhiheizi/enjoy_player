# ADR-0047: InnerTube `browse` as primary source for YouTube channel discover

## Status

Accepted

## Context

The Discover feature fetches YouTube channel data via the public Atom RSS endpoint at `https://www.youtube.com/feeds/videos.xml?channel_id=<UC…>` (`lib/features/discover/data/youtube_fetch.dart:6-30`). The refresh path runs on launch, on pull-to-refresh, on the in-screen header refresh button, and on an 8 h lifecycle-gated timer.

The RSS endpoint routinely returns HTTP 200 with a bot-block / consent interstitial HTML page instead of a valid Atom feed. `YoutubeRssParser.isValidFeedDocument` rejects the body and `DiscoverRepository._refreshChannel` throws `YoutubeFeedFetchException`, which `_refreshChannelGuarded` records in `DiscoverRefreshResult.failedChannelIds`. The user sees a localized error notice and the channel feed does not update. This is the user-visible reliability problem spec 017 is closing.

Independently, the RSS payload only carries `videoId`, `title`, `published`, and a thumbnail — no `lengthText`, no `viewCountText`, no `publishedTimeText`. Discover fills the duration gap today by fetching the watch-page HTML for every cached video (`YoutubeVideoDuration`), which adds up to 15 watch-page GETs per channel refresh and 300 GETs across a 20-channel refresh tick.

YouTube also exposes an anonymous `InnerTube` `browse` endpoint at `https://youtubei.googleapis.com/youtubei/v1/browse` that returns a richer JSON payload. The same anonymous surface is already used by the YouTube caption fetcher (`lib/features/transcript/data/youtube_caption_fetcher.dart:18-19`), and the same shared `ClientProfile` model (`lib/features/transcript/data/client_profile.dart`) is used to spoof a client identity for anti-bot mitigation. Spec 013 established that posture for captions; spec 017 extends it to channel refresh.

## Decision

1. **`DiscoverRepository._refreshChannel` becomes a dual-source contract.** It tries the InnerTube `browse` endpoint first; on `YoutubeBrowseException` (transport, parse, shape drift, or HTTP 401/403/5xx across all configured client profiles) it falls back to the existing Atom RSS path. Either source's success counts; both failing throws to `_refreshChannelGuarded` and the channel id is reported in `failedChannelIds`. The cache and `lastFetchedAt` are left untouched on dual failure.

2. **New collaborator `YoutubeBrowseClient`** (`lib/features/discover/data/youtube_browse_client.dart`) wraps the InnerTube `browse` call. It mirrors `YoutubeCaptionFetcher`'s posture exactly:
   - Anonymous InnerTube surface; no API key.
   - Per-channel profile rotation in `kBrowsePreferredProfileOrder` (`web` → `mweb`); each profile is tried once on the initial call before moving to the next. The successful profile is reused for all continuation pages.
   - Continuation pagination via `continuationItemRenderer.continuationEndpoint.continuationCommand.token`, capped at `kBrowseMaxPages = 5` (≈ 150 entries per channel) to bound wall-clock per channel under the existing 4-way `_kRefreshChannelConcurrency`.
   - `package:http` POST with `Content-Type: application/json` and the `X-YouTube-Client-Name` / `X-YouTube-Client-Version` headers.
   - `logNamed('discover.browse')` for diagnostics; never `print()`.

3. **New built-in `ClientProfile`** added to `kBuiltInClientProfiles`: `name: 'web'`, `clientName: 'WEB'`, `clientVersion: '2.20240101.00.00'`, desktop Chrome user agent, `platform: DESKTOP` context. `IOS` and `ANDROID_VR` remain in the list because the caption fetcher's rotation ladder depends on them; they are not used for `browse` (`ANDROID_VR` is documented as rejecting `browse` with 401). The cold-start fallback reuses the same built-in surface the caption fetcher already has, so no separate storage is needed.

4. **InnerTube-supplied `durationSeconds` persists on the existing `YoutubeFeedEntries.durationSeconds` column.** Preference order on each upsert:
   1. Library row (`videos.durationSeconds > 0`) — the user's source of truth once they imported the video.
   2. InnerTube-supplied `BrowseVideoEntry.durationSeconds` (parsed from `lengthText.simpleText`).
   3. Existing cache row's `durationSeconds` (preserved across refreshes per ADR-0046).
   No Drift migration is introduced.

5. **Legacy watch-page HTML duration enrichment is skipped on the InnerTube path.** When InnerTube supplies a `lengthText`, the cache row carries `durationSeconds` from the response and `_enrichMissingDurations` is not invoked for that tick. When InnerTube omits `lengthText` for an entry, the row is cached with `durationSeconds = null` and the legacy enrichment is still **not** invoked (no "InnerTube + HTML scrape" hybrid). The legacy enrichment runs only on the RSS fallback path, matching the pre-change behavior on that branch.

6. **Append-only cache contract (ADR-0046) is preserved.** The InnerTube primary path uses the same `(channelId, videoId)` upsert loop the RSS path already used; rows absent from the latest InnerTube payload are not deleted. A 50-row cache receiving a 30-row InnerTube payload keeps all 50 rows.

7. **The 1 h per-channel cooldown, 4-way concurrency cap, and 8 h lifecycle-gated timer are preserved.** None of the existing scheduling knobs change. The InnerTube primary path participates in the same cooldown via the existing `touchLastFetched` write at the end of `_refreshChannel`'s success path.

8. **`YoutubeChannelResolver` HTML-scrape path is unchanged.** Handle / URL → `channel_id` resolution continues to use the existing path. An InnerTube `navigation/resolve_url` alternative was identified but is **explicitly deferred** to a follow-up.

9. **Playlist import is explicitly out of scope.** The `VL<playlistId>` form of `browseId` and the `https://youtube.com/playlist?list=…` flow are deferred to a separate spec.

10. **No new dependencies, no Drift migration, no codegen regeneration.** The existing `package:http`, `package:logging`, Drift `AppDatabase`, and `ClientProfile` model carry the change.

## Consequences

Positive:

- Channel refresh is materially more reliable: under healthy InnerTube conditions, the user-facing error notice drops to zero for the common case. When YouTube begins throttling a single client profile, the per-channel retry ladder switches to the next profile before falling back to RSS.
- The Discover timeline shows video duration on InnerTube-sourced rows immediately, without waiting for the watch-page HTML enrichment. View count text is parsed but not persisted in this plan (held in the `BrowseVideoEntry.viewCountText` projection so a future change can persist it without touching the client).
- A 20-channel refresh tick issues ≤ 60% of the legacy request count (20 POSTs vs. 320 GETs).
- The same client-profile rotation pipeline, `logNamed` channel discipline, and exception-as-data contract used by the caption fetcher are reused — no new infrastructure.

Implementation notes (added during development):

- The parser tries three response-shape paths in order: `richGridRenderer` (paginated, preferred), `sectionListRenderer` → `shelfRenderer` → `horizontalListRenderer` (the Home / Videos-as-shelf shape used by some large channels like TED), and a deep recursive search. All three paths route items through a generic `_tryExtractEntry` helper that recognises `videoRenderer`, `gridVideoRenderer`, `compactVideoRenderer`, `lockupViewModel`, and `shortsLockupViewModel`. Channels that wrap their videos in the modern `lockupViewModel` renderer (e.g., TED) now resolve to the InnerTube path rather than always falling back to RSS.
- `durationSeconds` is resolved in three places for legacy renderers (`lengthText.simpleText`, `thumbnailOverlays[*].thumbnailOverlayTimeStatusRenderer.text.simpleText`, legacy top-level overlay) plus a fourth location for `lockupViewModel` (`contentImage.thumbnailViewModel.overlays[*].thumbnailBottomOverlayViewModel.badges[*].text` or `.thumbnailOverlayBadgeViewModel.thumbnailBadges[*].text`).

Negative / trade-offs:

- InnerTube client versions rotate every 2–8 weeks. Mitigations: the worker `GET /youtube/client-profiles` pipeline (`client_profile.dart`) re-fetches the live version list every 24 h; the new `WEB` built-in is the cold-start fallback. If both the live and built-in versions are throttled simultaneously, the per-channel retry ladder falls back to RSS — the same failure surface as today.
- InnerTube response shape can drift (`richItemRenderer`, `videoRenderer`, `continuationItemRenderer` are stable today per yt-dlp but Google may rename them). Mitigations: the parser is isolated to one file; `_findRichGridContents` returns `null` on shape drift, which the client translates to `YoutubeBrowseException('no videos')`, which the repository catches and routes to the RSS fallback. The user sees a non-blocking error for that tick; the cache and `lastFetchedAt` are untouched.
- A new collaborator `YoutubeBrowseClient` is added to the Discover data layer. Mitigations: it follows the same construction pattern as `YoutubeChannelResolver` and `YoutubeRssParser` (constructor-injected, default-constructed from `_client`), so unit tests can substitute a mock via the `browseClient` parameter without touching other plumbing.
- On InnerTube success, the channel's `displayName` is not refreshed (the InnerTube `channelMetadataRenderer.title` path is not wired in this MVP). The user's displayName remains whatever it was at subscribe time, or whatever the RSS fallback path last wrote (rare on InnerTube-success channels). A follow-up can extract the title from the InnerTube response if this becomes a noticeable regression.

## References

- Spec: `specs/017-innertube-channel-discover/spec.md`
- Plan: `specs/017-innertube-channel-discover/plan.md`
- Research: `specs/017-innertube-channel-discover/research.md`
- Contracts: `specs/017-innertube-channel-discover/contracts/discover-repository-contract.md`, `specs/017-innertube-channel-discover/contracts/youtube-browse-client-contract.md`
- ADR-0021: YouTube discovery via RSS — the original RSS-as-data-source decision; this ADR refines the data source without changing the cache semantics.
- ADR-0046: Discover feed cache is append-only — the cache contract preserved by the new InnerTube primary path.
- ADR-0036: Bilingual transcripts — establishes the InnerTube posture for the caption fetcher; this ADR extends it to channel refresh.
- Feature documentation: `docs/features/discover.md`
- Implementation:
  - `lib/features/discover/data/youtube_browse_client.dart` (new)
  - `lib/features/discover/data/discover_repository.dart` (`_refreshChannel`, `_refreshChannelGuarded`)
  - `lib/features/transcript/data/client_profile.dart` (`web` built-in)
  - `test/features/discover/youtube_browse_client_test.dart` (new)
  - `test/features/discover/discover_repository_test.dart` (extended)

## Implementation notes

- Profile rotation order lives in `kBrowsePreferredProfileOrder` (`youtube_browse_client.dart`). To add another profile (e.g., `TVHTML5_SIMPLY_EMBEDDED_PLAYER` once a working version is identified), append its `ClientProfile.name` to that list.
- Page cap (`kBrowseMaxPages = 5`) and per-page entry count estimate (`_kBrowsePageSizeEstimate`) are documented in `specs/017-innertube-channel-discover/data-model.md`. Adjust there when raising the per-channel InnerTube budget.
- `_persistBrowseOutcome` (`discover_repository.dart`) is the single place that converts `BrowseVideoEntry` projections to `YoutubeFeedEntryRow` upserts. Changes to InnerTube renderer names should be absorbed here, not at the call site.
