# Perf Improver run state

- **Last run:** 2026-10-18 (workflow run 39156637829) — eleventh run.
- **Previous runs:**
  - 2026-10-17 (39059970796) — tenth run; crosswalked backlog to #968.
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
- Task 1 (commands): Same blocker re-verified (11th consecutive). `curl --max-time 12`
  to `https://pub.dev/api/packages/flutter` and `https://api.github.com/repos/.../pulls/969`
  both still return exit 60 (SSL certificate problem — self-signed cert in chain).
  Writable Flutter copy at `/tmp/gh-aw/agent/flutter-3.47.6` is GONE (ephemeral —
  the /tmp/gh-aw/agent/ dir is wiped between runs). SDK nest under
  `toolcache/flutter-3.47.6-stable/flutter/` still verified.
- Task 2 (opportunities): **HUGE UPDATE.** All 5 maintainer PRs are MERGED on `main`
  between 2026-10-17 22:45 and 23:20 UTC. Verified by `pull_request_read`:
  - **#969 C1 TranscriptContent** — merged 2026-10-17 22:45 UTC by an-lee (521 add / 63 del, 12 files)
  - **#970 C2 LibraryViews** — merged 2026-10-17 23:19 UTC by an-lee (856 add / 56 del, 16 files; schema v20→v21)
  - **#971 C4 RulerGeometry** — merged 2026-10-17 23:19 UTC by an-lee (512 add / 136 del, 5 files)
  - **#972 C5 SurfaceStallProbe** — merged 2026-10-17 23:20 UTC by an-lee (140 add / 7 del, 4 files)
  - **#973 C3 TakeAssessmentNotes** — merged 2026-10-17 23:20 UTC by an-lee (357 add / 50 del, 6 files)
  Repo Assist (separate workflow run 39099034539) commented on #968 at 2026-10-18
  05:09 UTC recommending closure of the tracking issue. #968 is still `OPEN`.
  HEAD on main is now `2010eff` (PR #981 — CI fix to drop GitHub-cache round-trips
  on native mac/windows runners). The 3 "Also verified, smaller" candidates
  (P6 startup prefs, P7 auto-translate fan-out, P8 position tracker seek) remain
  out of scope per the maintainer. backlog.md updated accordingly.
- Task 3 (implement): **STILL BLOCKED.** Eleventh run in a row. Same SSL exit 60.
  No code-changing PR opened.
- Task 4 (PRs): N/A — no open `[perf-improver]`-titled PRs. All 5 maintainer PRs
  in this area are now MERGED.
- Task 5 (issues): **DID NOT COMMENT.** Anti-spam guidance: no new human comment
  on #968 since my last engagement (only Repo Assist's bot comment at 05:09 UTC,
  which is not human). Offer to take P6/P7/P8 still stands; awaiting human input
  from an-lee.
- Task 6 (measurement infra): Still deferred (5k-line SRT microbenchmark + test/perf/
  + benchmark smoke CI). Cannot author from this sandbox.
- Task 7 (monthly summary): Updated issue #864 — prepended 2026-10-18 entry at
  the top of Run History (11 entries total now). Body rewritten in full per
  format enforcement. Suggested Actions trimmed to "No suggested actions at this
  time" since all 5 maintainer PRs are merged and no new human items to track.

## Work in progress
- NONE. No branch, no code changes, no PR from this run.
- However: P6–P8 in `backlog.md` remain the natural next pick on a NETWORKED runner.
- If a future maintainer wants code-changing perf PRs from this workflow, the
  firewall needs `pub.dev` allow-listed (API access via gh-proxy). The MCP
  server already proxies GitHub reads fine — the issue is only `flutter pub get`
  for dep resolution.

## Open blockers / environment constraints (unchanged)
- Sandbox has NO network access to pub.dev / api.github.com (SSL certificate
  problem exit 60). `.dart_tool/package_config.json` does not exist.
  `.pub-cache/hosted/pub.dev/` empty (0 entries). `flutter pub get --offline`
  fails on missing `flutter_launcher_icons`. `dart analyze <file.dart>`
  produces "Target of URI doesn't exist" errors for every package import.
- **NEW OBSERVATION:** GitHub MCP `pull_request_read` / `issue_read` work fine
  (proxied via a different path). `safe-outputs` writes also work. The blocker
  is ONLY direct `curl`/`pub get`. So future firewall config could split:
  - MCP / safe-outputs writes — already working, no change needed
  - Direct `pub.dev` access for `flutter pub get` — still blocked, the real fix
- The CI-installed Flutter SDK nests under
  `/home/runner/.toolcache/flutter-3.47.6-stable/flutter/` (a `flutter/`
  subdir). The writable-copy recipe still works; the real SDK root inside
  the copy is `/tmp/gh-aw/agent/flutter-3.47.6/flutter/bin/flutter`. The
  writable copy itself is EPHEMERAL — the `/tmp/gh-aw/agent/` tree is wiped
  between workflow runs (this run found it MISSING; restored the recipe
  in commands.md).
- Consequence: cannot satisfy the AGENTS.md "every edit must be green" gate.
  No code-changing PR can be opened from this sandbox. Implementation must
  happen on a networked runner or be handed to a maintainer.
- `list_issues` with `performance` label returns only #864 (my monthly summary)
  + #968 (the maintainer's roadmap, recommended for closure by Repo Assist).
  `get_comments` on both returns cleanly. `issue_read.get` (with body) is
  selectively allowed for human-authored issues (#968 ✓) but blocked for
  automation-authored low-integrity issues (#864 ✗) — same pattern as last run.
- **Read-and-record-on-#864:** `get_comments` on #864 IS allowed and returned
  `[]` this run (11th consecutive empty run on #864).
- **FIREWALL FIX TIP (from my own last comment's footer warning):**
  GitHub API access works via `tools.github.mode: gh-proxy` (pre-authenticated
  gh CLI) without needing `api.github.com` in `network.allowed`. For
  `flutter pub get` to work, `pub.dev` still needs to be added to
  `network.allowed` in the workflow frontmatter. This is the actionable
  config change for a future maintainer.

## Next run suggestions (round-robin)
- Task 3 (implement): pick up **P6** (startup preferences bulk read) on a
  NETWORKED runner. Lowest-risk, highest-confidence — single seam in
  `app_preferences_provider.dart`, structural test pinned on `readSetting`
  call count. P7 and P8 follow once P6 lands. **Important:** the maintainer
  has NOT explicitly approved me to ship these — my last comment offered to
  take them and I said "if you'd rather take one or more yourself, just say."
  An-lee has not responded yet. So P6/P7/P8 remain conditional on maintainer
  green-light OR a future run on a networked sandbox.
- Task 5 (comment on perf issues): do NOT re-engage on #968 without new human
  comment from an-lee. If maintainer replies (accepts/declines P6/P7/P8), that's
  the next engagement trigger.
- Task 6 (measurement infra): the subtitle-parser microbenchmark (5k-line
  SRT) is the lowest-risk, highest-value deferral — author it on a
  networked runner.
- ELEVEN consecutive network-blocked runs now (2026-10-08 → 2026-10-18 inclusive).
  Same blocker signature throughout: curl SSL exit 60, no `package_config.json`,
  empty `.pub-cache`, Flutter SDK read-only (now nested structure). The only
  improvement since the first run is verification that GitHub MCP reads bypass
  the firewall via a different proxy. If a future maintainer wants code-changing
  perf PRs from this workflow, the firewall needs `pub.dev` allow-listed (and
  ideally switch to `tools.github.mode: gh-proxy` for completeness, though MCP
  reads already work).
- HEAD on main is `2010eff` (PR #981 — CI fix). All 5 maintainer PRs (#969–#973)
  are merged; they all branched from `e6d067f` and shipped between 22:45–23:20
  UTC on 2026-10-17.
- Re-read the monthly summary issue before further work — that is the only
  way to detect maintainer comments. Use `get_comments` on #864 (the only
  read path still allowed) before submitting a new body. For other issues
  opened by humans, `get_issue` is also allowed (see blocker note above).
- The integration story is now: maintainer ships the PRs, Perf Improver tracks
  the crosswalk, comments for cross-pollination, and stands ready for the
  conditional P6/P7/P8 batch on a networked runner.