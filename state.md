# Perf Improver State

Updated: 2026-07-20 18:46 UTC
Repository: `baizhiheizi/enjoy_player`
Current monthly summary: issue #189 (`[perf-improver] Monthly Activity 2026-07`)

## Round-robin cursor

- This run (2026-07-20, run 29769067276): Task 3 (implementation — single-flight guard), Task 7 (monthly summary update). Task 5 skipped — no new human comments on #310 or #355.
- Outstanding targets: #310 (incremental AI response streaming, no maintainer response yet), #355 (CI ready to close, Repo Assist already suggested close).
- Draft PR created: `perf-assist/discover-refresh-single-flight-2026-07-20` — single-flight guard for DiscoverRefreshState.refresh().
- Maintainer activity since 2026-07-17: v0.7.0 prep, docs updates (library, vocabulary, ProfileScreen), flutter plugin cache fix. CI green on `fbfcdfb`.

## Validated commands

CI-equivalent commands (unchanged):

```bash
flutter pub get
bash .github/scripts/check_dart_format.sh
bash .github/scripts/check_codegen_drift.sh
flutter analyze
flutter test
```

Status: Local Flutter SDK at `/opt/hostedtoolcache/flutter-3.44.0-stable` is read-only — `dart`/`flutter` commands fail due to `update_engine_version.sh` trying to write to engine stamps. CI for `fbfcdfb` (run 29706577939) is green. Latest docs-only commits `f99e760` etc. do not trigger CI.

## Optimization backlog

1. **Incremental AI response streaming** — issue #310; user-facing latency opportunity. Awaiting maintainer decision.
2. **Artwork palette off main isolate** — blocked on a major dependency change or new quantizer; requires maintainer sign-off.
3. **Dictation watch dedupe** — only if `DictationDao.watchByTarget` gains a production consumer.
4. **Measurement infrastructure** — structural perf tests exist (transcript_blur_long_list, discover_dedupe, discover_refresh_single_flight), but still no microbenchmark harness or CI regression threshold.
5. **Stream long-form ASR media instead of materializing bytes** — >=15-minute audio path materializes entire extracted payload into Uint8List/AsrRequest; 500 MiB extractor ceiling. Needs peak-RSS baseline measurement first.

### Recently addressed
- ✅ **Coalesce overlapping Discover refreshes** — single-flight guard in DiscoverRefreshState (this run, 2026-07-20). Draft PR on `perf-assist/discover-refresh-single-flight-2026-07-20`.
- ✅ **Batch discover feed persistence** — `YoutubeFeedEntryDao.upsertEntries(List<>)` shipped via PR #360 (merged 2026-07-17).

## Current actions and outputs

- Draft PR: `perf-assist/discover-refresh-single-flight-2026-07-20` — single-flight guard for DiscoverRefreshState.refresh(). 2 structural tests. Ready for review.
- Comment on #189: run summary and suggested actions posted.

## Completed performance work

- PR #360 (2026-07-17): batched feed entry upsert in `YoutubeFeedEntryDao` + 3 tests. Merged.
- PR #355: Restore CI after discover feed refactor — closed by maintainer action (CI green).
- PR #335 (2026-07-13): shared `L1Store` for discover avatar cache with 6-hour TTL. Merged.
- PR #188 (2026-07-02): artwork palette cache key includes path, size, and mtime. Merged.
- PRs #208 and #238 (2026-07-07): transcript-track stream dedupe. Merged.
