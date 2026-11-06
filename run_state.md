# Perf Improver run state

- **Last run:** 2026-11-06 (workflow run 42218042013) — thirteenth run to
  produce a code-changing PR. **Re-shipped P20** (lookup credits summary
  refresh dedupe) on `perf-assist/lookup-credits-refresh-once-per-result`
  (branch commit `51d6efec`); PR number assigned when the framework pushes
  the bundle.
- **CRITICAL lesson from 2026-11-05 (run 42029725619): that run's
  safe-output writes NEVER PUBLISHED** — no PR and no issue update landed
  (the recorded "success" from the agent's perspective was not enough).
  **Next run MUST first verify the P20 PR actually exists** (list open
  PRs / search `perf-improver in:title`), and verify #1192's body shows
  the 2026-11-06 run-history entry. If the 11-06 writes also failed,
  escalate via report_incomplete rather than silently re-doing a third
  time.
- **P19 MERGED as #1228 by an-lee on 2026-11-04 14:33 UTC → ELEVEN
  merged code-changing PRs total** (#1006, #1071, #1100, #1127, #1142,
  #1167, #1175, #1191, #1203, #1218, #1228).
- **Next run:** (1) verify P20 PR + #1192 published; check CI; maintain.
  (2) Then pick from P20b leftovers: **vocabulary explanation decode
  memo** (MEDIUM — but #1247 "split vocabulary screen into focused
  widgets" merged 2026-11-06, RE-VERIFY file locations before
  implementing) or the **craft-history DateFormat hoist** (tiny,
  trivially safe, `craft_history_screen.dart:155` → locale-keyed cache
  pattern from `discover_age_label.dart:30`). (3) Unswept surfaces: ai
  feature, player non-transport. P7/P8/P3-reframed/P10b still wait on
  maintainer decisions (#1192).

## Sandbox facts this run
- Full suite needs the **writable SDK first on PATH**: the 3
  `test/tool/patch_agp9_pub_plugins_test.dart` cases (from #1239) shell
  out to `flutter` and die on the read-only toolcache otherwise; all 6
  pass with `PATH="/tmp/gh-aw/agent/flutter-3.47.6/flutter/bin:$PATH"`.
- **`flutter test 2>&1 | tail -8` MASKS the exit code** (pipeline exits
  with tail's 0). First suite run looked green while 3 tests failed;
  write full output to a file instead
  (`> /tmp/gh-aw/agent/log 2>&1; echo exit=$?`).
- Suite this run: **7149 passed / 24 skipped** (~5 min exclusive).
- Re-verified yesterday's intl bench facts and the DraggableScrollableSheet
  SDK finding — no change.

## Repo state at this run
- HEAD on `main` at run start: `4e47cf6f` (#1257). Since the 11-05 run:
  #1247 (vocabulary screen split), #1250 (FFmpeg input classification +
  ASR validation), #1252 (v0.10.3 docs), #1253/#1254/#1255/#1257
  (v0.10.3 release-runner fixes). **v0.10.3 release in progress.**
- Open perf-improver PRs after this run: the P20 re-publication draft
  (number assigned post-run).
- Monthly: November issue **#1192** (open, zero comments; updated this
  run: removed the merged-P19 action, added the P20 review action,
  backlog rewritten to 11-merged + P20b state, run history prepended,
  tool-test PATH caveat documented in Discovered Commands).

## Tasks completed this run
- **Task 1**: commands revalidated (writable SDK copy, pub get, analyze,
  targeted + full suites). New: PATH requirement for tool tests; tail-pipe
  exit-code masking gotcha.
- **Task 2**: no new sweeps (run budget went to the P20 rebuild +
  verification of the failed publish).
- **Task 3**: **DONE** — P20 re-ship. 6 call sites tokenized, 5 new
  structural fetch-count tests, docs updated (dictionary-lookup.md chip
  contract, perf-measurement.md index).
- **Task 4**: verified NO perf-improver PR was open (the 11-05 P20 bundle
  never landed; P19 already merged) — nothing to maintain.
- **Task 5**: #1192 zero comments → no comments posted.
- **Task 6**: the 5 committed structural tests follow the fetch-count
  override pattern (counting `creditsSummaryProvider.overrideWith`);
  harness mirrors real sheet topology (watcher widget + tick-driven
  scheduler, separate).
- **Task 7**: #1192 rewritten (see above).

## P20 — key implementation notes (details in `backlog.md`)
1. Dedupe lives in `_refreshCreditsSummary` via `identical()` on the
   result/error token per section; module-level
   `Map<LookupSectionId, Object> _lastTokenPerSection` (≤3 entries);
   `clear`/`report` post-frame calls stay unconditional.
2. Tokens: sections pass `resultToken: d` in `data:` branches;
   `lookupSectionErrorWidget` passes `resultToken: error` in all three
   branches. Untokened schedules (banner) always refresh.
3. Cache-hit re-emissions (same instance) skip the refresh — correct
   because no credits were consumed; force-refresh produces a fresh
   instance → refresh fires.
4. Test gotchas (all re-validated this run): host must watch
   `lookupCreditsExhaustedProvider` (autoDispose) or post-frame writes
   hit a disposed notifier; drive rebuilds via `ValueNotifier` +
   `ValueListenableBuilder`; initial pump = 2 fetches; NEVER re-pump a
   new ProviderScope mid-test (module-level token map persists across
   scopes and fresh watches make counts nondeterministic) — grow the
   section list across ticks in ONE scope instead; two first-time
   sections invalidating in one frame may batch — keep one new token per
   tick; `const Object()` canonicalizes — use `final Object()`.
5. `const token = Object()` vs plain — see gotcha 4.

## Write path
- PRs via safe-outputs `create_pull_request`; the tool's success result
  does NOT guarantee publication (11-05 lesson) — verify on the next run.
- `update_issue` with `target: '*'` + `operation: replace` works for
  full-body rewrites (issue_number: 1192 succeeded this run — but VERIFY
  it landed next run).
- `create_pull_request` / `create_issue` add the `[perf-improver] `
  title prefix themselves — do NOT put it in the title.
- sqlite3 hooks override applied to `pubspec.yaml` for tests and
  REVERTED via `git checkout -- pubspec.yaml` before commit (verified
  absent from commit `51d6efec`).

## Open blockers / standing decisions
- P7 / P8 / P10b / P3-reframed all wait on maintainer decisions
  (surfaced in the November monthly issue #1192).
- `test/perf/` dir + benchmark CI job stay deferred per
  `docs/perf-measurement.md` — do not add them unilaterally.
- The November monthly issue (#1192) must be closed and a 2026-12 one
  opened when December starts.
