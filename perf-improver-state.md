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

**Status 2026-07-23**: All CI gates verified on Linux AWF sandbox:
- `dart format` — clean
- `flutter analyze` — 0 issues
- `flutter test` — 1707 passed, 2 skipped
- `check_codegen_drift.sh` — clean

Flutter SDK at `/opt/hostedtoolcache/flutter-3.44.0-stable/` is read-only overlayfs. Workaround: writable copy at `/tmp/gh-aw/agent/flutter_copy` with patched `shared.sh` + `update_engine_version.sh` that skips engine stamp writes. Hybrid artifact directory copies writable `engine/common/` and symlinks the rest. Packages directory fully copied (83 MB). Pub cache at `/tmp/gh-aw/agent/pub_cache` (set `PUB_CACHE` env var).

## Optimization Backlog — Remaining

1. **Incremental AI response streaming** — issue #310; user-facing latency opportunity. Awaiting maintainer decision.
2. **Artwork palette off main isolate** (`lib/core/theme/dynamic_color/artwork_palette.dart`) — `palette_generator` 0.3.x has no isolate-safe API; needs maintainer sign-off for major bump or hand-rolled quantiser. **Deferred.**
3. **Dictations DAO** — `DictationDao.watchByTarget` has no consumer in `lib/` today (only generated `.g.dart` references it). When hooked up, needs `.distinctBy(equals)`.
4. **JSON decode concurrency audit** — `_decodeResponseBody` uses `compute()` for >48 KB. Threshold correct as-is.
5. **Stream long-form ASR media instead of materializing bytes** — >=15-minute path materializes entire extracted audio into Uint8List/AsrRequest; 500 MiB extractor ceiling. Needs peak-RSS baseline first.
6. **Microbenchmark harness** — ✅ `test/perf/` directory created (2026-07-23). Two microbenchmarks added. CI regression job remains future work. Guide (`docs/perf-measurement.md`) updated.

## Optimization Backlog — Addressed

- ✅ **Microbenchmark harness** (2026-07-23) — `test/perf/` directory with `subtitle_parsing_benchmark.dart` and `case_conversion_benchmark.dart`. PR created.
- ✅ **Coalesce overlapping Discover refreshes** (2026-07-22) — Single-flight guard `DiscoverRefreshState._pendingRefresh` already implemented in `main` at `discover_providers.dart:149-176`. Two structural tests in `discover_refresh_single_flight_test.dart`. Previous draft from 2026-07-20 appears to have been merged by maintainer.
- ✅ **Measurement infrastructure guide** — `docs/perf-measurement.md` created (2026-07-21). Documents 4 structural perf test patterns, per-layer measurement strategies, and microbenchmark template. Draft PR on `perf-assist/measurement-infra-guide-2026-07-21`.
- ✅ PR #56/#64/#65/#79/#137/#150 — media library, discover, recordings, transcript, grid stable keys (June 2026).
- ✅ PR #188 (2026-07-02) — artwork palette LRU on `(path, size, mtime)`.
- ✅ PR #208+#238 (2026-07-07) — `TranscriptTrack` `==`/`hashCode` + `.distinctBy(_listEqualsTranscriptTrack)` in `TranscriptRepository.watchTracks`. Closes #219.
- ✅ PR #291 (2026-07-11) — `PlaybackSession`/`EchoState` equality; single shared `rawEnginePositionStreamProvider`; `.select(...)` on every chrome provider; `PlayerInteractions._lines()` cached.
- ✅ PR #335 (2026-07-13) — DiscoverRepository._avatarUrlCache` swapped onto shared `L1Store<K, V>`; 6h TTL; ~10 lines removed; 3 new unit tests.
- ✅ PR #360 (2026-07-17) — `YoutubeFeedEntryDao.upsertEntries(List<row>)` via `batch((b) => b.insertAll(...))`. Merged.

## Measurement infrastructure status

- 3 structural perf tests: `transcript_blur_long_list_perf_test.dart`, `discover_dedupe_test.dart`, `discover_refresh_single_flight_test.dart`.
- `test/perf/` directory (created 2026-07-23): `subtitle_parsing_benchmark.dart`, `case_conversion_benchmark.dart`.
- `docs/perf-measurement.md` (2026-07-21) documents 4 perf test patterns, per-layer strategies, microbenchmark template, and CI regression recommendations.
- No CI perf-regression job yet.

## Run History (last 8)

- **2026-07-23** 18:40 UTC — run 30031975736. Created `test/perf/` microbenchmark directory with SRT/VTT parsing and case-conversion benchmarks. Updated `docs/perf-measurement.md`. PR: `perf-assist/microbenchmark-harness-2026-07-23`.
- **2026-07-22** 18:25 UTC — run 29944478627. Audited Discover refresh — single-flight already implemented. Verified all CI gates on Linux AWF. Updated backlog: #6 (Discover coalescing) moved to ✅ Addressed. Updated memory + monthly summary.
- **2026-07-21** 14:00 UTC — run 29855434099. Created `docs/perf-measurement.md` — structural perf test patterns guide. Draft PR: `perf-assist/measurement-infra-guide-2026-07-21`.
- **2026-07-20** 18:46 UTC — run 29769067276. Drafted single-flight guard for DiscoverRefreshState.refresh(). 2 structural tests. (Worktree-local, not pushed.)
- **2026-07-20** 04:39 UTC — run 29690257927. Audited v0.7.0 code, identified discover refresh single-flight as candidate. Measurement inventory: 286 tests, 1 perf-named test.
- **2026-07-17** 12:00 UTC — run 29587195118. Verification only. PR #360 merged. Backlog audited.
- **2026-07-15** 14:57 UTC — run 29423417496. Drafted batched feed entry upsert. 3 structural tests.
- **2026-07-14** 15:23 UTC — run 29340890900. Investigation. Regex caching microbenchmarked (1.302x, deprioritized). Created #355.

## Per-run safe-output checklist

Always update issue #189 (monthly summary) with a new Run History entry. Use `update_issue` with `replace` operation. Update memory. Use `noop` only if no actions were taken.
