# Perf Improver run state

- **Last run:** 2026-10-28 (workflow run 40675246196, run #73) — sixteenth
  October run, fourth run to produce a code-changing PR.
- **Run history:** #73 2026-10-28 (40675246196) shipped P12 → draft PR on
  `perf-assist/ipa-spelling-memoization`. #72 2026-10-27 (40485464164)
  shipped P11 → PR #1100, **MERGED by an-lee 2026-10-27**. #71 2026-10-25
  (40225340975) shipped P10 → PR #1071, **MERGED by an-lee 2026-10-26**.
  #66 2026-10-20 (39489542383) shipped P9 → PR #1006, **MERGED by an-lee
  2026-10-20**. Runs #59–#65 (2026-10-13 → 2026-10-19) and #67–#70
  (2026-10-21 → 2026-10-24) produced no code change.
- **Next run:** check the `perf-assist/ipa-spelling-memoization` draft PR's
  CI. It is the first code to use an `Expando` memo in `lib/data/subtitle/`.
  The next backlog candidate is **P13** (auto-translate source-key SHA-256).

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
- HEAD on `main` was `e5a79f60` (v0.10.2 release-gate tests, #1123).
- **No open `[perf-improver]` PRs** at the start of the run. PR #1100 (P11)
  merged on 2026-10-27 — Perf Improver's third merged code-changing PR.
- Open PRs by other agents: #1124 (repo-assist startup bulk read — this
  **claims P6**, do not duplicate it) and #1125 (repo-assist deps).
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
  October 2026 runs are **#59–#73** (2026-10-13 → 2026-10-28). The run
  numbers **skip #53–#58** — the workflow was idle 2026-08-31 → 2026-10-13.

## Tasks completed this run
- **Task 1**: the full toolchain now works (see above). Rebuilt the writable
  Flutter SDK copy, resolved dependencies, and established a **green
  baseline** (6930 passed / 10 skipped).
- **Task 2**: surveyed the transcript/player hot paths. Confirmed the
  familiar-form IPA memoization (P12) and re-verified P3, P7, P8, P10b by
  direct grep. Added **P13–P16** to the backlog (auto-translate SHA-256,
  recording counts O(n×m), the twice-derived plain cue text, the eagerly
  built echo card).
- **Task 3**: **DONE.** Branch `perf-assist/ipa-spelling-memoization`,
  commit `0cdd3495`, draft PR opened via the safe-outputs tool. Details in
  `backlog.md` (P12).
- **Task 4**: no other open perf PRs to maintain; #1100 merged.
- **Task 5**: no action — no readable target.
- **Task 6**: added the repo's fourth local-only microbenchmark
  (`test/data/subtitle/transcript_word_ipa_perf_test.dart`), linked from
  `docs/perf-measurement.md`. The `test/perf/` dir + benchmark CI job stay
  deferred per that doc — do not add them unilaterally.
- **Task 7**: updated issue #864 in the mandated format (replace; the body
  was unreadable).

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

Strategy choice, measured: an `Expando` beat an `L1Store`/`LinkedHashMap`
memo by ~3.5x — the map must hash the word's whole `phones` list under
value equality, while the `Expando` uses identity.

Status: draft PR open on `perf-assist/ipa-spelling-memoization`. The PR
number is assigned when the framework pushes the bundle, so it was **not**
known during the run — the monthly summary references the branch instead.

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
