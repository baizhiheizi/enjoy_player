# Perf Improver run state

- **Last run:** 2026-10-14 (workflow run 38631286522) — seventh run, still network-blocked.
- **Previous runs:**
  - 2026-10-13 (38471681114) — sixth run, still blocked.
  - 2026-10-12 (38321153103) — fifth run, still blocked.
  - 2026-10-11 (38172969613) — fourth run, still blocked.
  - 2026-10-10 (38083345073) — third run, still blocked; toolcache verified at 3.47.6.
  - 2026-10-09 (37992822450) — second run, still blocked; toolcache verified at 3.47.6.
  - 2026-10-08 (37781547756) — first run, set up memory + backlog + issue #864.

## Tasks completed this run
- Task 1 (commands): Same blocker. `curl --max-time 8` to `https://pub.dev`, `https://pub.dev/api/packages/flutter_launcher_icons`, and `https://api.github.com` all return exit 60 (SSL certificate problem — self-signed cert in chain). `/home/runner/.toolcache/flutter-3.47.6-stable` still read-only. `.dart_tool/package_config.json` absent.
- Task 2 (opportunities): Re-read `lib/features/transcript/domain/transcript_recording_counts.dart` lines 22-38 — `countRecordingsPerLineIndex` byte-identical to 2026-10-08 baseline. P2-P5 also unchanged. The only commit since 2026-10-13 is `2400317` (PR #934, credits_usage_screen refactor), unrelated to perf. Reviewed 8 merged PRs since 10-13: #934 (credits screen split), #933 (lookup+player In-this-audio + layout tokens + Take-n heading), #929 (current-line card + v30 type scale), #928 (docked side margin + takes row), #927 (Echo loop "+ line"), #926 (Duet v30 dock), #925 (Dictate lens exclusivity), #924 (Duet v30 chrome). All Duet v30 / credits / look-and-feel — none touch P1–P5.
- Task 3 (implement): **STILL BLOCKED**. Seventh run in a row. AGENTS.md "every edit must be green" gate unsatisfiable from this sandbox. No code-changing PR opened.
- Task 4 (PRs): N/A — no `[perf-improver]` PRs open in the repo.
- Task 5 (issues): No open perf-labeled issues besides #864. Tried `get_comments` for #864 — returned `[]` (no comments in 7 runs; no maintainer guidance received).
- Task 6 (measurement infra): Deferred 5k-line SRT microbenchmark and `test/perf/` dir still open deferrals per `docs/perf-measurement.md`. Cannot author from this sandbox.
- Task 7 (monthly summary): Updated issue #864 — prepended 2026-10-14 entry at the top of Run History (6 entries total now). Body rewrites in full per format enforcement. Note: list_issues with `performance` label filters out #864 due to integrity policy on reads, but the update_issue safe-output write succeeds.

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
- Seven consecutive network-blocked runs now. The blocker is consistent (pub.dev + api.github.com SSL certificate problems with a self-signed cert in the chain — likely the same intercepting proxy the repo-assist PR #917 also flagged). If a future maintainer wants code-changing perf PRs from this workflow, the sandbox needs the firewall allow-listed OR this workflow should be moved to a runner with public network egress. This is flagged in the monthly summary's Run History entry so the next reader doesn't repeat the 7-run loop.
- Re-read the monthly summary issue before further work — that is the only way to detect maintainer comments. Use `get_comments` on #864 (the only read path still allowed) before submitting a new body.
