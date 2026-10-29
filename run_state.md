# Perf Improver run state

- **Last run:** 2026-10-29 (workflow run 40862808812, run #74) — seventeenth
  October run, fifth run to produce a code-changing PR.
- **Run history:** #74 2026-10-29 (40862808812) shipped P14 → draft PR on
  `perf-assist/recording-count-sweep`. #73 2026-10-28 (40675246196) shipped
  P12 → PR #1127, **MERGED by an-lee 2026-10-28**. #72 2026-10-27
  (40485464164) shipped P11 → PR #1100, **MERGED by an-lee 2026-10-27**.
  #71 2026-10-25 (40225340975) shipped P10 → PR #1071, **MERGED by an-lee
  2026-10-26**. #66 2026-10-20 (39489542383) shipped P9 → PR #1006, **MERGED
  by an-lee 2026-10-20**. Runs #59–#65 (2026-10-13 → 2026-10-19) and
  #67–#70 (2026-10-21 → 2026-10-24) produced no code change.
- **Next run:** check the `perf-assist/recording-count-sweep` draft PR's CI.
  The next backlog candidate is **P13** (auto-translate source-key SHA-256),
  then **P15** (plain cue text derived twice per row).

## THE BIG CHANGE 2026-10-28 — the sandbox can run the full gate
PR #1111 ("ci(agents): allow the dart ecosystem in the Perf Improver sandbox")
added `dart` to the `network.allowed` list in
`.github/workflows/perf-improver.md`. **`pub.dev` now answers HTTP 200**, so
`flutter pub get`, `flutter analyze` and `flutter test` all work in the
sandbox. The multi-run "HARD BLOCKER" in `commands.md` is **historical** —
read the 2026-10-28 section at the top of `commands.md`, not the old
offline-harness recipe.

- `flutter analyze` → no issues.
- `flutter test` → **6930 passed / 10 skipped** before this run's change,
  **6935 passed / 12 skipped** after, in ~4:45.
- The one snag is `package:sqlite3`'s native asset: it downloads the
  prebuilt Linux library from github.com, which is still blocked. The
  workaround (a temporary `hooks: user_defines: sqlite3:` block in
  `pubspec.yaml` pointing at the system library) is documented in
  `commands.md`. **Never commit it** — `git diff pubspec.yaml` before every
  commit.

## Repo state at this run
- HEAD on `main` was `4e6c00d` (ci(release): verify platform assets, #1141).
- **No open `[perf-improver]` PRs** at the start of the run. PR #1127 (P12)
  merged on 2026-10-28 — Perf Improver's **fourth** merged code-changing PR.
- Open PRs by other agents: #1140 (repo-assist release v0.10.3). PR #1124
  (repo-assist startup bulk read) **claims P6** — do not duplicate it.
- **No readable open issues.** The MCP integration drops all open issues
  (including #864) via its integrity policy; a `performance`-label query
  returns `[]`. Task 5 has no target and correctly took no action — do not
  manufacture one. #864's **body and comments are unreadable**, so the
  monthly summary is written from scratch each run (`operation: replace`);
  the check-off state is carried from memory (nothing recorded as checked
  off).
- The Perf Improver **Actions** API *is* readable, so the monthly summary's
  run history can be rebuilt from
  `actions_list(method=list_workflow_runs, resource_id=perf-improver.lock.yml)`.
  October 2026 runs are **#59–#74** (2026-10-13 → 2026-10-29). The run
  numbers **skip #53–#58** — the workflow was idle 2026-08-31 → 2026-10-13.
  The JSON is nested: `d[0]['structuredContent']['workflow_runs']['workflow_runs']`
  (the MCP tool wraps it in a `_meta`/`content`/`structuredContent` envelope).

## Tasks completed this run
- **Task 1**: rebuilt the writable Flutter SDK copy, resolved dependencies,
  and established a **green baseline** (6951 passed / 12 skipped).
- **Task 2**: re-verified the backlog against the current tree; confirmed
  P12 merged, P13/P15/P16 still open, P6 still claimed by repo-assist.
- **Task 3**: **DONE.** Branch `perf-assist/recording-count-sweep`,
  commit `00031fa`, draft PR opened via the safe-outputs tool. Details in
  `backlog.md` (P14).
- **Task 4**: no open perf PRs to maintain; #1127 merged.
- **Task 5**: no action — no readable target.
- **Task 6**: added the repo's fifth local-only microbenchmark
  (`test/features/transcript/transcript_recording_counts_perf_test.dart`),
  linked from `docs/perf-measurement.md`. The `test/perf/` dir + benchmark CI
  job stay deferred per that doc — do not add them unilaterally.
- **Task 7**: updated issue #864 in the mandated format (replace; the body
  was unreadable).

## P14 — what shipped (details in `backlog.md`)
`countRecordingsPerLineIndex` applied the overlap rule to every recording
for every cue — O(cues × takes) — and the whole set is recomputed on every
transcript revision (the provider watches the lines stream) and again on the
practice-poster path. The recording windows are now projected onto two
sorted lists (start times, end times) and each cue is resolved with two
binary searches: `#{started before the cue ends} - #{ended at or before the
cue starts}`. The two sets are nested, so the difference is the overlap
count. Non-positive-length windows never overlap anything and are excluded.

Measured (separate processes per implementation, `flutter test --run-skipped`,
n=4 process pairs): 2000 cues × 200 takes 0.938 → 0.288 ms/pass (~3.3x
median, ~2.3x worst pairing); 4000 cues × 800 takes 6.988 → 0.519 ms/pass
(~13.5x median, ~10.1x worst pairing). The output sink is identical across
all eight process runs at both scales.

Status: draft PR open on `perf-assist/recording-count-sweep`. The PR number
is assigned when the framework pushes the bundle, so it was **not** known
during the run — the monthly summary references the branch instead.

## P12 — what shipped (details in `backlog.md`)
`wordIpaSpelling` (the familiar-form IPA) was derived from scratch every
time it was asked for: once per word of a row on every row rebuild, once
more per word for a boolean, and once per line across the whole transcript
in `transcriptDisplayReadiness`. It is now memoized per `TranscriptWord` in
a weak-keyed `Expando` (an entry dies with the word → **no eviction story**,
which was the risk P11 left open), and the readiness scan short-circuits once
its monotone flags are known.

Measured (separate processes per implementation, `flutter test --run-skipped`,
n=3): visible-window rebuild (480 words) 1.910 → 0.083 ms/pass (~23x median,
~16x worst pairing); readiness scan (2000 fresh lines) 2.992 → 0.053 ms/pass
(~56x median, ~24x worst pairing). The output sink is byte-identical.

Status: **PR #1127 MERGED by an-lee on 2026-10-28.**

## Write path
- PRs must go through the safe-outputs `create_pull_request` tool. It does
  not push itself; it writes a bundle + patch under `/tmp/gh-aw/` and the
  framework pushes afterwards, so the PR may not be visible via the API
  immediately. Expected, not a failure. Artifacts this run:
  `aw-baizhiheizi-enjoy_player-perf-assist-ipa-spelling-memoization.bundle`
  (5.3 KB) / `.patch` (17.2 KB).
- Same for `update_issue`: it returns `{"result":"success"}` but the issue
  body may lag. Do not re-issue a write just because the API has not caught up.
- `update-issue` in `.github/workflows/perf-improver.md` is `target: "*"`,
  so **`issue_number` must be passed explicitly**, and `max: 1` — one write
  per run.
- The perf-improver workflow uses `protected-files: fallback-to-issue`, so a
  PR touching `.github/workflows/**` becomes an issue instead.
- `create_pull_request` adds the `[perf-improver] ` title prefix itself —
  do **not** put it in the title you pass.
- `.dart_tool/package_config.json` is now a **real** pub-generated config
  (gitignored). The old advice to delete it at the end of a run applied to
  the hand-written offline harness and no longer applies; leaving it saves
  the next run a `pub get`.

## Open blockers / standing decisions
- ~~The `network.allowed` gap~~ — **RESOLVED 2026-10-28 by #1111**. The
  suggested action is gone from the monthly summary.
- The monthly summary for 2026-10 stays open until 2026-11; close it and
  open a new one in November.
