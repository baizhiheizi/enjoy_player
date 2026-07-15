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

Local agentic SDK at `/opt/hostedtoolcache/flutter-3.44.0-stable` is read-only; rely on authoritative CI logs. Codegen: `dart run build_runner build` (or `bash .github/scripts/check_codegen_drift.sh --fix`). No benchmark / perf-regression CI job.

## Optimization Backlog — Remaining

1. **Artwork palette off main isolate** (`lib/core/theme/dynamic_color/artwork_palette.dart`) — `palette_generator` 0.3.x has no isolate-safe API; needs maintainer sign-off for major bump or hand-rolled quantiser. **Reassessed 2026-07-13, deferred.**
2. **JSON decode concurrency audit** (`lib/data/api/api_client.dart`) — `_decodeResponseBody` uses `compute()` for >48 KB. `audio_api.audios()` / `transcript_api.transcripts()` are simple one-shots; threshold correct as-is.
3. **Dictations DAO** — `DictationDao.watchByTarget` has no consumer in `lib/` today (`app_database.dart:650`; only generated `.g.dart` references it). When hooked up, needs `.distinctBy(equals)`.

## Optimization Backlog — Addressed

- ✅ PR #56/#64/#65/#79/#137/#150 — media library, discover, recordings, transcript, grid stable keys (June 2026).
- ✅ PR #188 (2026-07-02) — artwork palette LRU on `(path, size, mtime)`.
- ✅ PR #208+#238 (2026-07-07) — `TranscriptTrack` `==`/`hashCode` + `.distinctBy(_listEqualsTranscriptTrack)` in `TranscriptRepository.watchTracks`. Closes #219.
- ✅ PR #291 (2026-07-11) — `PlaybackSession`/`EchoState` equality; single shared `rawEnginePositionStreamProvider`; `.select(...)` on every chrome provider; `PlayerInteractions._lines()` cached.
- ✅ PR #335 (2026-07-13) — `DiscoverRepository._avatarUrlCache` swapped onto shared `L1Store<K, V>`; 6h TTL; ~10 lines removed; 3 new unit tests.
- ✅ PR draft `perf-assist/discover-feed-batched-upsert-2026-07-15` (commit 888be23, 2026-07-15) — `YoutubeFeedEntryDao.upsertEntries(List<row>)` via `batch((b) => b.insertAll(...))`. `_refreshSingleSource` and `subscribeFromUserInput` collapsed to one batched call. 3 new structural tests (50-row batch ≤1 emission; empty no-op; loop-of-30 emits strictly more than batch-of-30).

## Measurement infrastructure status

- All work to date measures via structural unit-test assertions (`emissions.length` before/after Drift write). Cheap, deterministic, runs in `flutter test`.
- For compute-bound work the natural extension is `Stopwatch` microbenchmarks in `test/perf/` gated on `--dart-define=PERF=1`. Not yet built.
- No CI perf regression job. Assessment 2026-07-07.
- 2026-07-14 microbenchmark deprioritized: caching three `extractVideoId` regexes measured 1.302× faster in isolation but saves only ~5.2 μs per 50-item feed; no standalone change.

## Investigation completed (closed-out parent issues)

- `_positionSub` / `_durationSub` — already bucketed to 400 ms in `_subscribeStreams`.
- `youtube_player_engine.dart` poll-loop timer — `_stopPolling()` confirmed in `dispose()` / `idleAfterClear()` / `onWebViewDisposed()` / `ended`.
- #131 transcript lines — closed 2026-06-28 by #137.
- #106 discover perf parent — closed 2026-06-28 by `@an-lee`.
- #219 transcript tracks dedupe — closed 2026-07-07 by #208+#238.
- #188 artwork palette cache staleness — merged 2026-07-02.
- #291 transcript/player rebuild storms — all post-#291 auditable paths deduped; PR captured by maintainer on 2026-07-11.

## Run History (last 5)

- **2026-07-15** 14:57 UTC — run 29423417496. Drafted batched feed entry upsert → PR draft `perf-assist/discover-feed-batched-upsert-2026-07-15`. `YoutubeFeedEntryDao.upsertEntries(List<row>)` + 3 new structural tests. CI green on `0d4e595`; #355 still open and ready to close.
- **2026-07-14** 15:23 UTC — run 29340890900. Investigation. Prioritized sequential per-entry Drift upserts for benchmark-first investigation; microbenchmarked `extractVideoId` regex caching (1.302×, deprioritized); created #355.
- **2026-07-13** 15:30 UTC — run 29262675978. Drafted LRU consolidation → PR #335. All gates green.
- **2026-07-11** 14:30 UTC — run 29155553769. Investigation only. Audited #291 / #292 / #293 / #295; dedupe chain complete.
- **2026-07-07** 15:30 UTC — run 28878529792. Investigation only. PR #208+#238 shipped.

## Per-run safe-output checklist

Always update issue #189 (monthly summary, current month) with a new Run History entry prepended; update memory; if no actionable findings call `noop`. Use `update_issue` with `replace` operation when replacing body (keep within 10 KB); prefer trimming Run History entries when memory exceeds 12 KB total.
