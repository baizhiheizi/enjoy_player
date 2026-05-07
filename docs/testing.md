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

## Guidelines

- Prefer **fast, deterministic** unit tests (no real `Player` in CI unless using integration harness).
- For playback integration, plan dedicated integration tests / golden tests later.
- After changing `@DriftDatabase` or `@Riverpod` annotations, run `dart run build_runner build` before tests.
