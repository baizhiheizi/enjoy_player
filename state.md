# Perf Improver State

Updated: 2026-07-21 14:00 UTC
Repository: `baizhiheizi/enjoy_player`
Current monthly summary: issue #189 (`[perf-improver] Monthly Activity 2026-07`)

## Round-robin cursor

- This run (2026-07-21, run 29855434099): Task 6 (measurement infrastructure guide), Task 7 (monthly summary update). Task 4 no-op (no open PRs). Task 5 no-op (#355 closed by maintainer; #310 no new human comments).
- Draft PR created: `perf-assist/measurement-infra-guide-2026-07-21` — `docs/perf-measurement.md` documenting structural perf test patterns, per-layer measurement strategies, and microbenchmark templates.
- #355 closed by maintainer (an-lee, 2026-07-21). #310 still open, awaiting maintainer direction.
- Previous single-flight guard draft (2026-07-20) was ephemeral worktree-local; not pushed.

## Validated commands

CI-equivalent commands (unchanged):

```bash
flutter pub get
bash .github/scripts/check_dart_format.sh
bash .github/scripts/check_codegen_drift.sh
flutter analyze
flutter test
```

Status: Local Flutter SDK at `/opt/hostedtoolcache/flutter-3.44.0-stable` is read-only — `dart`/`flutter` commands fail. Workspace HEAD: `f845df8` (2026-07-21).

## Optimization backlog

1. **Incremental AI response streaming** — issue #310; awaiting maintainer decision.
2. **Artwork palette off main isolate** — blocked; needs maintainer sign-off.
3. **Dictation watch dedupe** — only if `DictationDao.watchByTarget` gains a production consumer.
4. **Stream long-form ASR media instead of materializing bytes** — needs peak-RSS baseline first.
5. **Coalesce overlapping Discover refreshes** — previous draft was ephemeral; needs fresh implementation.
6. **Microbenchmark harness** — `test/perf/` directory and CI regression remain future work. Guide now documents patterns.

### Recently addressed
- ✅ **Measurement infrastructure guide** — `docs/perf-measurement.md` created (2026-07-21). Draft PR created on `perf-assist/measurement-infra-guide-2026-07-21`.

## Current actions and outputs

- Draft PR: `perf-assist/measurement-infra-guide-2026-07-21` — measurement infrastructure guide with 4 documented structural perf test patterns.

## Completed performance work

- PR #360 (2026-07-17): batched feed entry upsert in `YoutubeFeedEntryDao` + 3 tests. Merged.
- PR #355 (2026-07-21): CI issue — closed by maintainer (resolved).
- PR #335 (2026-07-13): shared `L1Store` for discover avatar cache with 6-hour TTL. Merged.
- PR #188 (2026-07-02): artwork palette cache key includes path, size, and mtime. Merged.
- PRs #208 and #238 (2026-07-07): transcript-track stream dedupe. Merged.
