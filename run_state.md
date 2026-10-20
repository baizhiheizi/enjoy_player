# Perf Improver run state

- **Last run:** 2026-10-20 (workflow run 39489542383, run #66) — thirteenth run.
  **First run that produced a code-changing PR.** The 12-run "network-blocked,
  no PR" streak is over.
- **Previous runs:**
  - 2026-10-19 (39326116922) — twelfth run, blocked.
  - 2026-10-18 (39156637829) — eleventh run, blocked.
  - 2026-10-17 (39059970796) — tenth run; crosswalked backlog to #968.
  - 2026-10-16 (38957015222) — ninth run, blocked.
  - 2026-10-15 (38798897827) — eighth run, blocked.
  - 2026-10-14 (38631286522) — seventh run, blocked.
  - 2026-10-13 (38471681114) — sixth run, blocked.
  - 2026-10-12 (38321153103) — fifth run, blocked.
  - 2026-10-11 (38172969613) — fourth run, blocked.
  - 2026-10-10 (38083345073) — third run, blocked.
  - 2026-10-09 (37992822450) — second run, blocked.
  - 2026-10-08 (37781547756) — first run, set up memory + backlog + issue #864.

## THE BREAKTHROUGH: measurement + code changes are possible without `pub get`

The blocker for 12 runs was not a generic outage. The egress proxy
(`172.30.0.10:3128`) terminates TLS with an **SNI guard**: for hostnames that
are not on the allowlist it presents a **self-signed `CN=awf-sni-guard.invalid`**
certificate, so `curl` exits 60 with "SSL certificate problem: self-signed
certificate". `pub.dev` is not allowlisted. `github.com` is **also** not
allowlisted for the generic proxy — so `git push` over HTTPS fails TLS too.

Two consequences:
1. Do **not** try to route around the deny (the `api-proxy` sidecar at
   `172.30.0.30` is in `no_proxy` but using it to bypass the SNI guard is
   network evasion — not done, and not to be done).
2. Everything needed for a perf PR can still be done **offline**, because the
   Flutter SDK is present and the repo's own sources only need a small set of
   packages for a targeted hot path.

### Offline harness recipe (worked this run)

- Dart SDK: `/home/runner/.toolcache/flutter-3.47.6-stable/flutter/bin/cache/dart-sdk/bin/dart` (Dart 3.13.5).
- The repo has **no** `.dart_tool/package_config.json` and **no** pub cache
  (`~/.pub-cache` absent). Hand-write one:
  - `enjoy_player` → repo root, `packageUri: "lib/"`, `languageVersion: "3.12"`
    (the pubspec constraint is `sdk: ^3.12.0`, so 3.12 — not the SDK's 3.13).
  - `flutter` → local stub (see below).
  - `flutter_test` → local stub (see below).
- **Stub `package:flutter/foundation.dart`**: it transitively pulls in `dart:ui`
  (engine-only), so it cannot compile under a standalone `dart` VM. The stub
  needs only `listEquals` (copy it verbatim from the SDK's
  `packages/flutter/lib/src/foundation/collections.dart`) and a minimal
  `immutable` annotation.
- **Stub `package:flutter_test/flutter_test.dart`**: a small matcher/test
  framework (`test`/`group`/`expect`/`setUp`, `equals`, `isEmpty`, `hasLength`,
  `isTrue`, `greaterThan`, `lessThan`, `contains`, `same`, `isNot`, …). With it
  the repo's real `*_test.dart` files can be **executed** under plain `dart`.
- Run a file: `dart --packages=<config> <file>.dart`.
- `dart analyze <file>` and `dart format` also work against that config.
  **`dart format` only reproduces CI output when a package config is present** —
  the language version selects tall vs short style, and without a config the
  formatter also inserts a blank line between a `package:` import and a
  relative import (which CI's formatter does not). Always place the config at
  `<repo>/.dart_tool/package_config.json` (gitignored) before formatting.

### What this unlocks
- Profiling a real hot path (no `pub get` needed).
- **Differential testing** of an optimized implementation against a snapshot of
  the pre-change source — a stronger correctness proof than the repo's usual
  structural tests.
- Running the repo's existing unit tests for the touched module.
- `dart analyze` + `dart format` on the changed files.

### What it does NOT unlock
- `flutter test` / `flutter analyze` against the real dependency set (needs
  the full pub graph). **CI on GitHub's runners is the authoritative gate.**
- Anything importing packages outside the stub set (e.g. `package:meta`,
  `package:path`).

## Tasks completed this run
- Task 1 (commands): confirmed the Flutter SDK is present and the Dart VM is
  usable; diagnosed the block precisely as the SNI guard (see above) rather
  than a network outage; built and validated the offline harness.
- Task 2 (opportunities): HEAD on `main` at `0174699` (bump v0.10.0, #999).
  Issue **#968 was closed** by `@an-lee` on 2026-10-20 10:58 UTC with all five
  candidates shipped as #969–#973. Two open draft PRs exist, both Repo Assist's
  (#1000 vocabulary bulk context, #1003 docs accuracy) — not perf targets.
  Identified the subtitle SRT parse path (`lib/data/subtitle/subtitle_parser.dart`,
  reached from `transcript_repository_subtitle_import.dart` and
  `embedded_subtitle_service.dart`) as the hot path to attack: `docs/perf-measurement.md`
  names it as the one case that had no measurement coverage at all.
- Task 3 (implement): **DONE.** Branch `perf-assist/subtitle-parser-throughput`,
  commit `5f21e33`. Three changes in `SrtParser` only:
  1. `_splitLines` — skip the two whole-string `replaceAll` normalization passes
     when the content has no `\r`; per-line trailing-`\r` strip otherwise, with
     a fallback to the original normalize-then-split path for lone-CR / mixed
     endings so unusual inputs cannot drift.
  2. `_isAllDigits` — replaces the per-cue `RegExp(r'^\d+$')` index match.
  3. `_parseTs` + `_digitsToInt` — digit scan instead of `tryParseHmsDuration`
     (no `Duration` allocation per timestamp).
  The VTT path was deliberately left alone: a VTT variant measured ≈1.5 %
  (within noise) and was **reverted** rather than shipped as an unjustified
  claim.
- Task 4 (PRs): N/A — no open `[perf-improver]` PRs to maintain.
- Task 5 (issues): **DID NOT COMMENT on #968** — it was closed by the
  maintainer on 2026-10-20 10:58 UTC and there was no new human comment. The
  `pub.dev` allowlist gap was raised in the monthly summary instead (as a
  maintainer-facing suggested action), which is the anti-spam-correct channel.
- Task 6 (measurement infra): **DONE (partially).** `test/data/subtitle/subtitle_parser_perf_test.dart`
  — 5000-cue scale fixture, LF/CRLF/lone-CR/mixed-ending equivalence, accepted
  timestamp forms, plus a `skip:`-marked local-only microbenchmark (loose
  ceiling only, per `docs/perf-measurement.md`). Linked from
  `docs/perf-measurement.md`. A dedicated `test/perf/` dir + benchmark smoke CI
  job remain deferred per that doc.
- Task 7 (monthly summary): updated issue #864 — prepended the 2026-10-20
  entry, rewrote Suggested Actions as checkboxes, added P9 (subtitle parse) and
  the network-allowlist action.

## Measured results (this run)

Isolated processes (one implementation per process, 100 warmup + 200 measured,
median per round, 3 rounds; mean of round medians reported):

| Input | Cues | Before | After | Speedup |
|---|---:|---:|---:|---:|
| SRT LF | 5000 | 10.34 ms | 5.50 ms | 1.88x |
| SRT CRLF | 5000 | 11.98 ms | 6.15 ms | 1.95x |
| SRT LF | 20000 | 39.48 ms | 22.85 ms | 1.73x |
| SRT CRLF | 20000 | 40.11 ms | 23.35 ms | 1.72x |

Minimum-of-rounds agrees (6.77 → 3.61 ms at 5000 cues LF), so the gain is not
a JIT-tiering artifact. In-repo microbenchmark: 5.05 ms/run for 5000 cues.

**Differential proof**: 60,055 cases (40 curated + 20,000 atom-fuzz + 40,000
CR-fuzz) comparing every cue's `(text, startMs, durationMs)` against a snapshot
of the pre-change parser — **0 mismatches** for both SRT and VTT. The new
structural tests also pass against the *original* implementation, so they pin
behavior, not implementation shape.

## Lessons for future runs
- An in-process A/B benchmark is **order-biased**: whichever implementation is
  measured first wins. Always use one implementation per fresh process.
- JIT tiering + GC make timings bimodal — use long warmups and report
  min/p10/median/p90, and lean on minimum-of-rounds for the headline number.
- Don't compile a `RegExp` inside a measured loop; that silently inflated one
  profiling run by ~7.9 ms.
- `String.replaceAll` returns the identical string when there is no match but
  still pays a full scan; multi-char patterns are far slower than
  `contains`/`indexOf`.

## Open blockers / environment constraints
- `pub.dev` (and `github.com`) are not on the egress proxy's allowlist; TLS is
  terminated by an SNI guard with a self-signed certificate. `flutter pub get`
  and `git push` therefore fail with curl/git exit 60.
- **Config fix for the maintainer:** `.github/workflows/ci.yml` already sets
  `PUB_HOSTED_URL: https://pub.flutter-io.cn` and
  `FLUTTER_STORAGE_BASE_URL: https://storage.flutter-io.cn` (routed DIRECT),
  but `.github/workflows/perf-improver.md` sets neither env var and its
  `network.allowed` list omits `pub.dev`, `pub.flutter-io.cn` and
  `storage.flutter-io.cn`. Adding them mirrors CI and unblocks every future
  code-changing perf run.
- **PR creation must go through the safe-outputs `create_pull_request` tool.**
  It does not push to GitHub itself; it writes a bundle + patch under
  `/tmp/gh-aw/` and the workflow framework pushes and opens the PR afterwards.
  So the PR may not be visible via the GitHub API immediately after the tool
  call — that is expected, not a failure.
  Confirmed artifacts this run:
  `/tmp/gh-aw/aw-perf-assist-subtitle-parser-throughput.bundle` (3.8 KB) and
  `….patch` (11.9 KB). Naming pattern: `aw-<branch>.bundle` / `aw-<branch>.patch`.
  The same applies to `update_issue`: the tool returned `{"result":"success"}`
  but issue #864's body still showed the 2026-10-19 run history when read via
  the GitHub API during the run — the framework applies the edit afterwards.
  Do not re-issue a write just because the API has not caught up yet.
- `issue_read.get` on #864 (automation-authored) is blocked; `get_comments` on
  #864 works and returns `[]`. `issue_read.get` on human-authored issues works.
- `.dart_tool/` is gitignored; the hand-written package config placed there
  must be deleted at the end of a run so a later `pub get` is not confused.

## Next run suggestions (round-robin)
- Task 4/5: check the new draft PR's CI. If CI is red because of a real
  regression, fix forward; if it is an infra-only failure, comment on the PR.
- Task 2: P3 (`vocabulary_item_dao.listDue` over-fetch) is the next
  independent, low-risk target; P6/P7/P8 remain offered to `@an-lee` on #968
  (now closed — re-offer only if the maintainer reopens or replies).
- Task 3: the same offline harness makes another code-changing perf PR
  possible; prefer a single hot path with an isolated-process benchmark and a
  differential proof.
- Task 6: the `test/perf/` directory + benchmark smoke CI job are still
  deferred per `docs/perf-measurement.md`; do not add them unilaterally.
- Re-read the monthly summary issue before further work — it is the only way
  to detect maintainer comments.
