# Perf Improver State

Updated: 2026-07-15 14:57 UTC
Repository: `baizhiheizi/enjoy_player`
Current monthly summary: issue #189 (`[perf-improver] Monthly Activity 2026-07`)

## Round-robin cursor

- This run: Tasks 1, 2, 3, 4, 6, and mandatory Task 7.
- Next run: Task 5 is next on the cursor (comment on #310 if maintainer replies; otherwise check #355).
- Task 4 result: PR draft `perf-assist/discover-feed-batched-upsert-2026-07-15` (commit 888be23) created via safeoutputs. Awaiting first maintainer review.
- Maintainer closed out the format/CI drift from the previous run via commits `9b35429f`, `3d62ac6`, `7fc05d1`, `0d4e595`. CI run `29414416058` is green on `0d4e595`. Issue #355 is still open and ready to be closed by the maintainer.
- No new maintainer checkbox decisions in issue #189 yet.

## Validated commands

CI-equivalent commands (unchanged):

```bash
flutter pub get
bash .github/scripts/check_dart_format.sh
bash .github/scripts/check_codegen_drift.sh
flutter analyze
flutter test
# Per path package:
(cd packages/<name> && flutter pub get && flutter test)
```

Status:
- Green on 2026-07-13 (prior run).
- Restored on 2026-07-15: maintainer ran `check_dart_format --fix`, deleted the stale `discover_feed_filter_test.dart`, regenerated codegen, fixed analyzer lints. CI run `29414416058` succeeded for `0d4e595`.
- The local agentic Flutter SDK at `/opt/hostedtoolcache/flutter-3.44.0-stable` is still read-only; we continue to rely on the authoritative CI log rather than claiming local gate success.

## Optimization backlog

1. ✅ **Batch discover feed persistence** — `YoutubeFeedEntryDao.upsertEntries(List<YoutubeFeedEntryRow>)` added in commit `888be23` using `batch((b) => b.insertAll(...))`. `_refreshSingleSource` and `subscribeFromUserInput` now build a small list and call once per source instead of N per-row `upsertEntry`. 3 new structural regression tests in `test/features/discover/discover_dedupe_test.dart`. PR draft on branch `perf-assist/discover-feed-batched-upsert-2026-07-15`.
2. **Incremental AI response streaming** — issue #310; user-facing latency opportunity. Suggested first vertical slice: API stream parser + cancellation + contextual translation + final-result-only cache. Awaiting maintainer decision; no work this run.
3. **Artwork palette off main isolate** — blocked on a major dependency change or new quantizer; requires maintainer sign-off.
4. **Dictation watch dedupe** — only if `DictationDao.watchByTarget` gains a production consumer.
5. **Measurement infrastructure** — now have two structural perf tests (`test/features/transcript/transcript_blur_long_list_perf_test.dart` + the new 3 tests in `test/features/discover/discover_dedupe_test.dart`). Still no microbenchmark harness or CI regression threshold.

## Measurements and decisions

### 2026-07-15 — Batched feed entry upsert (commit 888be23)

Method: structural in-test assertion via `flutter test` (in-memory Drift). New tests live in `test/features/discover/discover_dedupe_test.dart`:

- `batched upsertEntries yields one watchTimeline emission`: 50 entries inserted in one `upsertEntries` call → ≤ 1 `watchTimeline` re-emission, list length 50.
- `upsertEntries on an empty list is a no-op`: empty list → 0 additional emissions.
- `per-call upsertEntry loop emits more than batched upsertEntries`: same 30-row set, loop vs. batched → strict assertion `batchDelta < loopDelta`. Final list contains all 60 rows.

User-facing impact: with 4 subscriptions × 50-entry feeds, `refreshFeeds` previously paid 200 intermediate `watchTimeline` states; after this PR it pays 4 (one per source). The downstream `.distinctBy(_listEqualsFeedEntry)` mask still suppresses identical final states, but the per-emission rebuild (map + elementwise-equals over a 50-row list) is no longer paid N times.

Decision: ship as a focused PR. No new dependencies, no schema change, no breaking change to `upsertEntry` callers.

### 2026-07-14 — JSON feed video-ID regex caching

Method: standalone Dart JIT microbenchmark, 200 mixed watch/bare/short/invalid IDs, 2,000 rounds (400,000 calls/sample), 10 alternating samples after warm-up.

- Per-call `RegExp` median: 178,448.5 µs/sample.
- Cached `RegExp` median: 137,049.5 µs/sample.
- Relative speedup: 1.302×.
- Absolute saving: about 0.1035 µs/call, or 5.2 µs for a 50-item feed.
- Decision: deprioritized; the isolated relative gain is real but total refresh impact is too small for a standalone PR.

## Current actions and outputs

- Drafted PR on branch `perf-assist/discover-feed-batched-upsert-2026-07-15` (commit 888be23): batched feed entry upsert in single Drift transaction.
- Updated monthly summary issue #189 with the 2026-07-15 14:57 UTC run entry.
- Suggested maintainer actions in #189: close #355 (CI green on 0d4e595); review the new perf PR; review streaming issue #310.

## Completed performance work

- PR draft (2026-07-15): batched feed entry upsert in `YoutubeFeedEntryDao` + 3 new tests.
- PR #335: shared `L1Store` for discover avatar cache with 6-hour TTL; merged 2026-07-13.
- PR #188: artwork palette cache key includes path, size, and mtime; merged 2026-07-02.
- PRs #208 and #238: transcript-track stream dedupe; merged 2026-07-07.
- Earlier Drift emission and sliver-key dedupe wave is complete; consult issue #189 history for links.
