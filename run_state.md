# Perf Improver run state

- **Last run:** 2026-11-03 (workflow run 41635196398, run #79) — tenth run to
  produce a code-changing PR.
- **Run history:** #79 2026-11-03 shipped **P18** (pitch-contour runs memo,
  Expando per points identity) → draft PR on `perf-assist/pitch-runs-memo`
  (commit `fffe777f`). PR #1203 (P17, blur cue-id memo) was **MERGED by
  an-lee on 2026-11-03 03:23 UTC** → **nine merged code-changing PRs total**
  (#1006, #1071, #1100, #1127, #1142, #1167, #1175, #1191, #1203).
- **Next run:** (1) find the P18 PR number (search "perf-improver in:title"),
  check CI/GitGuardian, keep it healthy. (2) The code-level backlog is
  **EMPTY** — all remaining candidates (P7, P8, P3-reframed, P10b) wait on
  maintainer decisions surfaced in the November monthly issue #1192.
  (3) Fresh-scan surface options: the painter/custom-painter files beyond
  pitch_contour (waveform painters, `enjoy_logo` planes), the
  `practice_poster` domain (poster data derivation), or an ASR/sync sweep
  (not swept since 2026-10-25-ish). Verify callers before optimizing
  (P3 trap).

## Sandbox facts this run
- SDK copy + pub get warm (~3 min total). sqlite3 `hooks: user_defines:`
  workaround applied for tests and REVERTED before commit (verified absent
  from the commit).
- Full suite after P18: **7056 passed / 21 skipped** (7037 → 7056; +3 new
  tests, +2 skip-marked benches).
- Blobless clone still: use GitHub MCP `get_commit` for old diffs; `git log
  --format=%s%n%b <sha> <sha>` worked for two commits listed together.
- Bench this run: env `PITCH_RUNS_BENCH_MODE=legacy|memoized`, one impl per
  fresh process, n=5 per arm + 1 interleaved pair + a standalone-JIT
  isolation harness for the cold-path gap.
- **flutter_tester sweep numbers are bimodal across processes** (legacy
  122–169 ms for the SAME code; memoized 216–224 ms) — cross-process JIT
  tiering noise. The standalone `dart --packages=...` harness gives tight
  distributions; use it to confirm cold-path parity when the flutter_tester
  numbers look inconsistent. Expando insert micro-cost: 50–80 ns/list
  (measured, /tmp bench recipe in pitch_wrap_isolation.dart style).

## Repo state at this run
- HEAD on `main` at run start: `11b2407b` (#1217).
- Open perf-improver PRs after this run: the P18 draft (number assigned
  post-run; framework bundle written).
- Monthly: November issue is **#1192** (open, no maintainer comments as of
  13:06 UTC 2026-11-03; updated this run: removed the merged-P17 review
  action, added the P18 review action, prepended run history, backlog
  rewritten).

## Tasks completed this run
- **Task 1**: commands still valid (see `commands.md`); no new discovery.
- **Task 2**: Explore sweep of the post-#1201 surfaces (recording ticker,
  cloud repository/providers, RemoteLibraryItem, media cards) → all clean;
  scan of cloud_library_body `generativeAccentForSeed` → trivial FNV, not a
  target. Live target: the pitch-contour painter (held from run #78 with a
  plan).
- **Task 3**: **DONE** — P18 (pitch-contour runs memo). Playback repaint
  loop 55.4 → 0.06 ms per 200-tick pass (~900x median); cold sweep parity
  standalone; sinks byte-identical everywhere. Full suite 7056/21.
- **Task 4**: no open perf-improver PRs at run start (P17 #1203 merged
  2026-11-03).
- **Task 5**: #1192 is the only open performance-labeled issue; no new
  human comments → no comments posted.
- **Task 6**: no new infra (P18 perf test follows the counter + differential
  + skip-marked bench pattern; `docs/perf-measurement.md` index updated in
  the PR).
- **Task 7**: updated #1192 (removed merged-P17 action, added P18 review
  action, prepended run history).

## P18 — key implementation notes (details in `backlog.md`)
1. `_runs`/`_median` extracted from the painter to top-level pure functions;
   public `pitchContourRuns(points, showReference:, showUser:)` returns a
   record; per-series results cached in `_PitchRunsCache` via one Expando
   keyed on the points LIST identity (documented stable by
   `EchoMergedSeriesMemo`).
2. `@visibleForTesting int pitchContourRunsDerivationCount` counts real
   derivations; toggle-on of a disabled series derives only that series.
3. Widget-test approach was NOT needed — the public function is directly
   callable (P17-style counter assertions over fresh `_buildSeries()` lists;
   const-canonicalization trap avoided because the Expando keys on list
   identity and each builder call returns a fresh list).

## Write path
- PRs go through the safe-outputs `create_pull_request` tool; the PR number
  is assigned when the framework pushes the bundle — not visible via API
  immediately. Expected, not a failure.
- `update_issue` supports full-body rewrites; keep the mandated format.
- `create_pull_request` / `create_issue` add the `[perf-improver] ` title
  prefix themselves — do NOT put it in the title.
- `.dart_tool/package_config.json` left in place (warm pub get next run).

## Open blockers / standing decisions
- P7 / P8 / P10b / P3-reframed all wait on maintainer decisions (surfaced
  in the November monthly issue #1192).
- `test/perf/` dir + benchmark CI job stay deferred per
  `docs/perf-measurement.md` — do not add them unilaterally.
- The November monthly issue (#1192) must be closed and a 2026-12 one opened
  when December starts.
