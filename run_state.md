# Perf Improver run state

- **Last run:** 2026-10-10 (workflow run 38083345073) — third run, still network-blocked.
- **Previous runs:**
  - 2026-10-09 (37992822450) — second run, still blocked; toolcache verified at 3.47.6.
  - 2026-10-08 (37781547756) — first run, set up memory + backlog + issue #864.

## Tasks completed this run
- Task 1 (commands): Re-verified `flutter-3.47.6-stable` still in toolcache. Pub.dev still 403 (HTTP 000 / no response — `curl --max-time 5 https://pub.dev/` returns nothing). Old 3.44.0 copy is OBSOLETE; use `/tmp/gh-aw/agent/flutter-3.47.6/flutter/bin/flutter` if a writable copy is needed.
- Task 2 (opportunities): Re-verified P1 (`countRecordingsPerLineIndex`) + P3 (`vocabulary_item_dao.listDue`) targets still present in main. Only commit since 10-08 is `d51b965` (merge PR #885, lookup credits chip) — no impact on the backlog.
- Task 3 (implement): **STILL BLOCKED**. Pub.dev unreachable; `flutter pub get` cannot succeed; `flutter analyze`/`flutter test` cannot run; AGENTS.md "every edit must be green" gate cannot be satisfied from this sandbox. No code-changing PR opened.
- Task 4 (PRs): N/A — only 1 open PR in the repo (#887 from repo-assist, `test-lookup-credits-banner-and-reporting`); no `[perf-improver]` PRs to maintain.
- Task 5 (issues): No open issues labeled `performance` except #864 itself (the monthly summary). Repo-assist's #841 (auto-managed) is unrelated. No comment-worthy open perf issues.
- Task 6 (measurement infra): Confirmed `test/data/subtitle/subtitle_parser_test.dart` exists; the only `*perf*` test is `test/features/transcript/transcript_blur_long_list_perf_test.dart`. The deferred 5k-line SRT microbenchmark and a dedicated `test/perf/` dir are still open deferrals per `docs/perf-measurement.md`. Cannot author from this sandbox (no test runner).
- Task 7 (monthly summary): Updated issue #864 with this run's entry.

## Work in progress
- NONE. No branch, no code changes, no PR from this run.

## Open blockers / environment constraints (unchanged)
- Sandbox has NO network access to pub.dev (firewall). `.dart_tool/package_config.json` does not exist. `flutter pub get --offline` fails on `flutter_launcher_icons` (cache incomplete).
- Repo Assist run on 2026-10-10 (38071724408) recorded 8 blocked domains including `api.github.com`, `cocoapods.org`, `maven.google.com`, `storage.googleapis.com`, `releaseassets.githubusercontent.com`, `www.googleanalytics.com` — same egress lockdown.
- Consequence: cannot satisfy the AGENTS.md "every edit must be green" gate, so no code-changing PR can be opened from this sandbox. Implementation must happen on a networked runner or be handed to a maintainer.

## Next run suggestions (round-robin)
- Task 3 (implement): pick up P1 (sweep-line rewrite) on a NETWORKED runner. The structural test sketch is in backlog.md. Without network, revisit in a follow-up workflow run.
- Task 5 (comment on perf issues): revisit if a new perf-labeled issue opens.
- Task 6 (measurement infra): the subtitle-parser microbenchmark (5k-line SRT) is the lowest-risk, highest-value deferral — author it on a networked runner.
- Re-read the monthly summary issue (and any maintainer comments) before further work.