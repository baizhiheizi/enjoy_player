# Validated build/test/perf commands (Enjoy Player, Flutter)

## Toolchain quirk (IMPORTANT, cost me time — reuse this)
- The CI-installed Flutter at `/home/runner/.toolcache/flutter-3.47.6-stable`
  is on a **READ-ONLY filesystem**. Any `flutter`/`dart` command run from
  there fails: `update_engine_version.sh` cannot write `engine.stamp`/`engine.realm`,
  and the tools snapshot cannot write `bin/cache/lockfile`. Do NOT waste time
  trying env vars.
- SDK structure (verified 2026-10-17, still in place): the bin/ tree nests
  under `/home/runner/.toolcache/flutter-3.47.6-stable/flutter/` (a
  `flutter/` subdir). The writable-copy recipe below still works; just
  adjust the final path.
- Workaround that works: copy the SDK to writable temp and invoke by
  ABSOLUTE path.
  ```bash
  cp -a /home/runner/.toolcache/flutter-3.47.6-stable /tmp/gh-aw/agent/flutter-3.47.6
  # (cp -a into an existing dir nests it -> real SDK root is /tmp/gh-aw/agent/flutter-3.47.6/flutter)
  /tmp/gh-aw/agent/flutter-3.47.6/flutter/bin/flutter --version
  ```
- Verified (2026-10-17): Flutter 3.47.6 stable, Dart 3.13.5 — matches
  `mise.toml` pin exactly.
- **WARN: the writable Flutter copy is EPHEMERAL.** `/tmp/gh-aw/agent/` is
  wiped between workflow runs. The 2026-10-17 run found the copy missing
  from the 2026-10-16 run. Each run must re-create it; the recipe is
  idempotent (cp -a is safe to re-run).
- Shell profile re-prepends the read-only toolcache to PATH, so
  `export PATH=...` does NOT take effect. Always use the absolute path to
  the copied SDK.
- Old workaround targeting the 3.44.0 SDK is OBSOLETE; use the 3.47.6 copy
  above.

## OFFLINE HARNESS (validated 2026-10-20 — supersedes the "cannot change code" blocker below)
The pub.dev block is real, but it does NOT prevent measuring or changing code.
Use the Dart VM directly with a hand-written package config.

- Dart binary (read-only SDK is fine for `dart`; only `flutter` needs a
  writable copy):
  `/home/runner/.toolcache/flutter-3.47.6-stable/flutter/bin/cache/dart-sdk/bin/dart`
  (Dart 3.13.5).
- No pub cache exists (`~/.pub-cache` absent) and the repo has no
  `.dart_tool/package_config.json`. Write one by hand at
  `<repo>/.dart_tool/package_config.json` (gitignored — DELETE IT at the end
  of the run so a later `pub get` is not confused):
  ```json
  {
    "configVersion": 2,
    "packages": [
      {"name": "enjoy_player", "rootUri": "../", "packageUri": "lib/",
       "languageVersion": "3.12"},
      {"name": "flutter", "rootUri": "file:///tmp/gh-aw/agent/bench/stubs/flutter/",
       "packageUri": "lib/", "languageVersion": "3.12"},
      {"name": "flutter_test", "rootUri": "file:///tmp/gh-aw/agent/bench/stubs/flutter_test/",
       "packageUri": "lib/", "languageVersion": "3.12"}
    ]
  }
  ```
  `languageVersion` must be **3.12** (the pubspec constraint is `sdk: ^3.12.0`),
  not the SDK's 3.13.
- **Stub `package:flutter/foundation.dart`** — it transitively imports
  `dart:ui` (engine-only) so it cannot compile under a standalone `dart` VM.
  Needs `listEquals` (copy verbatim from the SDK's
  `packages/flutter/lib/src/foundation/collections.dart`) plus a minimal
  `immutable` annotation, **plus `compute`** (added 2026-10-25 — the codec
  imports it for isolate pre-decode):
  ```dart
  import 'dart:async';
  typedef ComputeCallback<M, R> = FutureOr<R> Function(M message);
  Future<R> compute<M, R>(ComputeCallback<M, R> callback, M message,
      {String? debugLabel}) async => callback(message);
  ```
  The `dart:async` import is required for `FutureOr`.
- **Stub `package:flutter_test/flutter_test.dart`** — a small matcher/test
  framework. Build it as ONE `abstract class Matcher` with `matches` /
  `describe` and a subclass per matcher; separate `const` matcher objects
  plus free functions produced type errors ("A value of type '_Matcher'
  can't be assigned to a variable of type 'Matcher'") on the first attempt.
  Needed surface: `test`/`group`/`expect`/`setUp`/`tearDown`/`addTearDown`,
  `equals` (**deep** list/map comparison — a shallow `==` makes
  `expect(listA, equals(listB))` fail for lists of objects without value
  equality), `isNull`, `isNotNull`, `isTrue`, `isFalse`, `isEmpty`,
  `isNotEmpty`, `same`, `isNot`, `hasLength`, `greaterThan`,
  `greaterThanOrEqualTo`, `lessThan`, `lessThanOrEqualTo`, `contains`,
  `startsWith`, `endsWith`, `isA`, `expectLater`, `fail`, `Timeout`, and a
  `TestFailure` type. With it the repo's real `*_test.dart` files run under
  plain `dart`.
- **Negative-control the stub** before trusting a green result: a
  deliberately failing `expect` must print `[FAIL]` and exit non-zero.
  Verified 2026-10-25.
- Run a script or a test file:
  `dart --packages=<repo>/.dart_tool/package_config.json <file>.dart`
- `dart analyze <file>` and `dart format` also work against that config.
  **`dart format` only reproduces CI output when a package config is present** —
  the language version selects tall vs short style, and without a config the
  formatter also inserts a blank line between a `package:` import and a
  relative import (CI's formatter does not). Place the config BEFORE formatting.
- **What still cannot compile locally**: anything importing `package:drift`,
  `package:riverpod`, `package:media_kit`, `package:logging`, `package:path`,
  `package:cross_file`, or the app's own `app_database.dart`. That includes
  every `TranscriptRepository` **part file** — a part file is only valid
  inside its library, and the library needs Drift. `dart format` still
  parses a part file standalone, so use it as a syntax check.
- Still not possible: `flutter test` / `flutter analyze` against the real
  dependency set. **CI on GitHub's runners is the authoritative gate**; say so
  explicitly in the PR body.

## HARD BLOCKER (partial): `flutter pub get` cannot resolve deps offline
- Validated 2026-10-08, re-verified 2026-10-17 and 2026-10-20.
- Root cause (identified 2026-10-20): the egress proxy terminates TLS with an
  **SNI guard**. For hostnames not on its allowlist it presents a self-signed
  `CN=awf-sni-guard.invalid` certificate, so `curl` exits 60 ("self-signed
  certificate"). `pub.dev` is not allowlisted — and neither is `github.com`,
  so `git push` over HTTPS fails too.
- The proxy CA (`O=MCPG Proxy, CN=MCPG Proxy CA`, 24 h rotation) IS in
  `/etc/ssl/certs/ca-certificates.crt`; the failure is the *hostname*
  allowlist, not a missing CA. Do not try to route around it (that is network
  evasion of the firewall — banned).
- `flutter pub get --offline` FAILS: "enjoy_player depends on
  flutter_launcher_icons any which doesn't exist (could not find package
  flutter_launcher_icons in cache)". No usable pub cache exists.
- => Use the offline harness above for measurement, analysis, formatting and
  unit-test execution. CI verifies the rest.
- **Config fix for the maintainer:** `.github/workflows/ci.yml` already sets
  `PUB_HOSTED_URL: https://pub.flutter-io.cn` and
  `FLUTTER_STORAGE_BASE_URL: https://storage.flutter-io.cn` (routed DIRECT),
  but `.github/workflows/perf-improver.md` sets neither and its
  `network.allowed` list omits `pub.dev`, `pub.flutter-io.cn` and
  `storage.flutter-io.cn`. Adding them mirrors CI and unblocks dependency
  resolution for every future run.
- To re-validate the toolchain on a networked runner:
  `bash .github/scripts/validate_ci_gates.sh --analyze`.

## GitHub write path in this sandbox
- `git push` fails TLS (github.com is not on the proxy allowlist).
- PRs must be created with the safe-outputs `create_pull_request` tool. It
  does not push itself: it writes a bundle + patch under `/tmp/gh-aw/` and the
  workflow framework pushes and opens the PR afterwards. So the PR may not be
  visible via the GitHub API immediately after the call — expected, not a
  failure.
- Reads: GitHub MCP tools work (separate proxy path).

## Canonical gates (from AGENTS.md + .github/scripts/validate_ci_gates.sh)
- Fast local mirror (format + codegen drift + path-deps gate):
  `bash .github/scripts/validate_ci_gates.sh`
- Add analyze: `bash .github/scripts/validate_ci_gates.sh --analyze`
- Add tests: `bash .github/scripts/validate_ci_gates.sh --test`
- Full (slow): `bash .github/scripts/validate_ci_gates.sh --all`
- Individual: `flutter analyze`, `flutter test`,
  `bash .github/scripts/check_dart_format.sh [--fix]`
- Codegen after annotation changes: `dart run build_runner build` or
  `bash .github/scripts/check_codegen_drift.sh --fix` (run in MAIN checkout,
  not agent worktree).
- Path packages live under `packages/*/` (azure_speech, forced_alignment,
  ffmpeg_kit_flutter_new, flutter_secure_storage_linux); `--packages` runs
  their suites.

## Project facts
- Flutter/Dart monorepo. Root app `enjoy_player` + path packages under
  `packages/`.
- Scale: ~934 lib dart files, ~668 test files. Big mature codebase.
- 24 features under lib/features/ (player, transcript, asr, sync, vocabulary,
  library, discover, lookup, ai, craft, shadow_reading, etc.).
- Tests use Drift (sqlite) + Riverpod; heavy use of Freezed/codegen.
- Test count as of 2026-10-17: 6730–6744 across the maintainer's 5 perf
  PRs (#969–#973). Each `flutter test` run is several minutes on a
  networked runner.

## Microbenchmark methodology (validated 2026-10-25 — supersedes ad-hoc timing)
- **One implementation per fresh process.** An in-process A/B benchmark is
  order-biased: whichever implementation runs first wins. Use
  `dart run --packages=<cfg> bench_before.dart` and `bench_after.dart` as
  separate invocations.
- **100 warmup + 200 measured iterations**, median per round, **3 rounds**,
  report the mean of the round medians *and* the minimum-of-rounds.
- **Warmup length changes the number materially.** A 20-warmup + 60-measured
  harness reported 1.461 ms for a 2.3 MB character scan; 100 warmup + 200
  measured reported 0.483 ms for the same work. Never quote a number from a
  short warmup.
- Report median / min / p90 together; if min-of-rounds disagrees with the
  median, the run is JIT-artifacted and must be repeated.
- Keep the measured function pure and feed it a **sink** (`sink += result`)
  so the optimizer cannot elide it.
- Do not compile a `RegExp` inside a measured loop.
- The in-repo microbenchmark template (`docs/perf-measurement.md`) uses a
  single warmup + 20 runs, so its printed number is deliberately colder than
  the isolated headline — say so when quoting both.
- Useful micro-optimization fact: `json.runes.length` is ~7–9x slower than a
  `codeUnitAt` scan of the same string (`Runes.length` iterates the `Runes`
  iterator rune by rune). Dart forbids `WeakReference<String>`, so a
  string-keyed weak cache is not an option.

## Performance testing philosophy (docs/perf-measurement.md)
- Prefers STRUCTURAL deterministic tests over wall-clock benchmarks:
  - Pattern 1: pin ==/hashCode for value types in dedupe chains.
  - Pattern 2: count stream emissions (Drift watch dedupe).
  - Pattern 3: Completer-barrier single-flight test doubles.
  - Pattern 4: 10k-item widget list + fling + takeException()==isNull.
  - Microbenchmark template exists for parse throughput (local only, loose
    ceilings).
- Known gap per doc: dedicated test/perf/ dir + benchmark smoke job are
  DEFERRED future work.
- Main-isolate perf focus (docs/architecture.md#main-isolate-performance-windows):
  no heavy per-item image analysis (palette_generator) in large grids/lists
  on UI isolate; keep playback/startup/scroll/transcript/sync/import work
  off UI thread. Profile with DevTools CPU profiler locally.
- Sliver perf: long-lived lists use stable ValueKey + findChildIndexCallback
  (lib/core/utils/sliver_key_index.dart) to reuse Elements.

## Conventions that gate PRs (AGENTS.md)
- No `print()` — use logNamed. No `//` comments in lib/test except analyzer
  directives (zero-comment policy).
- Every edit must be green: flutter analyze + flutter test both pass. Do not
  create a PR otherwise.
- All SQLite via Drift DAOs. Single media_kit Player (PlayerController).
  No Flutter web / kIsWeb.