# Validated commands

- `flutter pub get` — resolves against pub.dev; cold pub-cache download can exceed 10 min (re-run resumes from warm cache). On a fresh runner: budget with run_in_background + max timeout.
- `flutter analyze` — must pass with zero issues.
- `flutter test` — full app suite (~20 min on this runner; 7436 passing / 61 skipped as of 2026-11-20). `test/tool/patch_agp9_pub_plugins_test.dart` shells out to `flutter` — the suite must run with a WRITABLE SDK first on `PATH`.
- `flutter test --run-skipped <file>` — runs the repo's local-only microbenchmarks; select one with `--plain-name '<name>'` (`-n` does not exist on the pinned Flutter). Run A/B arms sequentially, ONE implementation per fresh process.
- `dart format lib test packages/*/lib packages/*/test` — the formatter (`flutter format` does not exist).
- `dart run build_runner build --delete-conflicting-outputs` — regenerate Drift/Riverpod/Freezed outputs (~41 s warm).
- `bash .github/scripts/validate_ci_gates.sh` — format + codegen drift + gates (`--fix`, `--analyze`, `--test`, `--all`).
- `bash .github/scripts/check_dart_format.sh` / `check_codegen_drift.sh` — individual gates, both green 2026-11-20.

## SDK / sandbox setup (refreshed 2026-11-20)

- Toolcache SDK at `/home/runner/.toolcache/flutter-3.47.6-stable/flutter` is READ-ONLY — `flutter` exits 1 writing `bin/cache/engine.stamp`. Fix: `cp -a` the SDK to `/tmp/gh-aw/agent/sdk/flutter` (~2.3 GB, ~1 min) and put `/tmp/gh-aw/agent/sdk/flutter/bin` first on `PATH`.
- `package:sqlite3` (3.9.1) downloads its prebuilt Linux library from github.com and the TLS-intercepting proxy breaks it for curl AND Dart HttpClient (self-signed cert); `tool/prefetch_sqlite3_libs.sh` fails the same way. Working workaround: temporary top-level pubspec.yaml block
  ```yaml
  hooks:
    user_defines:
      sqlite3:
        source: system
  ```
  (ONE nesting level under `user_defines:` — a second `sqlite3:` level is silently ignored, hook keeps downloading). NEVER commit it; revert before `git add`. System libsqlite3 (`/lib/x86_64-linux-gnu/libsqlite3.so`) ran the full suite.
