# Perf Improver run state

- **Last run:** 2026-10-09 (workflow run 37992822450) — second run, still blocked.
- **Previous run:** 2026-10-08 (workflow run 37781547756) — first run, set up memory + backlog + issue #864.

## Tasks completed this run
- Task 1 (commands): VERIFIED toolchain update. Toolcache now ships `flutter-3.47.6-stable`
  (matches `mise.toml` pin exactly). Read-only quirk unchanged. Old 3.44.0 copy is obsolete;
  the workable writable-copy path is now `/tmp/gh-aw/agent/flutter-3.47.6/flutter/bin/flutter`.
  Pub.dev remains firewalled (403), so `flutter analyze`/`flutter test` still cannot run.
- Task 2 (opportunities): Re-verified P1 + P2 targets are still present in main (no merged
  fixes between the two runs). Enriched P1 with a concrete structural-test suggestion.
- Task 3 (implement): BLOCKED. Same pub.dev network policy. No code-changing PR opened.
- Task 4 (PRs): N/A — no `[perf-improver]` PRs exist yet (the previous round didn't open one).
- Task 5 (issues): No open issues labeled `performance` (the 38 historically-labeled issues are
  all CLOSED; PR #864 is the only open `[perf-improver]` issue, which is the monthly summary).
- Task 6 (measurement infra): Confirmed `test/data/subtitle/subtitle_parser_test.dart` exists;
  the deferred microbenchmark from `docs/perf-measurement.md` would still need a networked runner.
- Task 7 (monthly summary): Updated issue #864 (in progress this turn).

## Work in progress
- NONE. No branch, no code changes, no PR from this run.

## Open blockers / environment constraints
- Sandbox has NO network access to pub.dev (firewall 403). `.dart_tool/package_config.json` does
  not exist. `flutter pub get --offline` fails on `flutter_launcher_icons` (cache incomplete).
- Consequence: cannot satisfy the AGENTS.md "every edit must be green" gate, so no
  code-changing PR can be opened from this sandbox. Implementation must happen on a networked
  runner or be handed to a maintainer.

## Next run suggestions (round-robin)
- Task 3 (implement): pick up P1 (sweep-line rewrite) on a NETWORKED runner. The structural
  test sketch is in backlog.md. Without network, revisit in a follow-up workflow run.
- Task 5 (comment on perf issues): revisit if a new perf-labeled issue opens.
- Task 6 (measurement infra): the subtitle-parser microbenchmark (5k-line SRT) is the
  lowest-risk, highest-value deferral — author it on a networked runner.
- Re-read the monthly summary issue (and any maintainer comments) before further work.