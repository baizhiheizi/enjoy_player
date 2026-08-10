---
name: perf-improver-state
description: Perf Improver persistent state — discovered commands, opportunities backlog, run history
metadata:
  type: project
---

# Perf Improver — State

## Discovered Commands

CI pinned in `.github/workflows/ci.yml`; Flutter version in `.github/flutter-version` (currently `3.44.0`).

```bash
flutter pub get
bash .github/scripts/check_dart_format.sh   # or --fix
bash .github/scripts/check_codegen_drift.sh
flutter analyze
flutter test
# Path packages: (cd packages/<name> && flutter pub get && flutter test)
```

**Status 2026-08-10**: All CI gates verified on Linux AWF sandbox:
- `dart format` — clean
- `flutter analyze` — 4 pre-existing `collapseWhitespace` ambiguous-import errors in `test/core/utils/text_normalization_test.dart` (PR #539); unrelated to perf work
- `flutter test` — vocabulary: 434 passed, sync: 213 passed, full suite: 5264 passed, 50 failed, 2 skipped
- `check_codegen_drift.sh` — clean
- The 50 failures are all pre-existing on `main` (verified by stashing changes and running the same test files against `main` directly). The transcript_scrollable_list_test failures (3) and other failures are unrelated to perf work.

Flutter SDK at `/opt/hostedtoolcache/flutter-3.44.0-stable/` is read-only overlayfs. Workaround: writable copy at `/tmp/gh-aw/agent/flutter_copy` (made via `cp -rL`). Pub cache at `/tmp/gh-aw/agent/pub_cache` (set `PUB_CACHE` env var). `dart format` is invoked through the writable Flutter copy's `dart-sdk/bin/dart`.

## Optimization Backlog — Remaining

1. **Incremental AI response streaming** — issue #310; user-facing latency opportunity. Repo Assist laid out a 4-step phased plan in a 2026-07-13 reply. Awaiting maintainer decision.
2. **Artwork palette off main isolate** (`lib/core/theme/dynamic_color/artwork_palette.dart`) — `palette_generator` 0.3.x has no isolate-safe API; needs maintainer sign-off for major bump or hand-rolled quantiser. **Deferred.**
3. **Stream long-form ASR media instead of materializing bytes** — >=15-minute path materializes entire extracted audio into Uint8List/AsrRequest; 500 MiB extractor ceiling. Needs peak-RSS baseline first.
4. **Distinct vocabulary items stream** — `vocabularyItemsProvider` re-emits a new `List<VocabularyItem>` on every Drift change. Now that `VocabularyItem` has field-by-field equality, a future `.distinct(equals)` on the stream would dedupe structurally identical lists and skip downstream consumer re-runs. Candidate for a follow-up PR after the equality PR lands.
5. **CI microbenchmark smoke job** — `test/perf/` directory was created in an earlier draft PR but not merged. A job running `flutter test test/perf/` would catch regressions on hot paths.

## Optimization Backlog — Addressed

- ✅ **VocabularyItem / VocabularyContext equality** (2026-08-10) — pinned field-by-field `==` / `hashCode` on both types. Branch `perf-assist/vocabulary-value-equality-2026-08-10`. 9 structural tests. Follows the same pattern as PRs #188, #208, #238, #291, and the recent `SyncQueueSnapshot` work.
- ✅ **SyncQueueSnapshot equality** (2026-07-27) — Pinned `==` / `hashCode` on `SyncQueueSnapshot`. 3 structural tests.
- ✅ **Microbenchmark harness docs** (2026-07-21) — `docs/perf-measurement.md` merged as PR #422.
- ✅ **Coalesce overlapping Discover refreshes** (2026-07-22) — Single-flight guard `DiscoverRefreshState._pendingRefresh` already implemented in `main` at `discover_providers.dart:149-176`.
- ✅ PR #56/#64/#65/#79/#137/#150 — media library, discover, recordings, transcript, grid stable keys (June 2026).
- ✅ PR #188 (2026-07-02) — artwork palette LRU on `(path, size, mtime)`.
- ✅ PR #208+#238 (2026-07-07) — `TranscriptTrack` `==`/`hashCode` + `.distinctBy(_listEqualsTranscriptTrack)` in `TranscriptRepository.watchTracks`. Closes #219.
- ✅ PR #291 (2026-07-11) — `PlaybackSession`/`EchoState` equality; single shared `rawEnginePositionStreamProvider`; `.select(...)` on every chrome provider; `PlayerInteractions._lines()` cached.
- ✅ PR #335 (2026-07-13) — DiscoverRepository._avatarUrlCache` swapped onto shared `L1Store<K, V>`; 6h TTL.
- ✅ PR #360 (2026-07-17) — `YoutubeFeedEntryDao.upsertEntries(List<row>)` via `batch((b) => b.insertAll(...))`. Merged.
- ✅ PR #504 (2026-07-30) — `perf: hoist regex allocations, scope MediaQuery dep, cache per-locale DateFormat`.
- ✅ PR #499 (2026-07-28) — `perf(player): scope two transport-bar / surface-host rebuilds`.
- ✅ PR #526 (2026-08-05) — `perf(image-cache): swap remaining Image.network for CachedNetworkImageProvider`.

## Measurement infrastructure status

- 3+ structural perf tests: `transcript_blur_long_list_perf_test.dart`, `discover_dedupe_test.dart`, `discover_refresh_single_flight_test.dart`, plus `vocabulary_value_equality_test.dart` (2026-08-10).
- `test/perf/` directory: not on main as of 2026-08-10.
- `docs/perf-measurement.md` (2026-07-21) documents 4 perf test patterns, per-layer strategies, microbenchmark template, and CI regression recommendations. Merged as PR #422.
- No CI perf-regression job yet.

## Run History (last 10)

- **2026-08-10** 17:40 UTC — run 31415106711. Pinned field-by-field `==` / `hashCode` on `VocabularyItem` (16 fields) and `VocabularyContext` (12 fields). 9 structural tests. Branch `perf-assist/vocabulary-value-equality-2026-08-10`. Pre-existing CI failures on main confirmed unrelated.
- **2026-07-27** 18:30 UTC — run 30292923202. Pinned `SyncQueueSnapshot.==` / `hashCode` so Riverpod skips UI rebuilds when Drift re-emit doesn't change the visible state. 3 structural tests. Draft PR: `perf-assist/sync-queue-snapshot-sql-aggregate-2026-07-27`. Investigated SQL aggregate for `watchSnapshot` (counts + detail) and reverted — slight wall-clock regression at 1000 rows because the watch itself dominates. Memory + monthly summary updated.
- **2026-07-24** 18:10 UTC — run 30115609598. Investigated backlog item #5 (ASR streaming): full architecture audit of `asr_audio_extractor.dart`, `AsrRequest`, `ApiClient`, and all 3 provider capability paths. Documented peak-RSS measurement strategy. Updated memory + monthly summary.
- **2026-07-23** 18:40 UTC — run 30031975736. Created `test/perf/` microbenchmark directory with SRT/VTT parsing and case-conversion benchmarks. Updated `docs/perf-measurement.md`. PR: `perf-assist/microbenchmark-harness-2026-07-23`.
- **2026-07-22** 18:25 UTC — run 29944478627. Audited Discover refresh — single-flight already implemented. Verified all CI gates on Linux AWF. Updated backlog: #6 (Discover coalescing) moved to ✅ Addressed. Updated memory + monthly summary.
- **2026-07-21** 14:00 UTC — run 29855434099. Created `docs/perf-measurement.md` — structural perf test patterns guide. Draft PR: `perf-assist/measurement-infra-guide-2026-07-21`.
- **2026-07-20** 18:46 UTC — run 29769067276. Drafted single-flight guard for DiscoverRefreshState.refresh(). 2 structural tests. (Worktree-local, not pushed.)
- **2026-07-20** 04:39 UTC — run 29690257927. Audited v0.7.0 code, identified discover refresh single-flight as candidate. Measurement inventory: 286 tests, 1 perf-named test.
- **2026-07-17** 12:00 UTC — run 29587195118. Verification only. PR #360 merged. Backlog audited.
- **2026-07-15** 14:57 UTC — run 29423417496. Drafted batched feed entry upsert. 3 structural tests.

## Per-run safe-output checklist

Always create/update the `[perf-improver] Monthly Activity YYYY-MM` issue with a new Run History entry. Create new issue when the previous month's is closed. Use `noop` only if no actions were taken.
