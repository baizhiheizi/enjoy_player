# Perf Improver run state

- **Last run:** 2026-10-27 (workflow run 40485464164, run #72) — fifteenth
  October run, third run to produce a code-changing PR.
- **Run history:** #71 2026-10-25 (40225340975) shipped P10 → PR #1071,
  **MERGED by an-lee 2026-10-26**. #66 2026-10-20 (39489542383) shipped P9 →
  PR #1006, **MERGED by an-lee 2026-10-20**. Runs #58–#65 (2026-10-12 →
  2026-10-19) produced no code change (dependency resolution blocked). Runs
  #67–#70 (2026-10-21 → 2026-10-24) ended without producing a change.
- **Next run:** check the `perf-assist/ipa-familiar-form-derivation` draft
  PR's CI. It is the first real compile of `lib/data/subtitle/ipa_mapping.dart`.

## Repo state at this run
- HEAD on `main` was `26bc53f` (fix(macos) closure check, #1099). Busy
  maintainer week: #1071 (P10, merged), #1078, #1079, #1080, #1081, #1084,
  #1085, #1088/#1093 → #1094, #1089, #1090, #1091, #1094, #1097, #1098,
  #1099.
- **No open `[perf-improver]` PRs** at the start of the run. PR #1071 (P10)
  merged on 2026-10-26 — Perf Improver's second merged code-changing PR.
- **No readable open issues.** The MCP integration drops all open issues
  (including #864) via its integrity policy; a `performance`-label query
  returns `[]`. Task 5 had no target and correctly took no action — do not
  manufacture one. #864's **body and comments are unreadable**, so the
  monthly summary is written from scratch each run (`operation: replace`);
  the check-off state is carried from memory (nothing recorded as checked off).

## Environment
The egress proxy terminates TLS with an SNI guard (self-signed
`CN=awf-sni-guard.invalid`), so `pub.dev` and `github.com` are unreachable:
`flutter pub get` and `git push` fail with exit 60. **Do not route around
it.** The full offline-harness recipe (Dart VM + hand-written package config
+ `flutter`/`flutter_test`/`meta` stubs), the stub requirements, and the
microbenchmark methodology are all in **`commands.md`** — read it rather
than re-deriving them.

Short version: pure-Dart hot paths CAN be measured, changed, and unit-tested
here; anything importing `package:drift` (including every
`TranscriptRepository` part file) cannot be compiled locally. **CI on
GitHub's runners is the authoritative gate** — say so in every PR body.

## Tasks completed this run
- **Task 1**: commands were already validated; the harness was rebuilt from
  scratch and the stubs extended (see `commands.md` for what is new).
- **Task 2**: surveyed the transcript/player/subtitle hot paths and found
  **P11** (familiar-form IPA derivation) outside the old backlog. Re-verified
  P3, P6, P7, P8 and P10b by direct grep — all still present; P8 is
  **narrowed** (the shared raw engine position stream has landed; only the
  seek/bucket classification remains).
- **Task 3**: **DONE.** Branch `perf-assist/ipa-familiar-form-derivation`,
  commit `4ebeffa`, draft PR opened via the safe-outputs tool. Details in
  `backlog.md` (P11).
- **Task 4**: no other open perf PRs to maintain; #1071 merged.
- **Task 5**: no action — no readable target.
- **Task 6**: added the repo's third local-only microbenchmark
  (`test/data/subtitle/ipa_mapping_perf_test.dart`), linked from
  `docs/perf-measurement.md`. The `test/perf/` dir + benchmark CI job stay
  deferred per that doc — do not add them unilaterally.
- **Task 7**: updated issue #864 in the mandated format (replace; the body
  was unreadable).

## P11 — what shipped (details in `backlog.md`)
`lib/data/subtitle/ipa_mapping.dart` derived a word's familiar-form IPA by
sorting the whole consonant/vowel catalog per phoneme, compiling a `RegExp`
per phoneme, and scanning all ~160 phoneme keys per character. It now
answers the catalog from a cached set, finds the stress mark by a code-unit
scan, and buckets the phoneme table by first code unit.

Measured (isolated processes, 100 warmup + 200 measured, n=8 process runs
per implementation): 2400-word corpus 34.4 ms -> 5.6 ms per pass (~6.1x at
the median, 4.3x worst case). Output byte-identical.
Correctness: 160,000 differential cases + curated edge cases against the
previous implementation, 0 mismatches.

Status: draft PR open on `perf-assist/ipa-familiar-form-derivation`. The PR
number is assigned when the framework pushes the bundle, so it was **not**
known during the run — the monthly summary references the branch instead.

## Write path
- PRs must go through the safe-outputs `create_pull_request` tool. It does
  not push itself; it writes a bundle + patch under `/tmp/gh-aw/` and the
  framework pushes afterwards, so the PR may not be visible via the API
  immediately. Expected, not a failure. Artifacts this run:
  `aw-baizhiheizi-enjoy_player-perf-assist-ipa-familiar-form-derivation.bundle`
  (7.2 KB) / `.patch` (22.5 KB).
- Same for `update_issue`: it returns `{"result":"success"}` but the issue
  body may lag. Do not re-issue a write just because the API has not caught up.
- `update-issue` in `.github/workflows/perf-improver.md` is `target: "*"`,
  so **`issue_number` must be passed explicitly**, and `max: 1` — one write
  per run.
- The perf-improver workflow uses `protected-files: fallback-to-issue`, so a
  PR touching `.github/workflows/**` becomes an issue instead.
- Delete `<repo>/.dart_tool/package_config.json` at the end of a run so a
  later `pub get` is not confused.

## Open blockers / standing decisions
- **The `network.allowed` gap** in `.github/workflows/perf-improver.md` (it
  omits `pub.dev`, `pub.flutter-io.cn`, `storage.flutter-io.cn`, while
  `ci.yml` already uses those mirrors) blocks `flutter pub get` for every
  run. **Deliberately not changed by this agent** — widening the agent
  runtime's egress allowlist is a security-boundary change and a maintainer
  decision. It is raised as a suggested action in the monthly summary.
- The monthly summary for 2026-10 stays open until 2026-11; close it and
  open a new one in November.
