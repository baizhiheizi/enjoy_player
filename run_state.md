# Perf Improver run state

- **Last run:** 2026-11-05 (workflow run 42029725619, run #81) — twelfth
  run to produce a code-changing PR. Shipped **P20** (lookup credits
  summary refresh dedupe) → draft PR on
  `perf-assist/lookup-credits-refresh-once-per-result`. PR number assigned
  when the framework pushes the bundle.
- **P19 MERGED as #1228 by an-lee on 2026-11-04 14:34 UTC → ELEVEN
  merged code-changing PRs total** (#1006, #1071, #1100, #1127, #1142,
  #1167, #1175, #1191, #1203, #1218, #1228). No open perf-improver PRs
  existed at this run's start.
- **Next run:** (1) find the P20 PR number, check CI, keep healthy.
  (2) Code-level backlog: P20b leftovers ( DateFormat hoist, discover
  thumbnail projection, vocabulary explanation decode memo) are the
  ready-to-ship candidates — prefer the **vocabulary explanation decode
  memo** (MEDIUM, classic pattern) or the **DateFormat hoist** (tiny,
  trivially safe). (3) Unswept surfaces: ai feature, player
  non-transport. P7/P8/P3-reframed/P10b still wait on maintainer
  decisions (November monthly issue #1192).

## Sandbox facts this run
- SDK copy + pub get + analyze ~5 min. Full suite: killed at the 10-min
  background cap on the first attempt (throwaway measurement ran
  concurrently — avoid); restarted with timeout=1800000. Wait for its
  result in the next section.
- Bench this run: intl DateFormat fresh construct+format **6.09 µs**
  vs cached format **0.22 µs** per call (standalone dart,
  `initializeDateFormatting` from `package:intl/date_symbol_data_local.dart`
  — NOT `date_symbols.dart`).
- DraggableScrollableSheet does NOT rebuild its builder per drag frame:
  the SDK passes `widget.builder(...)` as the ValueListenableBuilder's
  `child` (flutter/widgets/draggable_scrollable_sheet.dart build()) —
  an Explore sweep claim to the contrary was WRONG; verify in the
  writable SDK copy before believing rebuild-storm claims.

## Repo state at this run
- HEAD on `main` at run start: `1bc67771` (#1241). Since P19: #1233
  (assessment widgets split), #1234 (docs), #1239 (AGP9/FFmpeg/popover
  refactor), #1240 (ai test), #1241 (deps bump).
- Open perf-improver PRs after this run: the P20 draft (number assigned
  post-run).
- Monthly: November issue is **#1192** (open, ZERO maintainer comments
  as of this run; updated this run: removed the merged-P19 review
  action, P20 review action added, run history prepended, backlog
  rewritten to 11-merged state).

## Tasks completed this run
- **Task 1**: commands revalidated (pub get → analyze → targeted tests);
  no new discovery.
- **Task 2**: two Explore sweeps — lookup+vocabulary (found the P20
  HIGH finding + vocabulary decode MEDIUM + options LOW) and craft+
  discover (DateFormat, thumbnail, keystroke normalize; feed pipeline
  verified clean). The lookup agent died with a 503 mid-sweep and was
  resumed successfully via SendMessage.
- **Task 3**: **DONE** — P20. Legacy 7 fetches → 2 fetches for
  1 display + 5 same-result rebuilds; flat thereafter. 4 new structural
  tests.
- **Task 4**: P19 #1228 found MERGED; no open perf-improver PRs to
  maintain.
- **Task 5**: #1192 only open performance-labeled issue, zero new
  human comments → no comments posted.
- **Task 6**: P20 structural test follows the fetch-count pattern;
  legacy-replica A/B measured via a throwaway test (deleted).
- **Task 7**: updated #1192 (removed merged-P19 action, added P20
  review action, prepended run history).

## P20 — key implementation notes (details in `backlog.md`)
1. Dedupe lives in `_refreshCreditsSummary` via `identical()` on the
   result/error token per section; `clear`/`report` post-frame calls
   stay unconditional.
2. The `data:`/`error:` branches run per BUILD — that is the bug; the
   fix dedupes instead of rewiring to `ref.listen` (lower risk, keeps
   the FutureBuilder-based contextual section untouched).
3. Identity-based dedupe aligns with AI-result cache hits (same
   instance = no new spend = no refresh) and force-refresh (new
   instance = refresh).
4. Chip refetches on its own first watch after sheet reopen (provider
   is autoDispose), so the dedupe cannot strand a stale wallet.
5. Committed test host must watch `lookupCreditsExhaustedProvider` to
   keep the autoDispose notifier alive for post-frame writes.

## Write path
- PRs via safe-outputs `create_pull_request`; PR number assigned when
  the framework pushes the bundle — not visible via API immediately.
- `update_issue` supports full-body rewrites (target: '*' config).
- `create_pull_request` / `create_issue` add the `[perf-improver] `
  title prefix themselves — do NOT put it in the title.
- sqlite3 hooks override applied to `pubspec.yaml` for tests and
  REVERTED via `git checkout -- pubspec.yaml` before commit (verified
  absent from the commit).

## Open blockers / standing decisions
- P7 / P8 / P10b / P3-reframed all wait on maintainer decisions
  (surfaced in the November monthly issue #1192).
- `test/perf/` dir + benchmark CI job stay deferred per
  `docs/perf-measurement.md` — do not add them unilaterally.
- The November monthly issue (#1192) must be closed and a 2026-12 one
  opened when December starts.
