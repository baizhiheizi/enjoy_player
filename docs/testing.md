# Testing

## Commands

```bash
flutter test
flutter analyze
```

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

- Prefer **fast, deterministic** unit tests (no real `Player` in CI unless using integration harness).
- For playback integration, plan dedicated integration tests / golden tests later.
- After changing `@DriftDatabase` or `@Riverpod` annotations, run `dart run build_runner build` before tests.
