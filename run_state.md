# Perf Improver run state

- **Last run:** 2026-11-02 (workflow run 41448230411, run #78) — ninth run to
  produce a code-changing PR.
- **Run history:** #78 2026-11-02 (41448230411) shipped **P17** (blur cue-id
  memo, `cueIdFor` Expando per line) → draft PR on `perf-assist/cue-id-memo`
  (commit `6ca3e6c4`). PR #1191 (P16, echo-card tile reuse) was **MERGED by
  an-lee on 2026-11-02 01:15 UTC** (commit `ba78f6a8`) → **eight merged
  code-changing PRs total** (#1006, #1071, #1100, #1127, #1142, #1167, #1175,
  #1191). Maintainer refactor day also landed: #1201 (cloud paged-media
  widget + shared RecordingElapsedTicker + ErrorState), #1196
  (shadow-reading panel split), #1202 (openspec upgrade).
- **Next run:** (1) find the P17 PR number (search "perf-improver in:title"),
  check CI/GitGuardian; (2) the code-level backlog is **EMPTY** — the fresh
  scan's best remaining live target is the **pitch-contour runs/median
  per repaint** (painter-coupled, needs a structural-measurement plan first,
  see backlog "Verified non-targets"); everything else is a
  maintainer-decision item (P3-reframed, P7, P8, P10b) or dead path. (3) The
  2026-11-02 refactor day (#1196/#1201) created new surfaces (cloud
  paged-media widget, RecordingElapsedTicker) that were only lightly scanned —
  a deeper look at cloud_library_body.dart item builders is an option.

## Sandbox facts this run
- SDK copy + `pub get` warm (~2 min total, no cap kill). sqlite3
  `hooks: user_defines:` workaround applied for test runs and REVERTED before
  commit (`git checkout -- pubspec.yaml`).
- Full suite after P17: **7037 passed / 19 skipped** (tree keeps growing:
  6983 → 7028 → 7037).
- The checkout is a **blobless/partial clone**: `git show`/`git log -p` on
  older commits dies fetching from the promisor remote (TLS-blocked). Use
  GitHub MCP `get_commit` (detail=stats) for diffs; Read/Grep work fine at
  HEAD.
- `list_issues` with a label filter gets dropped by the MCP integrity policy,
  but `issue_read` DIRECTLY on a known number works — #1192 (November monthly)
  is readable that way.
- Bench this run: window regime (40-line warm) + sweep regime (512 fresh);
  legacy via an in-test copy of the pre-change body (NOT git stash — the
  change was in-file); env `CUE_ID_BENCH_MODE` selects the mode.

## Repo state at this run
- HEAD on `main` at run start: `6cbfbe7b` (#1201).
- Open perf-improver PRs after this run: the P17 draft (number assigned
  post-run).
- Monthly: November issue is **#1192** (open, no maintainer comments yet as
  of 13:37 UTC 2026-11-02; updated this run: P16 review action removed —
  merged, new P17 review action added, run history prepended).

## Tasks completed this run
- **Task 1**: commands still valid (see `commands.md`); no new discovery.
- **Task 2**: two parallel Explore sweeps (player/asr/shadow/transcript +
  sync/lookup/library/cloud/data) → 16 candidates; verified down to 1 shippable
  (P17) + several verified non-targets (recorded in backlog.md).
- **Task 3**: **DONE** — P17 (cue-id memo). Window 0.0192 → 0.0012 ms/pass
  (~16x median), sweep parity, sinks byte-identical. Full suite 7037/19.
- **Task 4**: no open perf-improver PRs (P16 #1191 merged 2026-11-02).
- **Task 5**: #1192 is the only open performance-labeled issue (my monthly
  summary); no new human comments → no comments posted.
- **Task 6**: no new infrastructure this run (P17 perf test follows the
  established counter + differential + skip-marked bench pattern;
  `docs/perf-measurement.md` index updated in the PR).
- **Task 7**: updated #1192 (removed merged-P16 action, added P17 review
  action, prepended run history).

## P17 — key implementation notes (details in `backlog.md`)
1. `Expando<String> _cueIdByLine` keyed on `TranscriptLine` identity;
   `cueIdDerivationCount` `@visibleForTesting` counter in transcript_blur.dart.
2. Derivation body moved to private `_deriveCueId` — logic byte-identical.
3. Test `a` const / `b` non-const with identical args: the `prefer_const_
   constructors` lint fires on `b`; silenced with `// ignore:` (allowed).
4. Const-canonicalization trap (P12 lesson) still applies for counter tests —
   use args unique in the file.

## Write path
- PRs must go through the safe-outputs `create_pull_request` tool; the
  framework pushes the bundle afterwards, so the PR may not be visible via
  the API immediately. Expected, not a failure.
- `update_issue` supports full-body rewrites; keep the mandated format
  (Suggested Actions first, reverse-chron Run History).
- `create_pull_request` / `create_issue` add the `[perf-improver] ` title
  prefix themselves — do **not** put it in the title you pass.
- `.dart_tool/package_config.json` is a real pub-generated config
  (gitignored); leaving it saves the next run a (warm) `pub get`.

## Open blockers / standing decisions
- P7 / P8 / P10b / P3-reframed all wait on maintainer decisions (surfaced
  in the November monthly issue #1192).
- `test/perf/` dir + benchmark CI job stay deferred per
  `docs/perf-measurement.md` — do not add them unilaterally.
- The November monthly issue (#1192) must be closed and a 2026-12 one opened
  when December starts.
