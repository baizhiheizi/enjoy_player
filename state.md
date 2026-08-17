---
## Perf Improver — State

Updated: 2026-08-17 18:00 UTC
Repository: baizhiheizi/enjoy_player
Current monthly summary: issue (created 2026-08-17, run 32049374878) `[perf-improver] Monthly Activity 2026-08`

## Round-robin cursor

- This run (2026-08-17, run 32049374878): Re-landed `VocabularyItem` / `VocabularyContext` field-by-field equality on branch `perf-assist/vocabulary-value-equality-2026-08-17`. 6 structural tests. PR created via safeoutputs.
- 2026-08-10 entry in `perf-improver-state.md` marked `VocabularyItem / VocabularyContext equality` as ✅ Addressed — that was STALE. Branch `perf-assist/vocabulary-value-equality-2026-08-10` was created in a worktree that did not survive; commit does not exist on main or any reachable ref. Memory corrected to "Re-landed 2026-08-17".
- No open perf-improver PRs to maintain.
- #310 still open, awaiting maintainer direction.

## Validated commands

CI-equivalent commands (verified 2026-08-17):

```bash
flutter pub get
bash .github/scripts/check_dart_format.sh
bash .github/scripts/check_codegen_drift.sh
flutter analyze
flutter test
```

Status: All gates pass on Linux AWF sandbox. Format clean, analyzer clean on edited files, codegen drift clean, 6/6 new tests pass. Flutter 3.44.0 via writable copy at `/tmp/gh-aw/agent/flutter_copy/flutter/bin/` with `PUB_CACHE=/tmp/gh-aw/agent/pub_cache`.

## Optimization backlog

1. **Incremental AI response streaming** — issue #310; awaiting maintainer decision.
2. **Artwork palette off main isolate** — blocked; needs maintainer sign-off.
3. **Stream long-form ASR media instead of materializing bytes** — needs peak-RSS baseline first.
4. **Distinct vocabulary items stream** — `vocabularyItemsProvider` re-emits a new `List<VocabularyItem>` on every Drift change. **Prerequisite equality landed in PR from run 32049374878**; follow-up `.distinct(equals)` on the stream remains.
5. **CI microbenchmark smoke job** — `test/perf/` exists but no dedicated CI step.

### Recently addressed
- ✅ **VocabularyItem / VocabularyContext equality** (2026-08-17) — RE-LANDED. Branch `perf-assist/vocabulary-value-equality-2026-08-17`. 6 structural tests cover identical-equal, hash-equals contract, and per-field inequality for all 28 fields. PR created.
- ✅ **test/perf/ microbenchmark harness** (2026-07-23) — `test/perf/` directory created with subtitle + case-conversion benchmarks.
- ✅ **Discover refresh single-flight** (2026-07-22) — already implemented in `main`.
- ✅ **Measurement infrastructure guide** (2026-07-21) — `docs/perf-measurement.md` merged as PR #422.

## Current actions and outputs

- PR created: `perf-assist/vocabulary-value-equality-2026-08-17` — VocabularyItem + VocabularyContext equality.
- Monthly summary issue created for 2026-08.
- Memory updated.

## Completed performance work

- PR `perf-assist/vocabulary-value-equality-2026-08-17` (2026-08-17): VocabularyItem + VocabularyContext equality. Draft PR created via safeoutputs.
- PR #526 (2026-08-05): `perf(image-cache): swap remaining Image.network for CachedNetworkImageProvider`.
- PR #504 (2026-07-30): `perf: hoist regex allocations, scope MediaQuery dep, cache per-locale DateFormat`.
- PR #499 (2026-07-28): `perf(player): scope two transport-bar / surface-host rebuilds`.
- PR #422 (2026-07-21): docs/perf-measurement.md.
- PR #360 (2026-07-17): batched feed entry upsert in `YoutubeFeedEntryDao` + 3 tests.
- PR #335 (2026-07-13): shared `L1Store` for discover avatar cache with 6-hour TTL.
- PRs #208, #238 (2026-07-07): transcript-track stream dedupe.
- PR #188 (2026-07-02): artwork palette LRU on (path, size, mtime).
- PRs #56/#64/#65/#79/#137/#150 (June 2026): media library, discover, recordings, transcript, grid stable keys.
## Per-run safe-output checklist

Always create/update the `[perf-improver] Monthly Activity YYYY-MM` issue with a new Run History entry. Use `noop` only if no actions were taken.
