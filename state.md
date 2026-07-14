# Perf Improver State

Updated: 2026-07-14 15:23 UTC
Repository: `baizhiheizi/enjoy_player`
Current monthly summary: issue #189 (`[perf-improver] Monthly Activity 2026-07`)

## Round-robin cursor

- This run: Tasks 2, 4, 6, and mandatory Task 7.
- Next run: prefer Tasks 1, 3, and 5, after first checking whether the CI-restoration issue created as `#aw_ci_fmt` is resolved.
- Task 4 result: no open `[perf-improver]` PRs; PR #335 merged on 2026-07-13.
- No maintainer checkbox decisions were present in issue #189 as of this run.

## Validated commands

CI-equivalent commands:

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
- Green on 2026-07-13 per prior Perf Improver run.
- Current `main` CI run 29329620274 fails `check_dart_format.sh`: 13 files need formatting; analyze/tests/coverage/path-package tests were skipped.
- `test/features/discover/discover_feed_filter_test.dart` still references removed `filterDiscoverFeedByFocusLanguage` and `DiscoverChannel(language: ...)` APIs, so compile/test is expected to fail after formatting is fixed unless the test is removed or rewritten.
- The local agentic Flutter SDK is read-only; direct Dart fallback could not load the cached `flutter_lints` include. Use authoritative CI results rather than claiming local gate success.

## Optimization backlog

1. **Batch discover feed persistence** — `DiscoverRepository._refreshSingleSource` at `lib/features/discover/data/discover_repository.dart:374-387` awaits one `YoutubeFeedEntryDao.upsertEntry` per feed entry. Before changing, benchmark 5 channels × 50 entries and compare transaction count, Drift emissions, and wall time.
2. **Incremental AI response streaming** — issue #310; user-facing latency opportunity. Suggested first vertical slice: API stream parser + cancellation + contextual translation + final-result-only cache.
3. **Artwork palette off main isolate** — blocked on a major dependency change or new quantizer; requires maintainer sign-off.
4. **Dictation watch dedupe** — only if `DictationDao.watchByTarget` gains a production consumer.
5. **Measurement infrastructure** — one 10k-line transcript widget perf test exists (`test/features/transcript/transcript_blur_long_list_perf_test.dart`), but no benchmark suite or performance-regression CI threshold.

## Measurements and decisions

### 2026-07-14 — JSON feed video-ID regex caching

Method: standalone Dart JIT microbenchmark, 200 mixed watch/bare/short/invalid IDs, 2,000 rounds (400,000 calls/sample), 10 alternating samples after warm-up.

- Per-call `RegExp` median: 178,448.5 µs/sample.
- Cached `RegExp` median: 137,049.5 µs/sample.
- Relative speedup: 1.302×.
- Absolute saving: about 0.1035 µs/call, or 5.2 µs for a 50-item feed.
- Decision: deprioritized; the isolated relative gain is real but total refresh impact is too small for a standalone PR.

## Current actions and outputs

- Created CI-restoration issue using temporary reference `#aw_ci_fmt`. It documents CI run 29329620274, 13 format-drift files, the stale discover-language test, and full-gate acceptance criteria. Safeoutputs will replace the temporary reference with the real issue number.
- Updated monthly summary issue #189 with the 2026-07-14 15:23 UTC run entry.
- Suggested maintainer actions in #189: resolve/close `#aw_ci_fmt`; review streaming issue #310.

## Completed performance work

- PR #335: shared `L1Store` for discover avatar cache with 6-hour TTL; merged 2026-07-13.
- PR #188: artwork palette cache key includes path, size, and mtime; merged 2026-07-02.
- PRs #208 and #238: transcript-track stream dedupe; merged 2026-07-07.
- Earlier Drift emission and sliver-key dedupe wave is complete; consult issue #189 history for links.
