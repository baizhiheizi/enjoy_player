# Validated build/test/perf commands (Enjoy Player, Flutter)

## Toolchain quirk (IMPORTANT, cost me time — reuse this)
- The CI-installed Flutter lives at `/home/runner/.toolcache/flutter-3.44.0-stable` and is a **READ-ONLY filesystem**. Any `flutter`/`dart` command run from there fails: `update_engine_version.sh` cannot write `engine.stamp`/`engine.realm`, and the tools snapshot cannot write `bin/cache/lockfile`. Do NOT waste time trying env vars.
- Workaround that works: copy the SDK to writable temp and invoke by ABSOLUTE path.
  ```bash
  cp -a /home/runner/.toolcache/flutter-3.44.0-stable /tmp/gh-aw/agent/flutter
  # NOTE: cp -a into an existing dir nests it -> real SDK root is /tmp/gh-aw/agent/flutter/flutter
  export FLUTTER=/tmp/gh-aw/agent/flutter/flutter/bin/flutter
  ```
- Verified: `$FLUTTER --version` => Flutter 3.44.0 stable, Dart 3.12.0. (Repo pins 3.47.6 in mise.toml; CI uses mise. Local toolcache is 3.44.0 — minor version skew, usually fine.)
- Shell profile re-prepends the read-only toolcache to PATH, so `export PATH=...` does NOT take effect. Always use the absolute `$FLUTTER` path.

## HARD BLOCKER in this sandbox: cannot resolve deps offline (validated 2026-10-08)
- There is NO network access and `.dart_tool/package_config.json` does NOT exist in the checkout.
- `flutter pub get --offline` FAILS: "enjoy_player depends on flutter_launcher_icons any which doesn't exist (could not find package flutter_launcher_icons in cache)". Pub cache has ~179 packages but is missing required ones.
- Consequence: `flutter analyze` and `flutter test` CANNOT run here (they need a resolved package_config). `flutter analyze --no-pub` still tries to "update packages" and times out (~5 min).
- => On this runner I cannot satisfy the AGENTS.md "every edit must be green" gate, so I must NOT open a code-changing PR from this environment. Do discovery + measurement-infra planning here; do code changes on a runner with network, or via a maintainer.
- To re-validate the toolchain on a networked runner: `bash .github/scripts/validate_ci_gates.sh --analyze`.

## Canonical gates (from AGENTS.md + .github/scripts/validate_ci_gates.sh)
- Fast local mirror (format + codegen drift + path-deps gate): `bash .github/scripts/validate_ci_gates.sh`
- Add analyze: `bash .github/scripts/validate_ci_gates.sh --analyze`
- Add tests: `bash .github/scripts/validate_ci_gates.sh --test`
- Full (slow): `bash .github/scripts/validate_ci_gates.sh --all`
- Individual: `flutter analyze`, `flutter test`, `bash .github/scripts/check_dart_format.sh [--fix]`
- Codegen after annotation changes: `dart run build_runner build` or `bash .github/scripts/check_codegen_drift.sh --fix` (run in MAIN checkout, not agent worktree).
- Path packages live under `packages/*/` (azure_speech, forced_alignment, ffmpeg_kit_flutter_new, flutter_secure_storage_linux); `--packages` runs their suites.

## Project facts
- Flutter/Dart monorepo. Root app `enjoy_player` + path packages under `packages/`.
- Scale: ~934 lib dart files, ~668 test files. Big mature codebase.
- 24 features under lib/features/ (player, transcript, asr, sync, vocabulary, library, discover, lookup, ai, craft, shadow_reading, etc.).
- Tests use Drift (sqlite) + Riverpod; heavy use of Freezed/codegen.

## Performance testing philosophy (docs/perf-measurement.md)
- Prefers STRUCTURAL deterministic tests over wall-clock benchmarks:
  - Pattern 1: pin ==/hashCode for value types in dedupe chains.
  - Pattern 2: count stream emissions (Drift watch dedupe).
  - Pattern 3: Completer-barrier single-flight test doubles.
  - Pattern 4: 10k-item widget list + fling + takeException()==isNull.
  - Microbenchmark template exists for parse throughput (local only, loose ceilings).
- Known gap per doc: dedicated test/perf/ dir + benchmark smoke job are DEFERRED future work.
- Main-isolate perf focus (docs/architecture.md#main-isolate-performance-windows): no heavy per-item image analysis (palette_generator) in large grids/lists on UI isolate; keep playback/startup/scroll/transcript/sync/import work off UI thread. Profile with DevTools CPU profiler locally.
- Sliver perf: long-lived lists use stable ValueKey + findChildIndexCallback (lib/core/utils/sliver_key_index.dart) to reuse Elements.

## Conventions that gate PRs (AGENTS.md)
- No `print()` — use logNamed. No `//` comments in lib/test except analyzer directives (zero-comment policy).
- Every edit must be green: flutter analyze + flutter test both pass. Do not create a PR otherwise.
- All SQLite via Drift DAOs. Single media_kit Player (PlayerController). No Flutter web / kIsWeb.
