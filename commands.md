# Validated commands

- `flutter pub get` — resolves against pub.dev; cold pub-cache download can exceed 10 min (re-run resumes from warm cache). 2026-11-17: cold-cache run took >10 min and was still filling (~4 MB/min observed mid-run).
- `flutter analyze` — must pass with zero issues.
- `flutter test` — full app suite (~22 min on this runner; 7345 passing / 45 skipped as of 2026-11-16). `test/tool/patch_agp9_pub_plugins_test.dart` shells out to `flutter` — the suite must run with a WRITABLE SDK first on `PATH`.
- `flutter test --run-skipped <file>` — runs the repo's local-only microbenchmarks; select one with `--plain-name '<name>'` (`-n` does not exist on the pinned Flutter). Run A/B arms sequentially, ONE implementation per fresh process.
- `dart format lib test packages/*/lib packages/*/test` — the formatter (`flutter format` does not exist).
- `dart run build_runner build` — regenerate Drift/Riverpod/Freezed outputs.
- `bash .github/scripts/validate_ci_gates.sh` — format + codegen drift + gates (`--fix`, `--analyze`, `--test`, `--all`).

## SDK / sandbox setup (2026-11-17)

- Toolcache SDK at `/home/runner/.toolcache/flutter-3.47.6-stable/flutter` is READ-ONLY — `flutter` exits 1 writing `bin/cache/engine.stamp`. Fix: `cp -a` the SDK to `/tmp/gh-aw/agent/sdk/flutter` (~2.3 GB, ~1 min) and put `/tmp/gh-aw/agent/sdk/flutter/bin` first on `PATH`.
- `package:sqlite3` downloads a prebuilt Linux library from github.com which the proxy BLOCKS. Workaround: temporary `hooks: user_defines: sqlite3:` block in `pubspec.yaml` pointing at system `libsqlite3`. NEVER commit it (established 2026-11 runs).
