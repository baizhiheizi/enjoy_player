# Perf Improver run state

- **Last run:** 2026-10-30 (workflow run 41045058648, run #75) — eighteenth
  October run, sixth run to produce a code-changing PR.
- **Run history:** #75 2026-10-30 (41045058648) shipped P13 → draft PR on
  `perf-assist/auto-translate-source-key`. #74 2026-10-29 (40862808812)
  shipped P14 → PR #1142, **MERGED by an-lee 2026-10-30 01:21 UTC** (merge
  commit `aa106dc7`) — Perf Improver's **fifth** merged code-changing PR.
  #73 shipped P12 → PR #1127 merged 2026-10-28. #72 shipped P11 → PR #1100
  merged 2026-10-27. #71 shipped P10 → PR #1071 merged 2026-10-26. #66
  shipped P9 → PR #1006 merged 2026-10-20.
- **Next run:** check the `perf-assist/auto-translate-source-key` draft PR's
  CI. The next backlog candidate is **P15** (plain cue text derived twice per
  row + FIFO parse cache), then **P16** (echo card eager build).

## Sandbox facts this run
- The writable Flutter SDK copy at `/tmp/gh-aw/agent/flutter-3.47.6` must be
  re-created each run (`cp -a` from the toolcache) — recipe in `commands.md`.
- **Cold `pub get` can exceed a 10-minute background cap** (524 MB of
  packages). The killed wrapper takes the dart child with it; the warm
  `~/.pub-cache` survives, so a plain re-run finishes in ~1 min. Budget for
  it: start pub get FIRST, then do read-only work while it downloads.
- **`pgrep -f "pub get"` matches your own watcher shell** (the pattern is in
  its own command line) — an `until ! pgrep ...` watcher never exits. Stop it
  with TaskStop; poll the artifact instead (e.g. the output file or
  `package_config.json`).
- Baseline this run: full suite **6983 passed / 15 skipped** AFTER the change
  (the change adds 3 passing tests + 2 skips). No pre-change baseline was
  measured this run — main had moved (#1159–#1165) since the last baseline.
- Concurrent-benchmark mistake made and fixed: launch A/B bench loops
  SEQUENTIALLY, never in parallel (methodology: never benchmark on a busy
  machine).

## Repo state at this run
- HEAD on `main` at run start: `1a98abb2` (fix(ui) #1165); P14's merge
  `aa106dc7` is 9 commits back — already in the tree.
- **No open `[perf-improver]` PRs** at run end (P14 merged this morning).
- repo-assist **PR #1124 (P6 startup bulk read) MERGED 2026-10-28** — P6 is
  done and dropped from the backlog.
- Issue #864 IS readable this run (unlike 2026-10-25 → 2026-10-29), including
  its comments. **Repo Assist's 2026-10-28 comment on #864 reframed P3**:
  `vocabulary_item_dao.listDue` has NO production caller; the live over-fetch
  is `VocabularyReviewSessionLifecycle.start()` loading every vocabulary row
  incl. the `explanation` blob, filtering in Dart. Repo Assist deliberately
  did not implement it — needs a maintainer decision. Surfaced in the monthly
  summary's Suggested Actions.

## Tasks completed this run
- **Task 1**: commands already validated; re-created the SDK copy, applied
  the local sqlite3 pubspec workaround, pub get (cold, resumed after cap
  kill), analyze + full suite green.
- **Task 2**: re-verified P13 against the current tree (call sites at
  `transcript_line_item_builder.dart:126`, `transcript_echo_region_merged_card.dart:124`,
  controller `auto_translate_controller.dart:386` = cold path). P15 also
  re-verified (line 207 + 388, unchanged).
- **Task 3**: **DONE.** Branch `perf-assist/auto-translate-source-key`,
  commit `a3c1c4a8`, draft PR via the safe-outputs tool (bundle 6.0 KB /
  patch 14.8 KB under `/tmp/gh-aw/`). Details in `backlog.md` (P13).
- **Task 4**: P14's PR #1142 merged — no open perf PRs to maintain.
- **Task 5**: no action — no open performance-labeled issues besides #864;
  Repo Assist's analysis of P3 was folded into the monthly summary instead
  of a duplicate comment.
- **Task 6**: no new infrastructure this run (the P13 perf test follows the
  established env-var bench pattern; `docs/perf-measurement.md` index
  updated in the PR).
- **Task 7**: updated issue #864 (replace; body was readable this time —
  carried P7/P8/P10b actions forward, dropped the merged P14 review action,
  added the P3-reframed decision).

## P13 — what shipped (details in `backlog.md`)
`resolveAutoTranslateSecondaryText` derived the expected SHA-256 source key
from scratch for every visible row on every rebuild (markup parse + regex
collapse + utf8 + sha256 + hex + substring). The expected key is now memoized
per primary `TranscriptLine` instance in an `Expando` (P12 pattern; the entry
records the language pair and re-derives when it changes). The public
`autoTranslateSourceKey` is unchanged; the controller's per-request path is
untouched.

Measured (one impl per fresh process, n=4 per mode, legacy mode
re-implements the old body in the test file; identical sinks across all 8
runs): visible-window rebuild (40 rows) 0.347 → 0.010 ms/pass (~35x median,
~21x worst pairing); 512-line sweep 0.422 → 0.007 ms/pass (~60x median,
~42x worst pairing). The before-cost degrades on the sweep (parse-cache
overflow); the after-cost does not.

Status: draft PR open on `perf-assist/auto-translate-source-key`. The PR
number is assigned when the framework pushes the bundle — not known during
the run.

## Write path
- PRs must go through the safe-outputs `create_pull_request` tool; the
  framework pushes the bundle afterwards, so the PR may not be visible via
  the API immediately. Expected, not a failure.
- `update_issue` (`target: "*"`): **`issue_number` must be passed
  explicitly**, and `max: 1` — one write per run.
- The perf-improver workflow uses `protected-files: fallback-to-issue`, so a
  PR touching `.github/workflows/**` becomes an issue instead.
- `create_pull_request` adds the `[perf-improver] ` title prefix itself —
  do **not** put it in the title you pass.
- `.dart_tool/package_config.json` is a real pub-generated config
  (gitignored); leaving it saves the next run a (warm) `pub get`. The
  `~/.pub-cache` (524 MB) also persists only within this sandbox lifetime —
  wiped between runs.

## Open blockers / standing decisions
- The monthly summary for 2026-10 stays open until 2026-11; close it and
  open a new one in November.
- `test/perf/` dir + benchmark CI job stay deferred per
  `docs/perf-measurement.md` — do not add them unilaterally.
- P7 / P8 / P10b / P3-reframed all wait on maintainer decisions (surfaced in
  the monthly summary each run).
