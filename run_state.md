# Perf Improver run state

- **Last run:** 2026-11-01 (workflow run 41302117389, run #77) — first
  November run, eighth run to produce a code-changing PR.
- **Run history:** #77 2026-11-01 (41302117389) shipped P16 → draft PR on
  `perf-assist/echo-card-tile-reuse` (commit `15572391`). Same day,
  **an-lee merged BOTH open perf-improver PRs**: #1167 (P13) at 00:29 UTC
  and #1175 (P15) at 01:31 UTC → **seven merged code-changing PRs total**
  (#1006, #1071, #1100, #1127, #1142, #1167, #1175).
- **Next run:** find the P16 PR number (`search_pull_requests
  "perf-improver in:title"` or list PRs; the framework assigns it when
  pushing the bundle) and check its CI/GitGuardian state. **The code-level
  backlog is now EMPTY** — after P16, only maintainer-decision items remain
  (P3-reframed, P7, P8, P10b; surfaced in the November monthly issue). The
  2026-10-31→11-01 maintainer refactor day (#1178–#1181, #1185, #1186,
  #1188, v0.10.3) touched many files — a fresh Task 2 scan of the
  post-refactor tree for NEW measurable opportunities is the natural next
  Task 3 candidate if the P16 PR needs no maintenance.

## Sandbox facts this run
- SDK copy + `pub get` warm (~1 min total). sqlite3 `hooks: user_defines:`
  workaround applied for test runs and REVERTED before commit (`git
  checkout -- pubspec.yaml`).
- Full suite after P16: **7028 passed / 17 skipped** (tree gained tests
  from the maintainer refactor day: was 6983/14 on 2026-10-31).
- `testWidgets(..., skip: 'reason')` does NOT compile — `testWidgets` takes
  `bool? skip` (only plain `test` accepts a String reason).
- Bench this run: 4 sequential legacy/cached process pairs; legacy measured
  via `git stash push -- <card file>` with the counter + tests still in the
  tree; the stash/pop cycle inside a script is safe as long as no other
  process touches the stashed file (do NOT format/edit lib while a stash
  loop runs).
- Structural counter tests + stash give an empirical "before" without a
  legacy copy: stash the lib change → counter test FAILS with the legacy
  delta (documented as the before-evidence).

## Repo state at this run
- HEAD on `main` at run start: `ad1895e9` (moved from `1a98abb2` —
  maintainer refactor day #1178/#1179/#1180/#1181/#1185/#1186/#1188 +
  v0.10.3 #1140).
- Open perf-improver PRs after this run: the P16 draft (number assigned
  post-run). #1167 and #1175 merged.
- Monthly: **October #864 CLOSED** (update_issue status=closed, no closing
  comment); **November issue created** (number unknown during the run;
  find via search_issues "Monthly Activity 2026-11").
- Issue #864 had no new human comments since 2026-10-31; its action
  checkboxes were never ticked by the maintainer; P7/P8/P3/P10b carried to
  the November issue.

## Tasks completed this run
- **Task 1**: commands still valid (see `commands.md`); no new discovery.
- **Task 3**: **DONE** — P16 shipped as a per-line tile cache
  (identical-widget short-circuit), NOT virtualization: much lower risk,
  same layout/selection semantics. Structural: cue change 180 → 2 tile
  builds (60-line block); wall clock 300-line block 126.6 → 16.7 ms median
  (~7.6x). Details in `backlog.md` (P16).
- **Task 4**: both open PRs merged today — nothing to maintain.
- **Task 5**: #864 was the only performance-labeled open issue (my own
  monthly summary); no new human comments → no comments posted.
- **Task 6**: no new infrastructure this run (the P16 perf test follows the
  established counter + skip-marked bench pattern; `docs/perf-measurement.md`
  index updated in the PR).
- **Task 7**: closed #864 (October), created the November monthly issue
  with the carried-over maintainer decisions + the P16 review action.

## P16 — key implementation notes (details in `backlog.md`)
1. `ConsumerStatefulWidget` + `Map<int, ({inputs, tile})>`; record equality
   (named fields) decides identical-widget reuse.
2. `didUpdateWidget` clears on lines-identity / mediaId / range change.
3. Request scheduling + resolve stay per-line-per-build (do NOT tie them to
   the cache — preserves the "auto-translate enabled later" path; the
   controller dedupes and self-pumps).
4. `TranscriptSecondaryMatcher.match` falls back to nearest-below → any
   secondary line matches nearly every primary → single-line invalidation
   tests must use the recording-counts provider.
5. `@visibleForTesting transcriptTileBuildCount` in
   `transcript_line_tile.dart` is the structural counter.

## Write path
- PRs must go through the safe-outputs `create_pull_request` tool; the
  framework pushes the bundle afterwards, so the PR may not be visible via
  the API immediately. Expected, not a failure.
- `update_issue` supports `status: closed` — used to close the October
  monthly issue (max 1 update_issue write per run).
- `create_pull_request` / `create_issue` add the `[perf-improver] ` title
  prefix themselves — do **not** put it in the title you pass.
- `.dart_tool/package_config.json` is a real pub-generated config
  (gitignored); leaving it saves the next run a (warm) `pub get`.

## Open blockers / standing decisions
- P7 / P8 / P10b / P3-reframed all wait on maintainer decisions (surfaced
  in the November monthly issue).
- `test/perf/` dir + benchmark CI job stay deferred per
  `docs/perf-measurement.md` — do not add them unilaterally.
- The November monthly issue must be closed and a 2026-12 one opened when
  December starts.
