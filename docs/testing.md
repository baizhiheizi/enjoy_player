# Testing

## Commands

```bash
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
- After changing `@DriftDatabase` or `@Riverpod` annotations, run `dart run build_runner build` before tests.
