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

Local agentic SDK at `/opt/hostedtoolcache/flutter-3.44.0-stable` is read-only; `update_engine_version.sh` fails trying to write engine stamps. Rely on authoritative CI logs. Codegen: `dart run build_runner build` (or `bash .github/scripts/check_codegen_drift.sh --fix`).

## Optimization Backlog — Remaining

1. **Incremental AI response streaming** — issue #310; user-facing latency opportunity. Awaiting maintainer decision.
2. **Artwork palette off main isolate** (`lib/core/theme/dynamic_color/artwork_palette.dart`) — `palette_generator` 0.3.x has no isolate-safe API; needs maintainer sign-off for major bump or hand-rolled quantiser. **Deferred.**
3. **Dictations DAO** — `DictationDao.watchByTarget` has no consumer in `lib/` today (only generated `.g.dart` references it). When hooked up, needs `.distinctBy(equals)`.
4. **JSON decode concurrency audit** (`lib/data/api/api_client.dart`) — `_decodeResponseBody` uses `compute()` for >48 KB. Threshold correct as-is.
5. **Microbenchmark harness** — no `test/perf/` yet; structural tests cover Drift emission costs but no JIT microbenchmarks for hot regex/serialization paths.
6. **Stream long-form ASR media instead of materializing bytes** — >=15-minute path materializes entire extracted audio into Uint8List/AsrRequest; 500 MiB extractor ceiling. Needs peak-RSS baseline first.

## Optimization Backlog — Addressed

- ✅ **Coalesce overlapping Discover refreshes** — single-flight guard in `DiscoverRefreshState.refresh()`. Draft PR 2026-07-20. `_pendingRefresh` stores the in-flight future; concurrent callers share it.
- ✅ PR #56/#64/#65/#79/#137/#150 — media library, discover, recordings, transcript, grid stable keys (June 2026).
- ✅ PR #188 (2026-07-02) — artwork palette LRU on `(path, size, mtime)`.
- ✅ PR #208+#238 (2026-07-07) — `TranscriptTrack` `==`/`hashCode` + `.distinctBy(_listEqualsTranscriptTrack)` in `TranscriptRepository.watchTracks`. Closes #219.
- ✅ PR #291 (2026-07-11) — `PlaybackSession`/`EchoState` equality; single shared `rawEnginePositionStreamProvider`; `.select(...)` on every chrome provider; `PlayerInteractions._lines()` cached.
- ✅ PR #335 (2026-07-13) — DiscoverRepository._avatarUrlCache` swapped onto shared `L1Store<K, V>`; 6h TTL; ~10 lines removed; 3 new unit tests.
- ✅ PR #360 (2026-07-17, commit `ce9f38b`) — `YoutubeFeedEntryDao.upsertEntries(List<row>)` via `batch((b) => b.insertAll(...))`. Merged.

## Measurement infrastructure status

- 3 structural perf tests now: `transcript_blur_long_list_perf_test.dart`, `discover_dedupe_test.dart`, `discover_refresh_single_flight_test.dart`.
- All measure via structural unit-test assertions (emissions.length before/after Drift write).
- No `test/perf/` directory, microbenchmark harness, or CI perf-regression job.

## Run History (last 5)

- **2026-07-20** 18:46 UTC — run 29769067276. Drafted single-flight guard for DiscoverRefreshState.refresh() — _pendingRefresh stores in-flight future, concurrent callers share it. 2 structural tests. Local SDK read-only; changes verified by code review. Comment posted on #189.
- **2026-07-20** 04:39 UTC — run 29690257927. Audited v0.7.0 code, identified discover refresh single-flight as candidate. Measurement inventory: 286 tests, 1 perf-named test. Task 5: no-op.
- **2026-07-17** 12:00 UTC — run 29587195118. Verification only. PR #360 merged. Backlog audited.
- **2026-07-15** 14:57 UTC — run 29423417496. Drafted batched feed entry upsert. 3 structural tests.
- **2026-07-14** 15:23 UTC — run 29340890900. Investigation. Regex caching microbenchmarked (1.302x, deprioritized). Created #355.

## Per-run safe-output checklist

Always update issue #189 (monthly summary) with a new Run History entry. Use `update_issue` with `replace` operation, or fall back to `add_comment` if update limit reached. Update memory. Use `noop` only if no actions were taken.
