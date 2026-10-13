# Perf Improver run state

- **Last run:** 2026-10-13 (workflow run 38471681114) — sixth run, still network-blocked.
- **Previous runs:**
  - 2026-10-12 (38321153103) — fifth run, still blocked.
  - 2026-10-11 (38172969613) — fourth run, still blocked.
  - 2026-10-10 (38083345073) — third run, still blocked; toolcache verified at 3.47.6.
  - 2026-10-09 (37992822450) — second run, still blocked; toolcache verified at 3.47.6.
  - 2026-10-08 (37781547756) — first run, set up memory + backlog + issue #864.

## Tasks completed this run
- Task 1 (commands): Same blocker. `curl` to pub.dev and api.github.com returns SSL handshake errors (self-signed cert); storage.googleapis returns HTTP 400. `/home/runner/.toolcache/flutter-3.47.6-stable/bin` empty (read-only filesystem; copy tool needed). `.dart_tool/package_config.json` absent. `flutter pub get` impossible from this sandbox.
- Task 2 (opportunities): Re-read `lib/features/transcript/domain/transcript_recording_counts.dart` lines 22-38 — the nested-loop `countRecordingsPerLineIndex` is unchanged. P2-P5 also still present (no merged fixes since 10-08). Commits since last run (fb1b294 docs/changelog) do not touch any P1–P5 target. Reviewed 9 merged PRs since 10-12: #899 (Linux YouTube codec), #900 (Duet UI audit), #903 + #904 (record-ring refactor + CI fix), #907 (subtitle track picker split), #909 (vocabulary sync), #910 (subtitle import flow), #911 (Apple CI resilience), #913 (LAN cache + CN mirrors), #914 (changelog) — all unrelated to perf targets. Two new draft PRs #916/#917 also unrelated.
- Task 3 (implement): **STILL BLOCKED**. Sixth run in a row. Same network blocker — pub.dev/api.github.com SSL handshake errors, pub cache empty. AGENTS.md "every edit must be green" gate cannot be satisfied. No code-changing PR opened.
- Task 4 (PRs): N/A — no `[perf-improver]` PRs open in the repo.
- Task 5 (issues): No open issues labeled `performance` except #864 (the monthly summary). No comment-worthy open perf issues.
- Task 6 (measurement infra): The deferred 5k-line SRT microbenchmark and `test/perf/` dir are still open deferrals per `docs/perf-measurement.md`. Cannot author from this sandbox. Only `*perf*` test in repo remains `test/features/transcript/transcript_blur_long_list_perf_test.dart`.
- Task 7 (monthly summary): Updated issue #864 with this run's entry. Prepended the 2026-10-13 run at the top of Run History (the body now has 5 entries — getting long but still under the limit).

## Work in progress
- NONE. No branch, no code changes, no PR from this run.

## Open blockers / environment constraints (unchanged)
- Sandbox has NO network access to pub.dev / api.github.com (SSL handshake errors). `.dart_tool/package_config.json` does not exist. `flutter pub get --offline` fails on missing `flutter_launcher_icons`. `dart analyze <file.dart>` produces "Target of URI doesn't exist" errors for every package import.
- Surprising wrinkle (2026-10-13): `storage.googleapis.com` now reliably returns HTTP 400 instead of the prior intermittent 403/timeout. Same outbound firewall effect, different error class — confirms the blocker is still active and consistent.
- The writable Flutter copy trick does NOT survive between workflow runs. Documented as ephemeral in `commands.md` for future-me.
- Consequence: cannot satisfy the AGENTS.md "every edit must be green" gate. No code-changing PR can be opened from this sandbox. Implementation must happen on a networked runner or be handed to a maintainer.

## Next run suggestions (round-robin)
- Task 3 (implement): pick up P1 (sweep-line rewrite) on a NETWORKED runner. The structural test sketch is in backlog.md. Without network, revisit in a follow-up workflow run.
- Task 5 (comment on perf issues): revisit if a new perf-labeled issue opens.
- Task 6 (measurement infra): the subtitle-parser microbenchmark (5k-line SRT) is the lowest-risk, highest-value deferral — author it on a networked runner.
- Issue #864's comment log is empty across all 6 runs — no maintainer guidance received. If guidance arrives via a comment, NOTE it in memory next run.
- Six consecutive network-blocked runs now. The blocker is consistent (pub.dev + api.github.com SSL handshake failures with a self-signed cert in the chain — likely the same intercepting proxy the repo-assist PR #917 also flagged). If a future maintainer wants code-changing perf PRs from this workflow, the sandbox needs the firewall allow-listed OR this workflow should be moved to a runner with public network egress. This is flagged in the monthly summary's Run History entry so the next reader doesn't repeat the 6-run loop.
- Re-read the monthly summary issue before further work — that is the only way to detect maintainer comments.
