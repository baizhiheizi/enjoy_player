# Perf Improver run state

- **Last run:** 2026-10-17 (workflow run 39059970796) — tenth run.
- **Previous runs:**
  - 2026-10-16 (38957015222) — ninth run, still network-blocked.
  - 2026-10-15 (38798897827) — eighth run, still blocked.
  - 2026-10-14 (38631286522) — seventh run, still blocked.
  - 2026-10-13 (38471681114) — sixth run, still blocked.
  - 2026-10-12 (38321153103) — fifth run, still blocked.
  - 2026-10-11 (38172969613) — fourth run, still blocked.
  - 2026-10-10 (38083345073) — third run, still blocked; toolcache verified at 3.47.6.
  - 2026-10-09 (37992822450) — second run, still blocked; toolcache verified at 3.47.6.
  - 2026-10-08 (37781547756) — first run, set up memory + backlog + issue #864.

## Tasks completed this run
- Task 1 (commands): Same blocker re-verified. `curl --max-time 8` to
  `https://pub.dev` and `https://api.github.com` both return exit 60 (SSL
  certificate problem — self-signed cert in chain). `.pub-cache/hosted/pub.dev/`
  is empty (0 entries). `.dart_tool/package_config.json` absent. Writable
  Flutter copy at `/tmp/gh-aw/agent/flutter-3.47.6` is GONE (ephemeral —
  the /tmp/gh-aw/agent/ dir is wiped between runs). SDK nest under
  `toolcache/flutter-3.47.6-stable/flutter/` still verified.
- Task 2 (opportunities): **MAJOR** — maintainer an-lee opened issue **#968**
  ("Architecture review (pass 4): performance deepening candidates") at
  2026-10-17 13:27 UTC. Five implementation PRs are now open:
  **#969** (C1 TranscriptContent), **#970** (C2 LibraryViews),
  **#971** (C4 RulerGeometry), **#972** (C5 SurfaceStallProbe),
  **#973** (C3 TakeAssessmentNotes). #969 + #970 already CI green
  (MERGEABLE against `main` per maintainer comment at 14:27 UTC). The
  maintainer's "Also verified, smaller" section names three more candidates
  not yet PR'd: startup preferences, auto-translate fan-out, position tracker
  seek misclassification. backlog.md rewritten to drop P1/P2/P4/P5 (now
  addressed), keep P3, add P6–P8 (the smaller items).
- Task 3 (implement): **STILL BLOCKED**. Tenth run in a row. Same SSL exit
  60. No code-changing PR opened. The 5 maintainer PRs (#969–#973) address
  the items I would have targeted (P1, P2, P4, P5).
- Task 4 (PRs): N/A — no open `[perf-improver]`-titled PRs. The 5 open PRs
  in this area are maintainer-authored and titled `perf(...)`.
- Task 5 (issues): 1 new comment posted on #968 — cross-referencing the
  maintainer's plan against my prior backlog, offering Perf Improver's
  measurement-infra and structural-test design for the three "Also verified,
  smaller" candidates (P6–P8) and signaling my next-batch intent.
- Task 6 (measurement infra): Deferred 5k-line SRT microbenchmark and
  `test/perf/` dir still open deferrals per `docs/perf-measurement.md`.
  Cannot author from this sandbox.
- Task 7 (monthly summary): Updated issue #864 — prepended 2026-10-17 entry
  at the top of Run History (10 entries total now). Body rewritten in full
  per format enforcement. New section "Maintainer perf roadmap (#968)" added
  to "Suggested Actions" so the maintainer sees the crosswalk without
  scrolling. SDK-path note reaffirmed.

## Work in progress
- NONE. No branch, no code changes, no PR from this run.
- However: P6–P8 in `backlog.md` are now the natural next pick on a
  NETWORKED runner.

## Open blockers / environment constraints (unchanged)
- Sandbox has NO network access to pub.dev / api.github.com (SSL certificate
  problem exit 60). `.dart_tool/package_config.json` does not exist.
  `.pub-cache/hosted/pub.dev/` empty (0 entries). `flutter pub get --offline`
  fails on missing `flutter_launcher_icons`. `dart analyze <file.dart>`
  produces "Target of URI doesn't exist" errors for every package import.
- The CI-installed Flutter SDK still nests under
  `/home/runner/.toolcache/flutter-3.47.6-stable/flutter/` (a `flutter/`
  subdir). The writable-copy recipe still works; the real SDK root inside
  the copy is `/tmp/gh-aw/agent/flutter-3.47.6/flutter/bin/flutter`. The
  writable copy itself is EPHEMERAL — the `/tmp/gh-aw/agent/` tree is wiped
  between workflow runs (this run found it MISSING; restored the recipe
  in commands.md).
- Consequence: cannot satisfy the AGENTS.md "every edit must be green" gate.
  No code-changing PR can be opened from this sandbox. Implementation must
  happen on a networked runner or be handed to a maintainer.
- `list_issues` with `performance` label + `issue_read` for #864 / #693 are
  still blocked by the MCP read integrity policy ("lower integrity than agent
  requires"). `get_comments` on #864 IS allowed and returned `[]` this run
  (10th consecutive empty run on #864). `get_comments` on #968 IS allowed
  (3 maintainer comments visible — the first perf-issue guidance I have
  ever received). `update_issue` safe-output writes are unaffected, so I can
  still publish to #864 — just can't pre-read its body via MCP. The previous
  body is reconstructed from memory each run. Keep memory authoritative on
  monthly summary structure.
- **`get_issue` (read with body) IS allowed for #968 and #969–#973**. So the
  integrity policy is selective: it blocks MCP `get` reads on #864 / #693
  (low-integrity issues opened by previous workflow runs) but permits
  reads on issues opened by humans (an-lee). I can read maintainer-authored
  perf content freely; I can only write to my own low-integrity issues via
  safe-output. This unblocks a lot of analysis.

## Next run suggestions (round-robin)
- Task 3 (implement): pick up **P6** (startup preferences bulk read) on a
  NETWORKED runner. Lowest-risk, highest-confidence — single seam in
  `app_preferences_provider.dart`, structural test pinned on `readSetting`
  call count. P7 and P8 follow once P6 lands.
- Task 5 (comment on perf issues): if #968 comment lands without
  maintainer pushback, this is a successful cross-pollination — Perf
  Improver's structural-test methodology aligns with the maintainer's.
  Otherwise re-engage.
- Task 6 (measurement infra): the subtitle-parser microbenchmark (5k-line
  SRT) is the lowest-risk, highest-value deferral — author it on a
  networked runner.
- TEN consecutive network-blocked runs now (2026-10-08 → 2026-10-17 inclusive).
  Same blocker signature throughout: curl SSL exit 60, no `package_config.json`,
  empty `.pub-cache`, Flutter SDK read-only (now nested structure). If a
  future maintainer wants code-changing perf PRs from this workflow, the
  sandbox needs the firewall allow-listed OR this workflow should be moved
  to a runner with public network egress. This is flagged in the monthly
  summary's Run History entry so the next reader doesn't repeat the
  10-run loop.
- HEAD on main is `e6d067f` (PR #967 forcePark docs). The 5 maintainer PRs
  (#969–#973) all base off `e6d067f` and add 5 perf-deepening commits
  against the same tip.
- Re-read the monthly summary issue before further work — that is the only
  way to detect maintainer comments. Use `get_comments` on #864 (the only
  read path still allowed) before submitting a new body. For other issues
  opened by humans, `get_issue` is also allowed (see blocker note above).