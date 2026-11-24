# Validated commands

- `flutter pub get` — resolves against pub.dev; cold pub-cache download can exceed 10 min (re-run resumes from warm cache). On a fresh runner: budget with run_in_background + max timeout.
- `flutter analyze` — must pass with zero issues.
- `flutter test` — full app suite (~20 min on this runner; 7537 passing / 71 skipped as of 2026-11-24). `test/tool/patch_agp9_pub_plugins_test.dart` shells out to `flutter` — the suite must run with a WRITABLE SDK first on `PATH`. The sqlite3 system-lib pubspec workaround must stay in place for the WHOLE verify pass: native assets build the sqlite3 hook during `flutter test` itself (2026-11-24: reverting after pub get failed the suite with "Building native assets failed").
- Path packages: CI's "Flutter test (path packages)" job runs `cd packages/<pkg> && flutter pub get && flutter test` for every package with a test dir — package-local benches + tests belong in packages/<pkg>/test/.
- Pinned-SDK download: ~1 GB takes ~45 min on this sandbox's throttled link; `curl -C - -o flutter.tar.xz <url>` resumes a killed download.
- `flutter test --run-skipped <file>` — runs the repo's local-only microbenchmarks; select one with `--plain-name '<name>'` (`-n` does not exist on the pinned Flutter). Run A/B arms sequentially, ONE implementation per fresh process.
- `dart format lib test packages/*/lib packages/*/test` — the formatter (`flutter format` does not exist).
- `dart run build_runner build --delete-conflicting-outputs` — regenerate Drift/Riverpod/Freezed outputs (~41 s warm).
- `bash .github/scripts/validate_ci_gates.sh` — format + codegen drift + gates (`--fix`, `--analyze`, `--test`, `--all`).
- `bash .github/scripts/check_dart_format.sh` / `check_codegen_drift.sh` — individual gates, both green 2026-11-20.

## SDK / sandbox setup (refreshed 2026-11-23)

- 2026-11-23: `main` (since #1454) pins Flutter **3.50.1** via `mise.toml` (`[tools] flutter = "3.50.1"`) — the toolcache `flutter-3.47.6-stable` is TOO OLD to compile `lib/` (`ScrollCacheExtent`, defined in `src/rendering/viewport.dart` but not exported by 3.47.6's `widgets.dart`, is used by transcript_scrollable_list.dart). The pinned SDK downloads fine from `https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.50.1-stable.tar.xz` (the exact URL CI's `.github/actions/setup-flutter` uses; ~1 GB); `storage.flutter-io.cn` (workflow env mirror) is NOT reachable from this sandbox. Copy a fresh toolcache SDK only if the pin matches it; otherwise download the pinned version from googleapis.
- Older-SDK toolcache copies are READ-ONLY — `flutter` exits 1 writing `bin/cache/engine.stamp`. Fix: `cp -a` the SDK to `/tmp/gh-aw/agent/sdk/<ver>` and put its `bin` first on `PATH`.
- `package:sqlite3` (3.9.1) downloads its prebuilt Linux library from github.com and the TLS-intercepting proxy breaks it for curl AND Dart HttpClient (self-signed cert); `tool/prefetch_sqlite3_libs.sh` fails the same way. Working workaround: temporary top-level pubspec.yaml block
  ```yaml
  hooks:
    user_defines:
      sqlite3:
        source: system
  ```
  (ONE nesting level under `user_defines:` — a second `sqlite3:` level is silently ignored, hook keeps downloading). NEVER commit it; revert before `git add`. System libsqlite3 (`/lib/x86_64-linux-gnu/libsqlite3.so`) ran the full suite.
