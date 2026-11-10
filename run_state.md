# Perf Improver run state

- **Last run:** 2026-11-10 (workflow run 42820468336). **P21 RE-SHIPPED**
  after the 2026-11-09 run's writes failed to publish AGAIN (no P21 PR in
  any state; that run's #1192 update never landed — second silent
  publication failure after 11-05). Rebuilt on current `main`
  (`6a107cc2`, targets survived #1283/#1296): commit `33b82bdc` on
  `perf-assist/date-format-cache`; bundle recorded (patch 13.7 KB /
  300 lines). #1192 fully rewritten (replace): P20 action removed,
  P21 review action added, backlog → twelve-merged, run history gained
  the 11-09 (missed) + 11-10 entries.
- **PUBLICATION VERIFICATION (first job next run):** the framework
  applies safe-output writes AFTER the run ends; in-run GitHub reads
  show pre-write state (trust the success result, don't re-read). But
  recorded writes have now failed to reach GitHub in 2 of the last 3
  runs (11-05, 11-09), so VERIFY ON GITHUB: search PRs by the
  `[perf-improver]` TITLE PREFIX or list recent PRs — NEVER by exact
  local branch name (framework publishes suffixed names). If the
  2026-11-10 P21 PR did not land, re-ship from the backlog P21 section
  notes. **TWELVE merged perf-improver PRs** (#1006, #1071, #1100,
  #1127, #1142, #1167, #1175, #1191, #1203, #1218, #1228, #1258).
- **Next run:** (1) verify the P21 PR published + #1192 rewrite landed;
  check CI; maintain. (2) P21b candidates, all re-confirmed on main
  TODAY with exact lines: `credits_usage_log_views.dart:146`
  (`DateFormat.Hm()` per table build) + `:262`
  (`DateFormat.yMMMd(localeName).add_jm()` per row),
  `sync_status_screen.dart:132` (`DateFormat.Hm(locale)`) + `:158`
  (inline `MMMd/yMMMd(locale).add_Hm()`), `home_screen.dart:224`
  (`DateFormat.MMMMEEEEd(locale)` per home build). Then: discover
  feed-tile thumbnail projection, vocabulary explanation-decode memo
  (post-#1247 file-layout re-verify STILL pending), `normalizeCraftText`
  per keystroke (LOW). (3) Unswept surfaces: ai feature, player
  non-transport. P7/P8/P3-reframed/P10b still wait on maintainer
  decisions (#1192).

## Sandbox facts this run
- Cold `pub get` on the fresh sandbox: ~10 min (557 MB cache) — start
  it FIRST in the background, in one shell; it finished inside the
  default window this time.
- SDK tar-pipe copy to `/tmp/gh-aw/agent/flutter-3.47.6` fine (~1 min).
- Full suite: **7198 passed / 28 skipped, ~22 min** (exit 0) with the
  writable SDK on PATH + the sqlite3 `source: system` pubspec override
  (REVERTED before commit; verified absent from `33b82bdc`). Keep
  timeout 1800000 for background suite runs.
- Bench A/B this run needed NO env vars: each arm is its own
  skip-marked `--plain-name` test; 8 sequential single-mode processes.

## P21 re-ship — measurements (2026-11-10, this box)
- 502-row pass; per round 200 warmup passes + 30 samples, 3 rounds,
  round medians; sink per pass = sum of label lengths, IDENTICAL
  between arms in all 8 process runs (1978920 relative-day /
  6935190 craft):
  - craft `yMMMd().add_jm()` fresh 3.026–4.555 → cached 0.130–0.169
    ms/pass (~26x median, worst pairing ~18x).
  - relativeDayLabel `MMMd` fresh 0.701–0.757 → cached 0.075–0.130
    ms/pass (~6.2x median, worst ~5.4x). (11-09 box measured ~9.5x /
    ~22x — cross-box JIT spread; report today's pairing.)
- Structural tests: differential en/de/ja × 502 dates vs fresh
  constructions through the REAL cached path; per-locale cache-key
  distinctness (pairwise-distinct labels); craft-shape fresh-vs-cached
  differential via a local replica map; craft widget-subtitle oracle in
  `craft_history_test.dart`; 4 skip-marked benches in
  `test/core/presentation/relative_day_label_perf_test.dart`.
- GOTCHA that cost an analyze round: do not name the row-count int and
  the rows list the same (`_kRows` twice → duplicate definition, loops
  iterate the int).

## Write path
- `create_pull_request` P21 bundle recorded 2026-11-10 (success).
- `update_issue` #1192 `target:'*'` + `operation:'replace'` recorded
  2026-11-10 (success) — in-run read showed old body (expected).
- `create_pull_request` / `create_issue` add the `[perf-improver] `
  title prefix themselves — do NOT put it in the title.
- Do NOT retype historical run-history entries from memory when
  rewriting #1192 — copy them verbatim from the previous read (retyped
  entries drift in small detail).

## Open blockers / standing decisions
- P7 / P8 / P10b / P3-reframed wait on maintainer decisions (#1192).
- `test/perf/` dir + benchmark CI job stay deferred per
  `docs/perf-measurement.md` — do not add them unilaterally.
- The November monthly issue (#1192) must be closed and a 2026-12 one
  opened when December starts.
