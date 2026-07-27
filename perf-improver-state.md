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

**Status 2026-07-27**: All CI gates verified on Linux AWF sandbox:
- `dart format` — clean (touched files)
- `flutter analyze` — 0 issues
- `flutter test` — 5034 passed, 2 skipped
- `check_codegen_drift.sh` — clean

Flutter SDK at `/opt/hostedtoolcache/flutter-3.44.0-stable/` is read-only overlayfs. Workaround: writable copy at `/tmp/gh-aw/agent/flutter_copy` (made via `cp -rL`). Pub cache at `/tmp/gh-aw/agent/pub_cache` (set `PUB_CACHE` env var). `dart format` is invoked through the writable Flutter copy's `dart-sdk/bin/dart`.

## Optimization Backlog — Remaining

1. **Incremental AI response streaming** — issue #310; user-facing latency opportunity. Repo Assist laid out a 4-step phased plan in a 2026-07-13 reply. Awaiting maintainer decision.
2. **Artwork palette off main isolate** (`lib/core/theme/dynamic_color/artwork_palette.dart`) — `palette_generator` 0.3.x has no isolate-safe API; needs maintainer sign-off for major bump or hand-rolled quantiser. **Deferred.**
3. **Dictations DAO** — `DictationDao.watchByTarget` has no consumer in `lib/` today (only generated `.g.dart` references it). When hooked up, needs `.distinctBy(equals)`.
4. **JSON decode concurrency audit** — `_decodeResponseBody` uses `compute()` for >48 KB. Threshold correct as-is.
5. **Stream long-form ASR media instead of materializing bytes** — >=15-minute path materializes entire extracted audio into Uint8List/AsrRequest; 500 MiB extractor ceiling. Needs peak-RSS baseline first.
   - **Investigation 2026-07-24**: Audio is extracted via FFmpeg→temp WAV→`out.readAsBytes()`→`AsrRequest.audioBytes`→HTTP PUT. Three 500 MiB checkpoints in `asr_audio_extractor.dart`. No `Stream`/`StreamedResponse`/chunked upload anywhere in the ASR pipe. Potential optimization: pipe FFmpeg stdout→HTTP upload body, skip the `Uint8List` materialization. Requires changes to `AsrRequest`, `AsrAudioExtractor`, `ApiClient.putBytesJson`, and `AsrMediaUploadApi`. Risk: high (architectural, touches 3 providers, error-handling surface). Recommended first step: add a `test/perf/asr_peak_rss_benchmark.dart` measuring peak RSS for 5/50/250 MiB synthetic WAV files via the current path, and optionally via a streaming pipe prototype.
6. **Microbenchmark harness** — `test/perf/` directory creation deferred again this run (2026-07-27). Investigation-only benchmarks were written and then removed to keep the equality PR focused. Docs (`docs/perf-measurement.md`) merged as PR #422.
7. **Sync queue watchSnapshot — SQL aggregate** — investigated 2026-07-27 and **reverted**:
   - Tried `SUM(CASE WHEN retryCount < 5 THEN 1 ELSE 0 END)` aggregate for counts + `ORDER BY created_at ASC LIMIT 50` for detail (via `idx_sync_queue_retry_created`).
   - Benchmarked at 1000 rows: raw watch ~1045 µs, aggregate ~67 µs, limited ~184 µs.
   - The watch itself is O(N) DB I/O. Two extra queries added ~280 µs per call vs. the in-Dart sort+slice baseline ~1350 µs.
   - Hybrid (watch keeps rows for counts; SQL for top 50 detail) is also a slight wall-clock regression for moderate queues.
   - Scales better at > 10K rows but slightly slower at < 1K rows — not worth the trade-off without a profiling signal that large queues are common.

## Optimization Backlog — Addressed

- ✅ **SyncQueueSnapshot equality** (2026-07-27) — Pinned `==` / `hashCode` on `SyncQueueSnapshot` so Riverpod skips rebuilds when a Drift re-emit doesn't change the visible state. PR: `perf-assist/sync-queue-snapshot-sql-aggregate-2026-07-27`. 3 structural tests.
- ✅ **Microbenchmark harness docs** (2026-07-21) — `docs/perf-measurement.md` merged as PR #422.
- ✅ **Coalesce overlapping Discover refreshes** (2026-07-22) — Single-flight guard `DiscoverRefreshState._pendingRefresh` already implemented in `main` at `discover_providers.dart:149-176`.
- ✅ PR #56/#64/#65/#79/#137/#150 — media library, discover, recordings, transcript, grid stable keys (June 2026).
- ✅ PR #188 (2026-07-02) — artwork palette LRU on `(path, size, mtime)`.
- ✅ PR #208+#238 (2026-07-07) — `TranscriptTrack` `==`/`hashCode` + `.distinctBy(_listEqualsTranscriptTrack)` in `TranscriptRepository.watchTracks`. Closes #219.
- ✅ PR #291 (2026-07-11) — `PlaybackSession`/`EchoState` equality; single shared `rawEnginePositionStreamProvider`; `.select(...)` on every chrome provider; `PlayerInteractions._lines()` cached.
- ✅ PR #335 (2026-07-13) — DiscoverRepository._avatarUrlCache` swapped onto shared `L1Store<K, V>`; 6h TTL; ~10 lines removed; 3 new unit tests.
- ✅ PR #360 (2026-07-17) — `YoutubeFeedEntryDao.upsertEntries(List<row>)` via `batch((b) => b.insertAll(...))`. Merged.

## Measurement infrastructure status

- 3+ structural perf tests: `transcript_blur_long_list_perf_test.dart`, `discover_dedupe_test.dart`, `discover_refresh_single_flight_test.dart`, plus new `sync_queue_repository_test.dart` detail-ordering + equality tests (2026-07-27).
- `test/perf/` directory: not on main as of 2026-07-27. Benchmarks live as investigation artifacts; not yet ready to be committed alongside code change.
- `docs/perf-measurement.md` (2026-07-21) documents 4 perf test patterns, per-layer strategies, microbenchmark template, and CI regression recommendations. Merged as PR #422.
- No CI perf-regression job yet.

## Run History (last 9)

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

Always update issue #189 (monthly summary) with a new Run History entry. Use `update_issue` with `replace` operation. Update memory. Use `noop` only if no actions were taken.
