# Perf Improver run state

- **Last run:** 2026-10-31 (workflow run 41193493646, run #76) — nineteenth
  October run, seventh run to produce a code-changing PR.
- **Run history:** #76 2026-10-31 (41193493646) shipped P15 → draft PR on
  `perf-assist/plain-cue-text-once-per-row` (commit `272d27ac`). #75
  2026-10-30 (41045058648) shipped P13 → **PR #1167** (open; GitGuardian
  check green; no repo CI on the branch). #74 shipped P14 → PR #1142
  MERGED 2026-10-30. #73 P12 → #1127 merged 2026-10-28. #72 P11 → #1100
  merged 2026-10-27. #71 P10 → #1071 merged 2026-10-26. #66 P9 → #1006
  merged 2026-10-20. Five merged code-changing PRs total.
- **Next run:** check PR #1167 (P13) and the P15 PR's state (number assigned
  when the framework pushes the bundle; find it via
  `search_pull_requests "perf-improver in:title"`). The next backlog
  candidate is **P16** (echo card builds every line of the echo range
  eagerly — virtualize it; MED risk: echo layout + selection behaviour) —
  the last code-level backlog item. After P16 only maintainer-decision
  items remain (P3-reframed, P7, P8, P10b).

## Sandbox facts this run
- The writable Flutter SDK copy at `/tmp/gh-aw/agent/flutter-3.47.6` must be
  re-created each run (`cp -a` from the toolcache) — recipe in `commands.md`.
  This run the copy + `pub get` were FAST (~1 min warm; the 2026-10-30 cold
  cap-kill did not recur — sandbox image may have warmed).
- **`flutter test -n` does NOT exist** on Flutter 3.47 despite AGENTS.md's
  "AI-debug route" showing `-n testName` — use `--plain-name`.
- Baseline this run: full suite **6983 passed / 14 skipped** AFTER the P15
  change (adds 3 tests + 1 skip). Pre-change demonstration done via
  `git stash push -- <tile file>` (counter test failed with delta 2 — the
  empirical "before").
- Sequential bench loops again (legacy n=4, then fast n=4); sinks identical
  across all 8 runs.

## Repo state at this run
- HEAD on `main` at run start: `1a98abb2` (fix(ui) #1165).
- **Open `[perf-improver]` PRs:** #1167 (P13 auto-translate source key) and
  the new P15 PR. Both awaiting maintainer review; neither merged.
- repo-assist: nothing new since #1124 (P6, merged 2026-10-28).
- Issue #864 readable (body + the 2026-10-28 Repo Assist comment). No new
  human comments anywhere since run #75 — P3/P7/P8/P10b still waiting on
  maintainer decisions (surfaced in the monthly summary).

## Tasks completed this run
- **Task 1**: SDK re-created; sqlite3 pubspec workaround applied (and
  REVERTED before commit — `git checkout -- pubspec.yaml`); pub get warm;
  analyze + format + codegen/path-deps gates + full suite all green.
- **Task 2**: P15 re-verified on the current tree (tile lines 207/388
  unchanged since the backlog entry; parser + FIFO cache unchanged).
- **Task 3**: **DONE.** Branch `perf-assist/plain-cue-text-once-per-row`,
  commit `272d27ac`, draft PR via safe-outputs (bundle 7.9 KB / patch
  20 KB). Details in `backlog.md` (P15).
- **Task 4**: PR #1167 open + green (only GitGuardian runs there); nothing
  to maintain. P14 merged last run.
- **Task 5**: no open performance issues besides #864 (my own monthly
  summary); no action.
- **Task 6**: no new infrastructure this run (the P15 perf test follows the
  established env-var bench + differential pattern; `docs/perf-measurement.md`
  index updated in the PR).
- **Task 7**: updated issue #864 (replace): carried P7/P8/P10b/P3 actions,
  swapped the P13 branch-compare action for the real PR #1167 review link,
  added the P15 review action, prepended the run entry.

## P15 — what shipped (details in `backlog.md`)
1. Tile: `shapeWords:` reuses `primaryPlain` — 2→1 derivations per outer
   build (counter `transcriptPlainDerivationCount` pins it).
2. Parser: fast path for inputs with no `<`/`&` — no cache, no per-char
   loop. Supersedes the LRU idea from the backlog.
Measured: eviction-regime sweep ~8.1x median; warm window parity; output
sinks identical. Differential-tested vs a legacy copy (corpus + 2000 fuzz).

## Write path
- PRs must go through the safe-outputs `create_pull_request` tool; the
  framework pushes the bundle afterwards, so the PR may not be visible via
  the API immediately. Expected, not a failure.
- `update_issue` (`target: "*"`): **`issue_number` must be passed
  explicitly**, and `max: 1` — one write per run.
- `create_pull_request` adds the `[perf-improver] ` title prefix itself —
  do **not** put it in the title you pass.
- `.dart_tool/package_config.json` is a real pub-generated config
  (gitignored); leaving it saves the next run a (warm) `pub get`.

## Open blockers / standing decisions
- The monthly summary for 2026-10 stays open until 2026-11; close it and
  open a new one in November.
- `test/perf/` dir + benchmark CI job stay deferred per
  `docs/perf-measurement.md` — do not add them unilaterally.
- P7 / P8 / P10b / P3-reframed all wait on maintainer decisions (surfaced in
  the monthly summary each run).
