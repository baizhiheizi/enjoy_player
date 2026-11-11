# Perf Improver run state

- **Last run:** 2026-11-11 (workflow run 43018170989). Verified the
  11-10 writes DID publish: **P21 = #1299, MERGED by an-lee on
  2026-11-11 → THIRTEEN merged perf-improver PRs** (#1006, #1071,
  #1100, #1127, #1142, #1167, #1175, #1191, #1203, #1218, #1228,
  #1258, #1299); the #1192 11-10 rewrite landed too (no maintainer
  comments). Publication-failure streak (11-05, 11-09) resolved.
- **P21b SHIPPED this run:** commit `037695e8` on
  `perf-assist/dateformat-once-per-locale-2` (bundle recorded 26.1 KB
  patch / 644 lines; #1192 replace recorded). Sites: credits usage
  table (`Hm` + `decimalPattern` per build) + card (`yMMMd(locale).add_jm()`
  per row), sync last-sync (`Hm(locale)`, composed `MMMd/yMMMd+Hm`),
  home overline (`MMMMEEEEd`). Measured (this box): card
  fresh 2.778–2.884 → cached 0.115–0.122 ms/502-row pass (~23–24x,
  2 pairs); table per-build ~1.1x (construction amortized over 50
  formats). Sinks identical in all runs. Full suite 7239 / 32 skipped.
- **Next run:** (1) verify the P21b PR published (TITLE-prefix search,
  never exact branch name) + #1192 rewrite landed; check CI; maintain.
  (2) Next candidates: subscription `_formatDate` (≤6 `yMMMMd` per
  card build, warm-but-quiet screen), discover feed-tile thumbnail
  projection (`remoteThumbnailForCard` = Uri.tryParse + ≤3 regex per
  tile per rebuild), vocabulary explanation-decode memo (post-#1247
  re-verify STILL pending), `normalizeCraftText` per keystroke (LOW).
  (3) Unswept: ai feature, player non-transport. P7/P8/P3-reframed/
  P10b still wait on maintainer decisions (#1192).

## Sandbox facts this run
- Toolcache SDK is read-only again → tar-pipe copy to
  `/tmp/gh-aw/agent/flutter-3.47.6` (~1 min) then pub get; whole
  setup ~3 min warm cache (fast this time, not 10).
- Full suite **7239 passed / 32 skipped, exit 0, ~22 min** with the
  writable SDK on PATH + sqlite3 `hooks: user_defines: source: system`
  pubspec override (REVERTED before commit; `037695e8` verified clean).
- Blobless clone: `git show <old-sha>` needs promisor fetch → fails;
  read merged-pattern files from the working tree instead.

## Lessons this run (all test/measurement-level)
- intl `DateFormat.add_*` → `addPattern` MUTATES and returns `this`:
  never cache a bare formatter and call `.add_Hm()` per render; cache
  fully composed at miss time. Stability test in the shapes file
  guards it.
- Riverpod trap: swapping provider overrides via a second `pumpWidget`
  on the same tester does NOT re-fire a watched future — the tree
  keeps the stale AsyncValue. Ship per-branch widget oracles as
  single-pump tests (one `testWidgets` per branch).
- Bench placement must mirror the real code: the cached table arm
  initially put `putIfAbsent` INSIDE the row loop (per-format hash
  lookups) and measured SLOWER than fresh; hoisting the lookup to
  build level (like the real widget) restored the true A/B.
- `NumberFormat.decimalPattern`: en and ja grouping are both comma —
  pairwise-distinctness assertions must use fresh-construction
  equality per locale instead (or en vs de only).
- flutter-test env: intl date symbols for the resolved locale are
  initialized by the localization delegates ('en' works without
  explicit `initializeDateFormatting`); `DecimalPattern('de')` works
  in flutter tests (probe-verified).

## Write path
- `create_pull_request` P21b bundle recorded 2026-11-11 (success).
- `update_issue` #1192 `target:'*'` + `operation:'replace'` recorded
  2026-11-11 (success) — in-run read shows pre-write state (expected).
- `create_pull_request` / `create_issue` add the `[perf-improver] `
  title prefix themselves — do NOT put it in the title.
- Do NOT retype historical run-history entries when rewriting #1192 —
  copy verbatim from the current issue read (retyping drifts).

## Open blockers / standing decisions
- P7 / P8 / P10b / P3-reframed wait on maintainer decisions (#1192).
- `test/perf/` dir + benchmark CI job stay deferred per
  `docs/perf-measurement.md` — do not add them unilaterally.
- The November monthly issue (#1192) must be closed and a 2026-12 one
  opened when December starts.
