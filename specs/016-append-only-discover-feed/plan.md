# Implementation Plan: Discover Feed Append-Only Persistence

**Branch**: `016-append-only-discover-feed` | **Date**: 2026-07-13 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/016-append-only-discover-feed/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Replace the current "wipe and rewrite" behavior of `DiscoverRepository._refreshChannel` with an append-only upsert. The local `youtube_feed_entries` cache must accumulate uploads across refreshes rather than being truncated to whatever subset the latest YouTube RSS response contains. Unsubscribing from a channel continues to delete its cached entries, and failed refreshes must leave the cache and `lastFetchedAt` untouched. The user-visible effect is that a subscribed channel's Discover feed now grows monotonically over time, matching the behavior of a conventional feed reader.

## Technical Context

**Language/Version**: Dart `^3.12.0` (per `pubspec.yaml` `environment.sdk`). Flutter stable (channel pinned by `flutter` SDK in the repo). No Dart version bump is required for this refactor.

**Primary Dependencies** (already in `pubspec.yaml`, none added by this refactor):

- `drift ^2.31.0` + `drift_flutter ^0.2.8` — `AppDatabase`, `YoutubeFeedEntryDao`, `YoutubeChannelSubscriptionDao`.
- `flutter_riverpod ^3.3.1` + `riverpod_annotation` — providers (`discoverRepositoryProvider`, `discoverSubscriptionsProvider`, `discoverTimelineProvider`, `discoverChannelFeedProvider`, `discoverRefreshStateProvider`, `DiscoverFeedRefreshScheduler`).
- `logging ^1.3.0` — used through `lib/core/logging/log.dart`'s `logNamed` for the `discover.repository` channel.
- `http ^1.4.0` — `YoutubeFetch.getRss` (unchanged).
- `go_router ^17.2.3` — `/discover/channel/:channelId` route (unchanged).

No new dependencies are introduced. No Drift schema change is required (column set stays the same; only the runtime refresh path changes), so `dart run build_runner build` is not needed unless the implementation introduces a new annotation that requires generated code.

**Storage**: Local Drift `AppDatabase` (per-user `enjoy_player_<userId>.sqlite`, ADR-0012). Two tables are involved:

- `youtube_channel_subscriptions` (Drift table, PK `channelId`) — unchanged.
- `youtube_feed_entries` (Drift table, PK `(videoId, channelId)`) — schema unchanged; only the refresh path's write/delete semantics change.

**Testing**: `flutter test` is the primary gate. The change must add unit tests under `test/features/discover/` covering (a) cache grows on new entries, (b) cache preserved when RSS omits entries, (c) refresh idempotency on identical RSS responses, (d) unsubscribe clears the channel's cache, (e) failed refresh leaves cache and `lastFetchedAt` untouched. The existing `discover_repository_test.dart` and `discover_dedupe_test.dart` may need updates if they assert stale-entry deletion (per spec QR-002 + SC-007).

**Target Platform**: Android, iOS, macOS, Windows, Linux (Flutter web is out of scope per ADR-0044 and the constitution). No platform-specific code; the change is in pure Dart.

**Project Type**: Flutter native mobile/desktop app.

**Performance Goals**:

- Discover timeline (`watchTimeline`) and channel feed (`watchChannelFeed`) must render first paint in under 200 ms with up to **500 cached entries per channel**, leveraging the existing `ValueKey` + `findChildIndexCallback` pattern documented in `docs/features/discover.md`.
- Per-channel RSS refresh RTT budget unchanged (≤ 4 concurrent refreshes, ≤ 4 concurrent duration enrichments).
- No new work added to the refresh hot path; the work *removed* is the `deleteStaleForChannel` call plus its surrounding `keepVideoIds` set construction, and the now-dead DAO helper itself is deleted from `YoutubeFeedEntryDao`.

**Constraints**:

- Local-first; the cache must remain usable offline (no required network calls to render existing entries).
- The refresh path must remain idempotent: re-fetching the same RSS payload must not change the cache state.
- Failed refreshes must not write to the cache or to `lastFetchedAt` — they must report through `DiscoverRefreshResult.failedChannelIds` exactly as today.
- No `print()` calls; logging must go through `logNamed('discover.repository')`.
- No new mutable global singletons; orchestration stays on the existing `DiscoverRepository` singleton via the `discoverRepositoryProvider`.

**Scale/Scope**:

- Typical user: ≤ 20 subscriptions, each up to a few hundred cached entries over time.
- Worst case considered: 20 subscriptions × 500 cached entries = 10 000 rows in `youtube_feed_entries`. No pagination, virtual scrolling, or other deferred-load work is required for v1 — the sliver performance pattern is sufficient at this scale.
- Diagnostics / counters that already report `youtube_feed_entries` row counts must continue to work; only the row count interpretation shifts (it now reflects history, not just "latest snapshot").

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Architecture and Code Quality

- **PASS** — Changes stay inside `lib/features/discover/data/discover_repository.dart` and the test files under `test/features/discover/`. No cross-feature shortcuts. Domain model `FeedEntry` is unchanged; persistence flows through the existing Drift DAO. Riverpod providers are reused unchanged.
- **PASS** — No new mutable global singleton; the existing `discoverRepositoryProvider` (singleton via `keepAlive: true`) is the single owner of refresh orchestration.
- **PASS** — No `media_kit` `Player()` construction and no `print()` calls touched.
- **PASS** — `lib/core` and `lib/data` paths are not affected.

### II. Testing Defines the Contract

- **PASS** — New unit tests are added in `test/features/discover/` covering the append-only behavior matrix (see Testing section above).
- **PASS** — Existing tests (`discover_repository_test.dart`, `discover_dedupe_test.dart`) are reviewed and updated/retired as needed per SC-007.
- **PASS** — No Drift or Riverpod annotation is added, so `dart run build_runner build` is not required. (Confirmed against the project's annotation surface: `YoutubeFeedEntries` and `YoutubeChannelSubscriptions` tables are unchanged.)
- **N/A** — No widget/integration coverage required; the bug and fix are pure repository-layer behavior. Manual verification on each platform is documented in `quickstart.md` if needed.

### III. User Experience Consistency

- **PASS** — No new user-facing strings; the existing ARB strings (`discoverFeedEmptyTitle`, `discoverFeedEmptyHint`, `discoverFeedErrorTitle`, `discoverFeedErrorHint`, `discoverRefreshSingleFailed`, `discoverRefreshPartialFailedDetail`, etc.) cover the surface. The empty-state copy is reused as-is for newly-empty channels (the moment between subscribe and first refresh).
- **PASS** — Tappable controls (`Manage channels`, `Unsubscribe`, pull-to-refresh, header refresh button) are unchanged.
- **PASS** — `docs/features/discover.md` (specifically the "Feed refresh", "Limitations", and "Sliver performance" sections) MUST be updated to reflect the new "append-only" semantics.

### IV. Performance Is a Requirement

- **PASS** — Per the Performance Goals section: ≤ 200 ms first paint with 500 cached entries per channel; the existing sliver pattern (`ValueKey<String>('discover-feed-<videoId>')` + `findChildIndexCallback`) is the documented mechanism. No new build-method work, no per-item computation added.
- **PASS** — The refresh path does *less* work after the fix (no `keepVideoIds` set construction, no DELETE statement). Existing per-channel concurrency (4-way `Future.wait`) and per-entry enrichment (4-way counting semaphore) are preserved.
- **PASS** — Diagnostics must still report cache size; the Drift `count()` query it already runs is unaffected.

### V. Documentation and Traceability

- **PASS** — A new ADR under `docs/decisions/` is required (per QR-006) to record why the cache is now append-only and supersede any earlier wording in ADR-0021 that implies a full-replace refresh.
- **PASS** — `docs/features/discover.md` MUST be updated to:
  - Clarify that `lastFetchedAt` is now the "last time the source re-presented this entry" timestamp.
  - Clarify that the cache is append-only between unsubscribe events.
  - Drop or rephrase any wording that suggests the refresh "rewrites" or "replaces" the cache (e.g., the existing "Sliver performance" paragraph is still correct but should reference append-only semantics).
- **PASS** — No constitution exception is needed; the refactor strengthens rather than weakens each principle.

## Project Structure

### Documentation (this feature)

```text
specs/016-append-only-discover-feed/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
├── checklists/
│   └── requirements.md  # Already produced by /speckit.specify
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── features/discover/
│   ├── application/
│   │   └── discover_providers.dart        # Unchanged
│   ├── data/
│   │   ├── discover_repository.dart       # EDIT: remove deleteStaleForChannel call in _refreshChannel
│   │   ├── youtube_rss_parser.dart        # Unchanged
│   │   ├── youtube_fetch.dart             # Unchanged
│   │   └── youtube_video_duration.dart    # Unchanged
│   ├── domain/
│   │   ├── feed_entry.dart                # Unchanged
│   │   └── discover_channel.dart          # Unchanged
│   └── presentation/
│       ├── channel_feed_screen.dart       # Unchanged
│       └── discover_screen.dart           # Unchanged
├── data/db/
│   ├── app_database.dart                  # EDIT: remove dead YoutubeFeedEntryDao.deleteStaleForChannel
│   └── tables/youtube_feed_entries.dart   # Unchanged
└── core/                                  # Unchanged

test/
├── features/discover/
│   ├── discover_repository_test.dart      # EDIT/EXTEND: add append-only assertions
│   ├── discover_dedupe_test.dart          # EDIT/EXTEND: add cache-preservation scenarios
│   ├── discover_subscribe_actions_test.dart   # Unchanged
│   └── discover_subscribe_sheet_test.dart     # Unchanged
├── data/db/                               # Unchanged
└── widget_test.dart                       # Unchanged

docs/
├── features/discover.md                   # EDIT: refresh + limitations copy
└── decisions/0046-discover-feed-append-only.md   # NEW: ADR for the cache semantics change
```

**Structure Decision**: This refactor is contained to a single Drift-backed repository (`discover_repository.dart`), its DAO callers, its tests, and its documentation. No new directories are introduced under `lib/`; no new external contracts are introduced under `contracts/` (the spec scope is internal persistence behavior — see `contracts/README.md` once written). The ADR follows the project's `docs/decisions/NNNN-short-title.md` naming convention; the next available number is `0046` (the most recent ADRs are `0045-ai-result-cache-hierarchy.md` and `0048-linux-platform-support.md`; originally filed as `0044-linux-platform-support.md`).

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| _None_ | _No principle is violated._ | _N/A_ |