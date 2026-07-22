# Perf Improver State

Updated: 2026-07-22 18:25 UTC
Repository: `baizhiheizi/enjoy_player`
Current monthly summary: issue #189 (`[perf-improver] Monthly Activity 2026-07`)

## Round-robin cursor

- This run (2026-07-22, run 29944478627): CI validation, backlog audit of Discover refresh (already implemented), memory update, monthly summary comment added.
- Discover refresh single-flight already in `main` at `discover_providers.dart:149-176`. Tested in `discover_refresh_single_flight_test.dart`.
- #355 closed by maintainer (an-lee, 2026-07-21). #310 still open, awaiting maintainer direction.
- Draft PR from 2026-07-21 (`perf-assist/measurement-infra-guide-2026-07-21`): status unknown (cannot verify via unauthenticated gh).

## Validated commands

CI-equivalent commands (verified 2026-07-22):

```bash
flutter pub get
bash .github/scripts/check_dart_format.sh
bash .github/scripts/check_codegen_drift.sh
flutter analyze
flutter test
```

Status: All gates pass on Linux AWF sandbox. 1707 tests pass, 2 skipped. Flutter 3.44.0 via writable overlay at `/tmp/gh-aw/agent/flutter_copy` with `PUB_CACHE=/tmp/gh-aw/agent/pub_cache`.

## Optimization backlog

1. **Incremental AI response streaming** — issue #310; awaiting maintainer decision.
2. **Artwork palette off main isolate** — blocked; needs maintainer sign-off.
3. **Dictation watch dedupe** — only if consumer exists.
4. **Stream long-form ASR media instead of materializing bytes** — needs peak-RSS baseline first.
5. **Microbenchmark harness** — `test/perf/` directory and CI regression remain future work.

### Recently addressed
- ✅ **Coalesce overlapping Discover refreshes** — already implemented in `main` at `discover_providers.dart:149-176` with `_pendingRefresh` single-flight guard. Backlog item resolved.
- ✅ **Measurement infrastructure guide** — `docs/perf-measurement.md` created (2026-07-21). Draft PR created.

## Current actions and outputs

- Comment added to issue #189: run summary for 2026-07-22.
- Draft PR: `perf-assist/measurement-infra-guide-2026-07-21` — measurement infrastructure guide (status unknown).

## Completed performance work

- ✅ Discover refresh single-flight — in `main` (merged by maintainer).
- PR #360 (2026-07-17): batched feed entry upsert in `YoutubeFeedEntryDao` + 3 tests. Merged.
- PR #355 (2026-07-21): CI issue — closed by maintainer (resolved).
- PR #335 (2026-07-13): shared `L1Store` for discover avatar cache with 6-hour TTL. Merged.
- PR #188 (2026-07-02): artwork palette cache key includes path, size, and mtime. Merged.
- PRs #208 and #238 (2026-07-07): transcript-track stream dedupe. Merged.
