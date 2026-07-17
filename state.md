# Perf Improver State

Updated: 2026-07-17 12:00 UTC
Repository: `baizhiheizi/enjoy_player`
Current monthly summary: issue #189 (`[perf-improver] Monthly Activity 2026-07`)

## Round-robin cursor

- This run (2026-07-17, run 29587195118): Tasks 1, 2, 4, 6 + mandatory Task 7. Task 3 deferred — no safe implementation target this run (see below). PR #360 (drafted last run) was merged by the maintainer.
- Next run: Task 5 (comment on performance issues). Outstanding targets: #310 (incremental AI response streaming, no maintainer response yet), #144 (no-op runs tracker — auto-managed, skip).
- No open `[perf-improver]` PRs to maintain. Task 4 result: clean.
- Maintainer activity since 2026-07-15: PR #360 merged; v0.6.0 prep; profile-edit form with avatar upload; Windows Azure non-ASCII paths fix; Drift snake_case migration; many doc syncs. CI green on `89b33c4`.
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
- 2026-07-17: PR #360 merged into `main`. Latest `main` is `89b33c4 docs: resolve ADR collisions and sync Discover / schema docs`.
- The local agentic Flutter SDK at `/opt/hostedtoolcache/flutter-3.44.0-stable` is read-only; we continue to rely on authoritative CI logs.

## Optimization backlog

1. **Incremental AI response streaming** — issue #310; user-facing latency opportunity. Suggested first vertical slice: API stream parser + cancellation + contextual translation + final-result-only cache. Awaiting maintainer decision; no work this run.
2. **Artwork palette off main isolate** — blocked on a major dependency change or new quantizer; requires maintainer sign-off.
3. **Dictation watch dedupe** — only if `DictationDao.watchByTarget` gains a production consumer.
4. **Measurement infrastructure** — now have three structural perf tests (`test/features/transcript/transcript_blur_long_list_perf_test.dart`, `test/features/transcover/transcript_dedupe_test.dart`, plus the 3 in `test/features/discover/discover_dedupe_test.dart`). Still no microbenchmark harness or CI regression threshold.
5. ✅ **Batch discover feed persistence** — `YoutubeFeedEntryDao.upsertEntries(List<YoutubeFeedEntryRow>)` shipped via PR #360 (merged 2026-07-17, commit `ce9f38b`).

## Measurements and decisions

### 2026-07-15 — Batched feed entry upsert (commit ac41979, merged as #360)

Method: structural in-test assertion via `flutter test` (in-memory Drift). Tests live in `test/features/discover/discover_dedupe_test.dart`:

- `batched upsertEntries yields one watchTimeline emission`: 50 entries inserted in one `upsertEntries` call → ≤ 1 `watchTimeline` re-emission, list length 50.
- `upsertEntries on an empty list is a no-op`: empty list → 0 additional emissions.
- `per-call upsertEntry loop emits more than batched upsertEntries`: same 30-row set, loop vs. batched → strict assertion `batchDelta < loopDelta`. Final list contains all 60 rows.

User-facing impact: with 4 subscriptions × 50-entry feeds, `refreshFeeds` previously paid 200 intermediate `watchTimeline` states; after #360 it pays 4 (one per source). The downstream `.distinctBy(_listEqualsFeedEntry)` mask still suppresses identical final states, but the per-emission rebuild (map + elementwise-equals over a 50-row list) is no longer paid N times.

Decision: shipped via PR #360 (merged 2026-07-17).

### 2026-07-14 — JSON feed video-ID regex caching

Method: standalone Dart JIT microbenchmark, 200 mixed watch/bare/short/invalid IDs, 2,000 rounds (400,000 calls/sample), 10 alternating samples after warm-up.

- Per-call `RegExp` median: 178,448.5 µs/sample.
- Cached `RegExp` median: 137,049.5 µs/sample.
- Relative speedup: 1.302×.
- Absolute saving: about 0.1035 µs/call, or 5.2 µs for a 50-item feed.
- Decision: deprioritized; the isolated relative gain is real but total refresh impact is too small for a standalone PR.

## Current actions and outputs

- Updated monthly summary issue #189 with the 2026-07-17 12:00 UTC run entry. Removed the now-stale "review PR draft perf-assist/discover-feed-batched-upsert-2026-07-15" suggested action (PR #360 is merged). Kept the "close #355" suggestion (still open, parent issue ready to close) and "review #310" (still open, no maintainer response).
- No new draft PR this run.

## Completed performance work

- PR #360 (2026-07-17): batched feed entry upsert in `YoutubeFeedEntryDao` + 3 new tests. Merged.
- PR #335: shared `L1Store` for discover avatar cache with 6-hour TTL; merged 2026-07-13.
- PR #188: artwork palette cache key includes path, size, and mtime; merged 2026-07-02.
- PRs #208 and #238: transcript-track stream dedupe; merged 2026-07-07.
- Earlier Drift emission and sliver-key dedupe wave is complete; consult issue #189 history for links.