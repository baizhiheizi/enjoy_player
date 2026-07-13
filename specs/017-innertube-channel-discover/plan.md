# Implementation Plan: InnerTube Channel Discover

**Branch**: `017-innertube-channel-discover` | **Date**: 2026-07-13 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/017-innertube-channel-discover/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Re-platform the per-channel refresh in `DiscoverRepository._refreshChannel` so it tries the InnerTube `browse` endpoint first and falls back to the legacy Atom RSS path when the primary source fails or returns an unparseable shape. The append-only cache contract from ADR-0046, the 1 h cooldown / 8 h lifecycle-gated timer / 4-way concurrency contract from ADR-0021, and the existing client-profile rotation pipeline (already in use by the YouTube caption fetcher) are preserved. The InnerTube response supplies per-video metadata that today is filled by a second pass (`lengthText`, `viewCountText`, `publishedTimeText`); when the primary path succeeds, the watch-page HTML duration enrichment is skipped for that entry. The `YoutubeFeedEntries` schema is unchanged. Playlist import (`https://youtube.com/playlist?list=…`) is **explicitly deferred** to a follow-up spec per FR-013.

## Technical Context

**Language/Version**: Dart `^3.12.0` (per `pubspec.yaml` `environment.sdk`). Flutter stable channel pinned by the repo's `flutter` SDK. No Dart version bump is required.

**Primary Dependencies** (already in `pubspec.yaml`, none added by this plan):

- `drift ^2.31.0` + `drift_flutter ^0.2.8` — `AppDatabase`, `YoutubeFeedEntryDao`, `YoutubeChannelSubscriptionDao` (unchanged).
- `flutter_riverpod ^3.3.1` + `riverpod_annotation` — providers (unchanged).
- `logging ^1.3.0` — used through `lib/core/logging/log.dart`'s `logNamed` for the `discover.repository` and a new `discover.browse` channel.
- `http ^1.4.0` — `YoutubeFetch.getRss` (legacy fallback, unchanged) and the new `YoutubeBrowseClient.post` (InnerTube `browse`).

No new dependencies are introduced. No Drift schema change is required — `YoutubeFeedEntries.durationSeconds` is already nullable, so InnerTube-supplied durations can be persisted on the same row; no codegen drift, no migration.

**Storage**: Local Drift `AppDatabase` (per-user `enjoy_player_<userId>.sqlite`, ADR-0012). Two tables are involved, both unchanged:

- `youtube_channel_subscriptions` (Drift table, PK `channelId`) — unchanged.
- `youtube_feed_entries` (Drift table, PK `(videoId, channelId)`) — schema unchanged; the refresh path now writes `durationSeconds` from the InnerTube response when available.

**Testing**: `flutter test` is the primary gate. New and updated unit tests must live under `test/features/discover/`:

- `youtube_browse_client_test.dart` (new) — response parsing for `richItemRenderer` → `videoRenderer`, continuation token extraction, pagination loop termination, empty-page handling, malformed-response handling.
- `discover_repository_test.dart` (extend) — primary-success path writes InnerTube rows with `durationSeconds`; primary-failure falls back to RSS and writes the legacy payload; primary partial-shape (missing `lengthText`/`viewCountText`) still writes rows; failed refresh on both sources leaves cache + `lastFetchedAt` untouched; cooldown skip; profile rotation: profile A 401 → profile B retries → RSS fallback.
- `discover_dedupe_test.dart` — unchanged (dedupe via `distinctBy(_listEqualsFeedEntry)` is independent of source).

No widget/integration tests are required; the change is a repository-layer data-source swap with documented observable behavior. Manual verification is described in `quickstart.md`.

**Target Platform**: Android, iOS, macOS, Windows, Linux (Flutter web is out of scope per ADR-0044 and the constitution). No platform-specific code; `package:http` already supports all targets.

**Project Type**: Flutter native mobile/desktop app.

**Performance Goals** (per spec SC-003, QR-004):

- A 20-channel refresh tick with both sources healthy MUST complete within ≤ 2× the current baseline wall-clock budget.
- A 20-channel refresh tick with both sources healthy MUST issue fewer total HTTP requests than the legacy RSS + watch-page enrichment path (≤ 60% of the legacy request count).
- Discover timeline (`watchTimeline`) and per-channel feed (`watchChannelFeed`) MUST render first paint in under 200 ms with up to 500 cached entries per channel, leveraging the existing `ValueKey` + `findChildIndexCallback` sliver pattern documented in `docs/features/discover.md`.
- Per-channel InnerTube request: typical 1 POST for ~30 entries; up to N POSTs for very active channels (continuation pagination). Wall-clock for one channel is bounded by the existing 4-way `_kRefreshChannelConcurrency` cap.

**Constraints**:

- Local-first; the cache must remain usable offline (no required network calls to render existing entries).
- The refresh path must remain idempotent: re-running with an unchanged source returns the same cache state (upsert by `(channelId, videoId)`).
- Failed refreshes (InnerTube 401/403/5xx across all profiles + RSS bot-block + RSS non-200) MUST NOT write to the cache or to `lastFetchedAt`; they MUST report through `DiscoverRefreshResult.failedChannelIds` exactly as today.
- No `print()` calls; logging MUST go through `logNamed` (channels: `discover.repository`, `discover.browse`).
- No new mutable global singletons; orchestration stays on the existing `DiscoverRepository` instance via `discoverRepositoryProvider`.
- The new InnerTube path MUST participate in the existing client-profile rotation pipeline (same `ClientProfile` model + worker `GET /youtube/client-profiles` + 24 h cache fallback used by the YouTube caption fetcher).
- `YoutubeChannelResolver`'s HTML-scrape path for handle → `channel_id` resolution is unchanged in this plan.

**Scale/Scope**:

- Typical user: ≤ 20 subscriptions, each up to a few hundred cached entries over time (existing budget from ADR-0046 / QR-004).
- Worst case considered: 20 subscriptions × 500 cached entries = 10 000 rows in `youtube_feed_entries`. No pagination, virtual scrolling, or other deferred-load work is required for v1.
- InnerTube `browse` returns ~30 entries per page; active channels may need 2–4 pages to cover the recent window. The page cap (default: 5 pages / ~150 entries per channel) is enforced inside `YoutubeBrowseClient.fetchChannelVideos` to bound total wall-clock per channel.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Architecture and Code Quality

- **PASS** — Changes stay inside `lib/features/discover/data/` (`youtube_browse_client.dart` new; `discover_repository.dart` edit; tests under `test/features/discover/`). The InnerTube client profile is read from `lib/features/transcript/data/client_profile.dart` (which is already shared between caption and discovery consumers — same `ClientProfile` model, not a duplicate).
- **PASS** — Domain models (`FeedEntry`, `DiscoverChannel`) remain UI-free. The new `BrowseVideoEntry` projection lives in `lib/features/discover/data/youtube_browse_client.dart` and is internal to the repository — never crosses into presentation code.
- **PASS** — Persistence flows through the existing Drift DAO (`YoutubeFeedEntryDao.upsertEntry`, `updateDurationSeconds`). No raw SQL in feature code.
- **PASS** — Riverpod providers are reused unchanged (`discoverRepositoryProvider` is the single owner of refresh orchestration).
- **PASS** — No new mutable global singletons. The new `YoutubeBrowseClient` is constructed per-repository-instance (or shared via a constructor argument, mirroring `YoutubeRssParser` and `YoutubeFetch`).
- **PASS** — No `media_kit` `Player()` construction; no `print()` calls.
- **PASS** — `lib/core` and `lib/data` paths are not affected. The InnerTube profile plumbing reuses what the YouTube caption fetcher already uses (`lib/features/transcript/data/client_profile.dart`).

### II. Testing Defines the Contract

- **PASS** — New unit tests are added in `test/features/discover/youtube_browse_client_test.dart` (response parsing, continuation pagination, malformed-response, empty-page handling). `discover_repository_test.dart` is extended with the dual-source contract matrix (primary success, primary failure → RSS fallback, primary partial shape, dual failure preserves cache, cooldown skip, profile rotation).
- **PASS** — Existing tests (`discover_dedupe_test.dart`, `discover_subscribe_actions_test.dart`, `discover_subscribe_sheet_test.dart`) are not expected to need changes; their assertions are about cache projections and UI surfaces that are unaffected by the source swap.
- **PASS** — No Drift or Riverpod annotation is added, so `dart run build_runner build` is not required.
- **N/A** — No widget/integration coverage required; the change is a repository-layer data-source swap. Manual verification is documented in `quickstart.md`.

### III. User Experience Consistency

- **PASS** — No new user-facing strings are required. Durations and view counts start appearing on tiles that already render `FeedEntry` — the projection is widened, the ARB strings are not.
- **PASS** — Tappable controls (`Manage channels`, `Unsubscribe`, pull-to-refresh, header refresh button) are unchanged. The localized per-channel refresh error notice (e.g., `discoverRefreshSingleFailed`) is reused as-is for the dual-failure case.
- **PASS** — `docs/features/discover.md` MUST be updated to describe the dual-source posture, the InnerTube-supplied metadata (duration / view count), and the explicit playlist deferral note.
- **PASS** — The existing `ValueKey<String>('discover-feed-<videoId>')` sliver-keyed pattern is reused; no widget code is touched.

### IV. Performance Is a Requirement

- **PASS** — Performance budgets are explicit (SC-003 ≤ 2× baseline wall-clock, ≤ 60% of legacy request count, 200 ms first paint at 500 entries/channel). The 4-way `_kRefreshChannelConcurrency` cap is preserved; the per-channel page cap (default 5) bounds InnerTube pagination cost.
- **PASS** — The refresh path does **less** network work after the change (no per-entry watch-page HTML enrichment when InnerTube supplied the duration). The legacy duration enrichment is invoked only on the RSS fallback path, matching today's behavior on that branch.
- **PASS** — No expensive work added to `build` methods or list/grid item builders. The new `BrowseVideoEntry` projection is constructed inside the repository, not in widget code.

### V. Documentation and Traceability

- **PASS** — A new ADR `docs/decisions/0047-youtube-discover-innertube.md` MUST be added to record (a) the data-source change, (b) the InnerTube-primary + RSS-fallback posture, (c) the client-profile rotation contract reused from the caption fetcher, (d) the explicit playlist deferral.
- **PASS** — `docs/features/discover.md` MUST be updated to reflect the dual-source posture, the InnerTube-supplied metadata, the page-cap policy, and the playlist deferral note.
- **PASS** — No constitution exception is needed; the change strengthens rather than weakens each principle (the inner architecture is unchanged; the source surface becomes more reliable and richer).

## Project Structure

### Documentation (this feature)

```text
specs/017-innertube-channel-discover/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   ├── discover-repository-contract.md    # Phase 1 output
│   └── youtube-browse-client-contract.md  # Phase 1 output
├── checklists/
│   └── requirements.md  # Already produced by /speckit.specify
└── tasks.md             # Phase 2 output (/speckit-tasks - NOT produced by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── features/discover/
│   ├── application/
│   │   └── discover_providers.dart        # Unchanged
│   ├── data/
│   │   ├── discover_repository.dart       # EDIT: _refreshChannel tries InnerTube first, falls back to RSS; suppress _enrichMissingDurations when InnerTube supplied duration
│   │   ├── youtube_browse_client.dart     # NEW: InnerTube POST + response parser + continuation pagination
│   │   ├── youtube_rss_parser.dart        # Unchanged (legacy fallback)
│   │   ├── youtube_fetch.dart             # Unchanged (legacy fallback)
│   │   ├── youtube_video_duration.dart    # Unchanged (legacy fallback only)
│   │   └── youtube_channel_resolver.dart  # Unchanged
│   ├── domain/
│   │   ├── feed_entry.dart                # EDIT: project optional durationSeconds / viewCount (already nullable)
│   │   └── discover_channel.dart          # Unchanged
│   └── presentation/                       # Unchanged (existing sliver-keyed widgets)
├── features/transcript/
│   └── data/
│       └── client_profile.dart            # EDIT: add a WEB built-in client profile (alongside IOS / ANDROID_VR / MWEB)
└── core/                                  # Unchanged

test/
├── features/discover/
│   ├── youtube_browse_client_test.dart   # NEW: parser + continuation + malformed-response coverage
│   ├── discover_repository_test.dart      # EDIT/EXTEND: dual-source contract matrix
│   ├── discover_dedupe_test.dart          # Unchanged
│   ├── discover_subscribe_actions_test.dart   # Unchanged
│   └── discover_subscribe_sheet_test.dart     # Unchanged
└── data/db/                               # Unchanged

docs/
├── features/discover.md                   # EDIT: dual-source posture, InnerTube-supplied metadata, playlist deferral note
└── decisions/0047-youtube-discover-innertube.md   # NEW: ADR for the data-source change
```

**Structure Decision**: This change is contained to the Discover feature (one new collaborator file, one edited repository file, one edited shared client-profile file) plus its tests and documentation. The new `youtube_browse_client.dart` mirrors the shape and posture of the existing `youtube_caption_fetcher.dart` — anonymous InnerTube surface, profile rotation, `package:http` POST, no `media_kit`, no `kIsWeb`. The ADR follows the project's `docs/decisions/NNNN-short-title.md` naming convention; the next available number is `0047` (the most recent ADRs are `0046-discover-feed-append-only.md` and `0045-ai-result-cache-hierarchy.md`).

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| _None_ | _No principle is violated._ | _N/A_ |
