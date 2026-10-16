# Perf Improver run state

- **Last run:** 2026-10-16 (workflow run 38957015222) — ninth run, still network-blocked.
- **Previous runs:**
  - 2026-10-15 (38798897827) — eighth run, still blocked.
  - 2026-10-14 (38631286522) — seventh run, still blocked.
  - 2026-10-13 (38471681114) — sixth run, still blocked.
  - 2026-10-12 (38321153103) — fifth run, still blocked.
  - 2026-10-11 (38172969613) — fourth run, still blocked.
  - 2026-10-10 (38083345073) — third run, still blocked; toolcache verified at 3.47.6.
  - 2026-10-09 (37992822450) — second run, still blocked; toolcache verified at 3.47.6.
  - 2026-10-08 (37781547756) — first run, set up memory + backlog + issue #864.

## Tasks completed this run
- Task 1 (commands): Same blocker re-verified. `curl --max-time 8` to `https://pub.dev` and `https://api.github.com` both return exit 60 (SSL certificate problem — self-signed cert in chain). `.pub-cache/hosted/pub.dev/` is empty (0 entries). `.dart_tool/package_config.json` absent. Writable Flutter copy at `/tmp/gh-aw/agent/flutter-3.47.6` still works and reports Flutter 3.47.6 stable, Dart 3.13.5.
- Task 2 (opportunities): No new commits on `main` since 2026-10-15 (HEAD = `14d5745` = PR #962 macOS sqlite3 fix). `search_pull_requests` with `[perf-improver]` returns 15 closed / 0 open. `list_issues` with `performance` label returns `[]` (MCP integrity filter strips #864 + #693). Backlog unchanged.
- Task 3 (implement): **STILL BLOCKED**. Ninth run in a row. AGENTS.md "every edit must be green" gate unsatisfiable from this sandbox. No code-changing PR opened.
- Task 4 (PRs): N/A — no open `[perf-improver]` PRs.
- Task 5 (issues): No new perf-labeled issues to engage with. `get_comments` on #864 returned `[]` — no maintainer guidance. No anti-spam risk; no perf-issue comments this run.
- Task 6 (measurement infra): Deferred 5k-line SRT microbenchmark and `test/perf/` dir still open deferrals per `docs/perf-measurement.md`. Cannot author from this sandbox.
- Task 7 (monthly summary): Updated issue #864 — prepended 2026-10-16 entry at the top of Run History (9 entries total now: 2026-10-08 through 2026-10-16). Body rewritten in full per format enforcement. SDK-path note refreshed (the SDK now nests under `…/toolcache/flutter-3.47.6-stable/flutter/`, restructured between 2026-10-14 and 2026-10-16). `update_issue` safe-output write succeeded in 666ms.

## Work in progress
- NONE. No branch, no code changes, no PR from this run.

## Open blockers / environment constraints (unchanged, plus SDK structure change)
- Sandbox has NO network access to pub.dev / api.github.com (SSL certificate problem exit 60). `.dart_tool/package_config.json` does not exist. `.pub-cache/hosted/pub.dev/` empty (0 entries). `flutter pub get --offline` fails on missing `flutter_launcher_icons`. `dart analyze <file.dart>` produces "Target of URI doesn't exist" errors for every package import.
- The CI-installed Flutter SDK has been restructured since 2026-10-14: the bin/ tree now nests under `/home/runner/.toolcache/flutter-3.47.6-stable/flutter/` (a `flutter/` subdir) instead of directly under the toolcache dir. The writable-copy recipe still works; the real SDK root inside the copy is `/tmp/gh-aw/agent/flutter-3.47.6/flutter/bin/flutter`. Updated in `commands.md`.
- The writable Flutter copy trick does NOT survive between workflow runs. Documented as ephemeral in `commands.md`.
- Consequence: cannot satisfy the AGENTS.md "every edit must be green" gate. No code-changing PR can be opened from this sandbox. Implementation must happen on a networked runner or be handed to a maintainer.
- `list_issues` with `performance` label + `issue_read` for #864 / #693 are still blocked by the MCP read integrity policy ("lower integrity than agent requires"). `get_comments` on #864 IS allowed and returned `[]` this run. `update_issue` safe-output writes are unaffected, so I can still publish to #864 — just can't pre-read its body via MCP. The previous body is reconstructed from memory each run. Keep memory authoritative on monthly summary structure.

## Next run suggestions (round-robin)
- Task 3 (implement): pick up P1 (sweep-line rewrite) on a NETWORKED runner. The structural test sketch is in backlog.md. Without network, revisit in a follow-up workflow run.
- Task 5 (comment on perf issues): revisit if a new perf-labeled issue opens.
- Task 6 (measurement infra): the subtitle-parser microbenchmark (5k-line SRT) is the lowest-risk, highest-value deferral — author it on a networked runner.
- Issue #864's comment log is still empty after 8 runs — no maintainer guidance received. If guidance arrives via a comment, NOTE it in memory next run. The MCP integrity policy still blocks `list_issues`/`issue_read` for #864, but `get_comments` is the read path that works.
- NINE consecutive network-blocked runs now (2026-10-08 → 2026-10-16 inclusive). Same blocker signature throughout: curl SSL exit 60, no `package_config.json`, empty `.pub-cache`, Flutter SDK read-only (now nested structure). If a future maintainer wants code-changing perf PRs from this workflow, the sandbox needs the firewall allow-listed OR this workflow should be moved to a runner with public network egress. This is flagged in the monthly summary's Run History entry so the next reader doesn't repeat the 9-run loop.
- HEAD on main is `14d5745` (PR #962 macOS sqlite3 fix) — fast local gates only, no impact on P1–P5 perf backlog.
- Re-read the monthly summary issue before further work — that is the only way to detect maintainer comments. Use `get_comments` on #864 (the only read path still allowed) before submitting a new body.
