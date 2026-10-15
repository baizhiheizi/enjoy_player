# Perf Improver run state

- **Last run:** 2026-10-15 (workflow run 38798897827) — eighth run, still network-blocked.
- **Previous runs:**
  - 2026-10-14 (38631286522) — seventh run, still blocked.
  - 2026-10-13 (38471681114) — sixth run, still blocked.
  - 2026-10-12 (38321153103) — fifth run, still blocked.
  - 2026-10-11 (38172969613) — fourth run, still blocked.
  - 2026-10-10 (38083345073) — third run, still blocked; toolcache verified at 3.47.6.
  - 2026-10-09 (37992822450) — second run, still blocked; toolcache verified at 3.47.6.
  - 2026-10-08 (37781547756) — first run, set up memory + backlog + issue #864.

## Tasks completed this run
- Task 1 (commands): Same blocker re-verified. `curl --max-time 8` to `https://pub.dev` and `https://api.github.com` both return exit 60 (SSL certificate problem — self-signed cert in chain). `/home/runner/.toolcache/flutter-3.47.6-stable` still read-only (`engine.stamp` missing). `.dart_tool/package_config.json` absent.
- Task 2 (opportunities): Only commit since 2026-10-14 is `a71f15d` (PR #949, "ci: fast, safe gates — unblock main, fix local hangs, gate only outside PRs"). CI-gate refactor only — no impact on P1–P5 (transcript / DAO / SentenceRuler / etc.). Backlog unchanged.
- Task 3 (implement): **STILL BLOCKED**. Eighth run in a row. AGENTS.md "every edit must be green" gate unsatisfiable from this sandbox. No code-changing PR opened.
- Task 4 (PRs): N/A — `search_pull_requests` with `[perf-improver]` returns 0; `list_pull_requests` (state=open) returns 0. No `[perf-improver]` PRs open in the repo.
- Task 5 (issues): No open perf-labeled issues besides #864. `list_issues` with `performance` label filters out #864 due to MCP integrity policy on reads (same as last 2 runs). Safe-output writes to #864 still succeed.
- Task 6 (measurement infra): Deferred 5k-line SRT microbenchmark and `test/perf/` dir still open deferrals per `docs/perf-measurement.md`. Cannot author from this sandbox.
- Task 7 (monthly summary): Updated issue #864 — prepended 2026-10-15 entry at the top of Run History (8 entries total now: 2026-10-08 through 2026-10-15). Body rewrites in full per format enforcement. New suggested-actions entry added for PR #949 (CI gate refactor — informational, no action required unless CI measurements regress).

## Work in progress
- NONE. No branch, no code changes, no PR from this run.

## Open blockers / environment constraints (unchanged)
- Sandbox has NO network access to pub.dev / api.github.com (SSL certificate problem exit 60). `.dart_tool/package_config.json` does not exist. `flutter pub get --offline` fails on missing `flutter_launcher_icons`. `dart analyze <file.dart>` produces "Target of URI doesn't exist" errors for every package import.
- The writable Flutter copy trick does NOT survive between workflow runs. Documented as ephemeral in `commands.md` for future-me.
- Consequence: cannot satisfy the AGENTS.md "every edit must be green" gate. No code-changing PR can be opened from this sandbox. Implementation must happen on a networked runner or be handed to a maintainer.
- NEW: `list_issues` with `performance` label + `issue_read` for #864 are now blocked by the MCP read integrity policy ("lower integrity than agent requires"). `update_issue` safe-output writes are unaffected, so I can still publish to #864 — just can't pre-read its body via MCP. The previous body is reconstructed from memory each run. Keep memory authoritative on monthly summary structure.

## Next run suggestions (round-robin)
- Task 3 (implement): pick up P1 (sweep-line rewrite) on a NETWORKED runner. The structural test sketch is in backlog.md. Without network, revisit in a follow-up workflow run.
- Task 5 (comment on perf issues): revisit if a new perf-labeled issue opens.
- Task 6 (measurement infra): the subtitle-parser microbenchmark (5k-line SRT) is the lowest-risk, highest-value deferral — author it on a networked runner.
- Issue #864's comment log is still empty after 7 runs — no maintainer guidance received. If guidance arrives via a comment, NOTE it in memory next run.
- Seven consecutive network-blocked runs now. The blocker is consistent (pub.dev + api.github.com SSL certificate problems with a self-signed cert in the chain — likely the same intercepting proxy the repo-assist PR #917 also flagged). If a future maintainer wants code-changing perf PRs from this workflow, the sandbox needs the firewall allow-listed OR this workflow should be moved to a runner with public network egress. This is flagged in the monthly summary's Run History entry so the next reader doesn't repeat the 7-run loop. [superseded by 8th-run note below]
- EIGHT consecutive network-blocked runs now (2026-10-08 → 2026-10-15 inclusive). Same blocker signature throughout: curl SSL exit 60, no `package_config.json`, Flutter SDK read-only. PR #949's CI gate refactor may improve PR-CI duration once code-changing work is unblocked — flag for measurement when that happens.
- Re-read the monthly summary issue before further work — that is the only way to detect maintainer comments. Use `get_comments` on #864 (the only read path still allowed) before submitting a new body.
