# Perf Improver run state

- **Last run:** 2026-11-04 (workflow run 41830328066, run #80) — eleventh
  run to produce a code-changing PR. Shipped **P19** (ASR timeline build
  join-per-step → incremental length + last-word terminator bit) → draft
  PR on `perf-assist/asr-timeline-incremental` (commit `1219fae8`).
  PR number assigned when the framework pushes the bundle.
- **P18 MERGED as #1218 by an-lee on 2026-11-04 00:19 UTC → TEN merged
  code-changing PRs total** (#1006, #1071, #1100, #1127, #1142, #1167,
  #1175, #1191, #1203, #1218).
- **Next run:** (1) find the P19 PR number (search "perf-improver
  in:title"), check CI/GitGuardian, keep it healthy. (2) Code-level
  backlog **EMPTY again** — P7 / P8 / P3-reframed / P10b all wait on
  maintainer decisions (November monthly issue #1192). (3) Unswept
  surfaces for round-robin: lookup + vocabulary presentation, craft
  (non-recording), ai feature, discover, player non-transport. Verify
  callers before optimizing (P3 trap).

## Sandbox facts this run
- SDK copy + pub get warm (~4 min total incl. sqlite3 hooks override +
  re-pub-get). Full suite after P19: **7096 passed / 24 skipped**
  (~5 min; 7056/21 → +40 from #1226/#1227 merges + 5 new here).
- Blobless clone still: use GitHub MCP `get_commit` (detail=stats) for
  commit file lists.
- Bench this run: env `ASR_TIMELINE_BENCH_MODE=legacy|incremental` in
  `test/features/asr/domain/asr_timeline_builder_perf_test.dart`
  (default = incremental), n=3 fresh processes per arm, sequential —
  legacy arms were tight (9.4–10.05 ms); incremental word arm spread
  1.6–3.1 ms across rounds (JIT tiers) — report median + worst pairing.
- flutter_tester noise note in commands.md (2026-11-03) still applies.

## Repo state at this run
- HEAD on `main` at run start: `cc3dee0e` (#1227); #1226 (sync paging
  consolidation) also landed this run-start window.
- Open perf-improver PRs after this run: the P19 draft (number assigned
  post-run).
- Monthly: November issue is **#1192** (open, still no maintainer
  comments as of 13:04 UTC 2026-11-04; updated this run: removed the
  merged-P18 review action, added the P19 review action, prepended run
  history, backlog rewritten).

## Tasks completed this run
- **Task 1**: commands revalidated (SDK copy → pub get → analyze →
  smoke test → full suite); no new discovery (see `commands.md`).
- **Task 2**: sweeps — all 15 CustomPainters read directly (clean);
  share_poster domain traced to a one-shot sheet-open call (cold);
  `paintLogoMarkPlanes` saveLayer flagged as DESIGN territory
  (ADR-0093); Explore agent swept sync + ASR: sync post-#1226 refactor
  clean, ASR timeline builder = live finding.
- **Task 3**: **DONE** — P19. Word path ~9.5 → ~1.9 ms per 18k-word
  build (~5x), segment ~4.2x, plain ~1.3x; byte-identical sinks
  (95212/52623/115751) in all 24 process runs; curated boundary corpus
  × 6 param variants + 300 fuzz cases, 0 mismatches.
- **Task 4**: P18 #1218 found MERGED; no open perf-improver PRs to
  maintain at run start.
- **Task 5**: #1192 only open performance-labeled issue, no new human
  comments → no comments posted.
- **Task 6**: P19 perf test follows the differential + env-selected
  skip-marked bench pattern; `docs/perf-measurement.md` index updated
  in the PR.
- **Task 7**: updated #1192 (removed merged-P18 action, added P19
  review action, prepended run history).

## P19 — key implementation notes (details in `backlog.md`)
1. Equivalence argument: joined line's last char == last word's last
   char (join adds no trailing content); length additive with the
   1-char separator. Kept words always have non-empty text
   (`trim().isEmpty` skip + single leading-space strip).
2. Segment path appends to the SAME list (no aliasing: emitted `_Line`s
   are never mutated after `lines.add`).
3. `_endsWithTerminator` compares last code unit against a code-unit
   set (substring semantics identical — all terminators single BMP).
4. Differential test needs
   `import 'package:flutter_test/flutter_test.dart' hide
   collapseWhitespace;` — flutter_test's matcher ALSO exports a
   `collapseWhitespace` (ambiguous-import otherwise).
5. `AsrResult`/`AsrSegment`/`AsrWord` are `final class` with const
   constructors — fully-const curated fixtures trigger
   prefer_const lints on inner nodes; drop inner `const` when the
   outer context is const.

## Write path
- PRs via safe-outputs `create_pull_request`; PR number assigned when
  the framework pushes the bundle — not visible via API immediately.
- `update_issue` supports full-body rewrites (target: '*' config, so
  issue_number 1192 works).
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
