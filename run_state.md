# Perf Improver run state

- **Last run:** 2026-10-25 (workflow run 40225340975, run #67) — fourteenth
  run. Second run to produce a code-changing PR.
- **Run history:** #66 2026-10-20 (39489542383) shipped P9 → PR #1006,
  **MERGED by an-lee 2026-10-20**. Runs 2026-10-09..10-19 (12 runs) were
  blocked on dependency resolution; 2026-10-08 was the first run.
- **Next run:** check the `perf-assist/timeline-revision-scan` draft PR's CI;
  it is the first real compile of the four `TranscriptRepository` part files.

## Repo state at this run
- HEAD on `main` was `669d127` (bump v0.10.1, #1047). Heavy maintainer
  activity since: #1007 (transcript_scrollable_list split — **the P7 file
  references in `backlog.md` are stale**), #1010, #1015, #1023, #1038,
  #1043, #1046, #1048, #1062.
- **No open `[perf-improver]` PRs** at the start of the run.
- **No readable open issues.** The MCP integration now drops all 9 open
  issues (including #864) via its integrity policy; a `performance`-label
  query returns `[]`. Task 5 had no target and correctly took no action —
  do not manufacture one.

## Environment
The egress proxy terminates TLS with an SNI guard (self-signed
`CN=awf-sni-guard.invalid`), so `pub.dev` and `github.com` are unreachable:
`flutter pub get` and `git push` fail with exit 60. **Do not route around
it.** The full offline-harness recipe (Dart VM + hand-written package config
+ `flutter`/`flutter_test` stubs), the stub requirements, and the
microbenchmark methodology are all in **`commands.md`** — read it rather
than re-deriving them.

Short version: pure-Dart hot paths CAN be measured, changed, and unit-tested
here; anything importing `package:drift` (including every
`TranscriptRepository` part file) cannot be compiled locally. **CI on
GitHub's runners is the authoritative gate** — say so in every PR body.

Two harness changes this run: the `flutter` stub also needs **`compute`**
(not just `listEquals`/`immutable`), and `flutter_test`'s `equals` must do
**deep** list/map comparison. Negative-control the stub (a failing `expect`
must exit non-zero) before trusting a green result.

## Tasks completed this run
- **Task 1**: re-validated the offline harness from scratch; extended the
  stubs.
- **Task 2**: the Explore subagent tasked with re-verifying backlog
  candidates P3/P6/P7/P8 **failed with a 503 from the inference gateway** (no
  results) — re-verify with direct greps instead of trusting a survey agent
  that did not return. P6 was confirmed still present by grep (four
  sequential `readSetting` awaits at
  `lib/core/application/app_preferences_provider.dart:113-120`). A **new**
  target was found outside the old backlog (P10).
- **Task 3**: **DONE.** Branch `perf-assist/timeline-revision-scan`, commit
  `fda2e6c`, draft PR opened via the safe-outputs tool. Details in
  `backlog.md` (P10).
- **Task 4**: no open perf PRs to maintain.
- **Task 5**: no action — no readable target.
- **Task 6**: added the repo's second local-only microbenchmark
  (`test/features/transcript/transcript_timeline_character_count_perf_test.dart`),
  linked from `docs/perf-measurement.md`. The `test/perf/` dir + benchmark
  CI job stay deferred per that doc — do not add them unilaterally.
- **Task 7**: updated issue #864 in the mandated format.

## P10 — what shipped (details in `backlog.md`)
The transcript decode memo is keyed on `(updatedAt, timelineJson character
count)`. The count was `json.runes.length` — a rune-by-rune walk of the whole
1–10 MB blob — and the repository derived that same revision **three times
per tick** plus once more per auto-translate flush. Fixed with a UTF-16
code-unit scan (identical to `String.runes.length` and SQLite `length()`)
and by deriving the revision once per row.

Measured (isolated processes, 100 warmup + 200 measured, 3 rounds):
5000 cues (573 KB) 3.138 → 0.137 ms (22.9x); 20000 cues (2.3 MB)
9.763 → 0.483 ms (20.2x). Scan-only 6.7–9.5x, redundancy-only 6.7–7.8x.
Correctness: 20,000 fuzz cases + curated edge cases vs `String.runes.length`,
0 mismatches.

Status: draft PR open on `perf-assist/timeline-revision-scan`. The PR number
is assigned when the framework pushes the bundle, so it was **not** known
during the run — the monthly summary references the branch instead.

## Write path
- PRs must go through the safe-outputs `create_pull_request` tool. It does
  not push itself; it writes a bundle + patch under `/tmp/gh-aw/` and the
  framework pushes afterwards, so the PR may not be visible via the API
  immediately. Expected, not a failure. Artifacts this run:
  `aw-baizhiheizi-enjoy_player-perf-assist-timeline-revision-scan.bundle`
  (6.8 KB) / `.patch` (18.7 KB).
- Same for `update_issue`: it returns `{"result":"success"}` but the issue
  body may lag. Do not re-issue a write just because the API has not caught up.
- **Issue #864's body AND comments are unreadable** (integrity policy), so
  the monthly summary cannot be re-read before it is updated — say so in the
  body and stay conservative about the check-off state.
- The perf-improver workflow uses `protected-files: fallback-to-issue`, so a
  PR touching `.github/workflows/**` becomes an issue instead.
- Delete `<repo>/.dart_tool/package_config.json` at the end of a run so a
  later `pub get` is not confused.

## Open blockers / standing decisions
- **The `network.allowed` gap** in `.github/workflows/perf-improver.md` (it
  omits `pub.dev`, `pub.flutter-io.cn`, `storage.flutter-io.cn`, while
  `ci.yml` already uses those mirrors) blocks `flutter pub get` for every
  run. **Deliberately not changed by this agent** — widening the agent
  runtime's egress allowlist is a security-boundary change and a maintainer
  decision. It is raised as a suggested action in the monthly summary.
- The monthly summary for 2026-10 stays open until 2026-11; close it and
  open a new one in November.
