# Testing

## Commands

Cheap CI gates (format + codegen drift + path-deps governance) — run before every push that touches Dart:

```bash
bash .github/scripts/validate_ci_gates.sh
bash .github/scripts/validate_ci_gates.sh --fix             # write format + regenerate codegen
bash .github/scripts/validate_ci_gates.sh --test --coverage # + test, then enforce the coverage gate
bash .github/scripts/validate_ci_gates.sh --all             # + analyze + test + coverage gate + path packages
bash .github/scripts/validate_ci_gates.sh --test --changed-only # only the test files that exist for the lib/test sources this branch touched (vs the merge base; excludes --coverage)
```

Individual commands:

```bash
bash .github/scripts/check_dart_format.sh
bash .github/scripts/check_codegen_drift.sh
flutter test
flutter test --coverage
flutter analyze
```

After generating coverage, enforce the CI baseline locally:

```bash
bash .github/scripts/check_coverage_gate.sh coverage/lcov.info
```

CI uploads `coverage/lcov.info` to [Codecov](https://codecov.io) and fails when line coverage drops below the recorded baseline (see `MIN_COVERAGE` in `.github/scripts/check_coverage_gate.sh`, currently **32%**).

## Layout

| Area | Location |
|------|----------|
| Echo window math | `test/features/player/echo_window_test.dart` |
| PlayerController (fake engine) | `test/features/player/player_controller_test.dart` |
| Media library repository | `test/features/library/library_repository_test.dart` |
| Transcript repository + lines cache | `test/features/transcript/transcript_repository_test.dart` |
| Transcript lines provider | `test/features/transcript/transcript_lines_provider_test.dart` |
| File import (streaming hash) | `test/data/files/file_storage_test.dart` |
| Subtitle parsers | `test/data/subtitle/subtitle_parser_test.dart` |
| Sync queue + retry backoff | `test/features/sync/sync_queue_repository_test.dart`, `test/features/sync/sync_engine_test.dart` |
| Azure WAV normalization | `test/features/ai/azure_assessment_wav_normalizer_test.dart` |
| AI service `ApiException → AppFailure` translation | `test/features/ai/chat_service_test.dart` |
| Echo PCM extraction guards | `test/features/shadow_reading/echo_segment_pcm_extractor_test.dart` |
| Sliver key index helper | `test/core/utils/sliver_key_index_test.dart` |
| App smoke (EnjoyApp) | `test/widget_test.dart` |
| Drift smoke | `test/data/db/app_database_test.dart` |
| Logging test infrastructure (`TestLoggingScope`) | `test/support/test_logging.dart` |

## Gallery (opt-in screenshots)

The Duet gallery ([docs/design/duet/](design/duet/README.md)) renders app screens to PNGs so they can be compared with the design boards. Plain `flutter test` skips these tests:

```bash
flutter test                                              # gallery reported as skipped
flutter test --tags gallery --run-skipped test/duet_gallery   # writes build/duet_gallery/<Board>.png
bash tool/duet_compare.sh Main DEcho                      # → build/duet_gallery/compare/<Board>.png
```

- `test/duet_gallery/gallery_support.dart` holds the board presets (desktop 1440 × 900 at 1×, compact 880 × 560 at 1×, phone 390 × 844 at 2×), the light/dark switch, and the capture. Fonts load from the bundled assets only — no network.
- `test/duet_gallery/fixtures.dart` holds the `ProviderScope` fixtures (in-memory Drift, signed-in profile, sample library) shared by the scenes.
- One test per board; the capture file name must match the board name in `docs/design/duet/renders/` so `tool/duet_compare.sh` can pair them.
- A maintainer-local prototype may exist at `test/_gallery/` (git-excluded); the committed harness does not depend on it.

## Pre-release (platform compile)

CI runs debug smoke builds plus **release compile** for Android (`apk` + `appbundle`), Windows (`--release`), iOS (`--release --no-codesign`), and macOS (`--release` with ad-hoc signing) — see `.github/workflows/`. Locally, before tagging:

```bash
flutter build appbundle --release   # with android/key.properties for real signing
flutter build apk --release --split-per-abi
flutter build windows --release
flutter build ios --release --no-codesign   # compile-only smoke
flutter build macos --release
flutter build ipa --release --export-options-plist=ios/ExportOptions.export.plist
```

See [packaging.md](packaging.md) for signing, FFmpeg, Inno Setup installer, and Apple release steps.

## Guidelines

- Every behavior change needs automated coverage or a documented manual verification reason.
- Prefer **fast, deterministic** unit tests (no real `Player` in CI unless using integration harness).
- Add unit tests for pure logic, parsers, repositories, Drift DAOs, Riverpod notifiers, and bug fixes.
- Add widget or integration tests when navigation, input, localization, platform chrome, or shared UI behavior cannot be proven with unit tests alone.
- Include a performance verification note for playback, startup, scrolling, transcript rendering, sync, and media import changes.
- For playback integration, use a dedicated integration harness rather than constructing `media_kit` `Player()` directly in tests.
- After changing `@DriftDatabase` or `@Riverpod` annotations, run `dart run build_runner build` (or `bash .github/scripts/check_codegen_drift.sh --fix`) and **commit** the regenerated files before tests or push.
