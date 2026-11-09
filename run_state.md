# Perf Improver run state

- **Last run:** 2026-11-09 (workflow run 42625002283) — fourteenth run to
  produce a code-changing PR. Shipped **P21** (locale-keyed DateFormat
  construction cache: craft-history tiles + `relativeDayLabel` rows) on
  `perf-assist/date-format-cache` (branch commit `0ed9111e`).
- **PUBLICATION VERIFICATION RULE (corrected this run):** the framework
  publishes the PR branch under a SUFFIXED name
  (`<branch>-<hash>`, e.g. P20 landed as
  `perf-assist/lookup-credits-refresh-once-per-result-acd53a97015b49b8`
  → PR **#1258**, MERGED by an-lee 2026-11-07 01:29 UTC). Verifying by
  exact branch name is unreliable — search by the `[perf-improver]`
  TITLE PREFIX or list recent PRs. Next run MUST verify the P21 PR
  exists (search `[perf-improver] perf(ui): construct the DateFormat`)
  and that #1192 shows the 2026-11-09 run-history entry. **TWELVE
  merged perf-improver PRs** (#1006, #1071, #1100, #1127, #1142, #1167,
  #1175, #1191, #1203, #1218, #1228, #1258).
- **Next run:** (1) verify P21 PR + #1192 published; check CI; maintain.
  (2) Ready-to-ship candidates, re-verify against current main first:
  discover feed-tile thumbnail projection (call sites re-confirmed
  unchanged this run), vocabulary explanation-decode memo (post-#1247
  re-verify STILL pending), `normalizeCraftText` per keystroke (LOW);
  plus the NEW follow-ups from P21: per-build DateFormat at
  `credits_usage_log_views.dart:146/:262`, `sync_status_screen.dart:132/:157`,
  `home_screen.dart:224`. (3) Unswept surfaces: ai feature, player
  non-transport. P7/P8/P3-reframed/P10b still wait on maintainer
  decisions (#1192).

## Sandbox facts this run
- **`cp -r` of the 2.3 GB SDK tree is UNRELIABLE here** — exits 0 with
  a partial tree (top-level files only, no directories). Use the tar
  pipe: `(cd $SRC && tar cf - .) | (cd $DST && tar xf -)`; verify
  `bin/flutter` exists afterwards.
- Writable SDK this run: `/tmp/gh-aw/agent/flutter-3.47.6/bin` (tar
  pipe copies the CONTENTS of the SDK dir).
- sqlite3 hooks override for ANY `flutter test` (native-assets build
  runs even for widget tests): append to pubspec.yaml
  `hooks:\n  user_defines:\n    sqlite3:\n      source: system` —
  system `libsqlite3.so` + `/usr/include/sqlite3.h` exist in this
  image. REVERT via `git checkout -- pubspec.yaml` before commit
  (verified absent from commit `0ed9111e`).
- Background-task timeout: a `flutter test` full-suite run with
  timeout 600000 was KILLED at the limit mid-suite; the suite took
  ~25 min this box (vs ~5 min on 11-06). Give the suite
  timeout 1800000+ when running in background.
- Suite this run: **7177 passed / 28 skipped** (full, green).
- `flutter analyze` + `dart format` (4 changed files, 0 changed) clean.

## Repo state at this run
- HEAD on `main` at run start: `7890e266` (#1284). Merged since 11-06:
  **#1258 (P20, merged 11-07)**, #1262 (macOS media_kit vendor — closed
  UNMERGED), #1268 (docs drift), #1269 (lockfile), #1274 (listResource),
  #1277 + #1285 (changelogs), #1283/#1284 (craft + transcript chrome
  dedup refactors). v0.10.3 shipped 11-06/07.
- Open perf-improver PRs after this run: the P21 draft (number assigned
  when the framework publishes the bundle).
- Monthly: November issue **#1192** (updated this run: P20 action
  removed as merged-#1258, P21 review action added, backlog rewritten
  to twelve-merged state, run history prepended).

## Tasks completed this run
- **Task 1**: commands revalidated (tar-pipe SDK copy, pub get,
  analyze, targeted + full suites). New facts: cp -r partial-tree
  gotcha; sqlite3 `source: system` user-define schema (read from
  sqlite3-3.9.0 hook source); background suite timeout guidance.
- **Task 2**: re-verified P20b candidates on current main; swept all 11
  DateFormat construction sites repo-wide (6 per-build hot, 3 warm,
  2 cold — hot/warm split recorded in backlog P21 section).
- **Task 3**: **DONE** — P21. Both caches + differential/per-locale-key
  tests + 4 skip-marked benches + craft subtitle oracle assertions +
  perf-measurement.md link.
- **Task 4**: no open perf-improver PRs to maintain at run start
  (P20 was already merged as #1258).
- **Task 5**: #1192 had zero comments → no comments posted.
- **Task 6**: no new infra this run (budget went to P21 + publication
  verification of the 11-06 writes).
- **Task 7**: #1192 rewritten (see above).

## P21 — key implementation notes
1. `putIfAbsent` closure, NOT a `DateFormat.yMMMd().add_jm` tear-off —
   the tear-off constructs the yMMMd formatter EAGERLY on every call
   (cache hit still pays construction).
2. Craft cache key = `Intl.getCurrentLocale()` (what intl's no-arg
   constructor resolves); relativeDayLabel keys on its explicit
   `locale` param. Both files import `package:intl/intl.dart` already.
3. Cache maps live at file bottom, mirroring `discover_age_label.dart`.
4. Bench harness: `_benchRows` helper (warmup 200, 30 samples, 3
   rounds, median printed with sink); one mode per process selected by
   `--plain-name`; run modes SEQUENTIALLY.
5. The per-locale-key structural test asserts en/de/ja labels are
   pairwise distinct through the cached path — fails if someone
   replaces the cache with one global formatter.

## Write path
- PRs via safe-outputs `create_pull_request`; verify publication NEXT
  run by TITLE search (branches publish suffixed). This run's P21
  bundle recorded successfully (patch 12.3 KB / 257 lines).
- `update_issue` with `target: '*'` + `operation: replace` works for
  full-body rewrites (#1192 verified landed after the 11-06 run).
- `create_pull_request` / `create_issue` add the `[perf-improver] `
  title prefix themselves — do NOT put it in the title.
- sqlite3 hooks override applied to `pubspec.yaml` for tests and
  REVERTED via `git checkout -- pubspec.yaml` before commit.

## Open blockers / standing decisions
- P7 / P8 / P10b / P3-reframed all wait on maintainer decisions
  (surfaced in the November monthly issue #1192).
- `test/perf/` dir + benchmark CI job stay deferred per
  `docs/perf-measurement.md` — do not add them unilaterally.
- The November monthly issue (#1192) must be closed and a 2026-12 one
  opened when December starts.
