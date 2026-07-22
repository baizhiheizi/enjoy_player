# Test Improver run state

## Last run

- **Run date**: 2026-07-22 21:22 UTC
- **Run URL**: https://github.com/baizhiheizi/enjoy_player/actions/runs/29958669216
- **Run ID**: 29958669216
- **Round-robin tasks**: Task 2 (explored testing opportunities), Task 3 (vocabulary_models.dart — 49 tests), Task 7 (monthly issue #166 updated).
- **Branch**: `test-assist/vocabulary-models-coverage`
- **Commit**: `64558d7` (`test: add comprehensive unit tests for vocabulary domain models`)
- **Files changed**: `test/features/vocabulary/vocabulary_models_test.dart` (new, 648 lines, 49 tests)
- **PR**: Draft PR created via safeoutputs: `[test-improver] test: add comprehensive unit tests for vocabulary domain models`
- **Monthly issue**: #166 updated with new 2026-07-22 entry prepended to Run History, Suggested Actions updated (removed merged items), backlog updated.

## Work completed

Added 49 unit tests for `lib/features/vocabulary/domain/vocabulary_models.dart`:

1. **Enums** (12 tests): `VocabularyStatus`, `VocabularyRating`, `VocabularySourceType` — wire values, `fromWire`/`fromValue` resolution, invalid-input error handling, case sensitivity.
2. **MediaLocator** (9 tests): JSON round-trip, type validation, `num` coercion, value equality/hashCode, inequality.
3. **EbookLocatorLocations** (6 tests): Null-field defaults, JSON round-trip with all fields, null fragments, numeric coercion.
4. **EbookLocator** (6 tests): JSON round-trip with/without optionals, nested locations parsing, type validation.
5. **VocabularyItem** (5 tests): Constructor, `copyWith` overrides, `clearLastReviewedAt` semantics.
6. **VocabularyContext** (5 tests): Constructor, `copyWith` overrides, `clearExplanation` semantics, ebook variant.
7. **VocabularyReview** (2 tests): Required and optional field construction.
8. **AddVocabularyResult** (2 tests): `isNewContext` true/false.
9. **ReviewUpdate** (1 test): Constructor field assignment.

## Validation commands (validated 2026-07-20)

```bash
flutter pub get
bash .github/scripts/validate_ci_gates.sh            # format + codegen drift
# bash .github/scripts/validate_ci_gates.sh --fix    # write format + regenerate
# bash .github/scripts/validate_ci_gates.sh --all   # + analyze + test
bash .github/scripts/check_dart_format.sh
bash .github/scripts/check_codegen_drift.sh
bash .github/scripts/check_coverage_gate.sh coverage/lcov.info
flutter analyze
flutter test --coverage
# Path packages: (cd packages/<name> && flutter pub get && flutter test)
```

Results:
- New tests: 49 pass / 0 fail
- Vocabulary suite: 186 pass / 0 fail
- `flutter analyze` → No issues found
- `dart format`: Clean

## Testing backlog (priority order)

1. `lib/data/subtitle/embedded_subtitle_service.dart` — highest behavioral risk (track filtering, language dedupe, fallback extraction, temp cleanup) but needs FFmpeg/process/platform seams first.
2. `lib/core/logging/diagnostic_session_header.dart` — locale/WebView field inclusion and privacy contracts; needs metadata/sink injection.

Completed and removed from the active backlog:

- `lib/features/vocabulary/domain/vocabulary_models.dart` — **49 tests added this run** (draft PR created)
- `lib/core/logging/setup_logging.dart` — seams added 2026-07-21, merged as PR #416
- `lib/features/shadow_reading/domain/yin_pitch.dart` — covered 2026-07-20, merged as PR #398.
- `lib/features/asr/application/asr_failure_messages.dart` — covered 2026-07-16 (20 tests).
- `lib/data/files/ffmpeg_media_probe.dart` — covered 2026-07-14 (26 tests).
- `lib/core/logging/log_file_sink.dart` — covered 2026-07-13 (6 tests).
- `lib/data/api/recording_client_platform_stub.dart` — covered 2026-07-11 (4 tests).
- `lib/data/files/media_resolver.dart` — covered 2026-07-09 (31 tests).
- `lib/features/ai/application/ai_api_failures.dart` — covered 2026-07-08 (11 tests).
- `lib/data/subtitle/transcript_line.dart` — covered 2026-07-06 (32 tests).
- `lib/core/utils/youtube_video_identity.dart` — covered 2026-07-02 (38 tests).
- `lib/core/errors/app_failure.dart` — covered 2026-07-01 (28 tests).

## Test infrastructure notes

- **Logging reset seams now in main**: `debugResetAppLogging()` and `LogFileSink.debugResetInstance()` plus `TestLoggingScope` utility merged as PR #416.
- CI has a real coverage pipeline: `.github/workflows/ci.yml` runs `flutter test --coverage`, enforces 32% through `.github/scripts/check_coverage_gate.sh`, and uploads to Codecov.
- Stateful singleton/global services remain hard to isolate. Reset seams now exist for `LogFileSink`, `FfmpegMediaProbe`, and `setup_logging.dart` (`@visibleForTesting`).
- `TestPathProvider` is the preferred existing filesystem fake for application-support/document/temp paths.
- `TestLoggingScope` in `test/support/test_logging.dart` is the shared utility for logging tests.
- PR creation uses safeoutputs tool; when successful, a draft PR is created on GitHub.

## GitHub state verified 2026-07-22

- Open Test Improver PRs: 1 draft PR (this run — vocabulary-models-coverage).
- Merged Test Improver PRs this month: #416 (logging infrastructure), #398 (yin_pitch), plus earlier PRs #75, #67, #63, #58.
- Monthly issue #166 updated this run with the 2026-07-22 entry prepended.
- No maintainer comments or checkbox changes on #166 since last run.
- No other testing-labeled issues exist in the repo.
- Top backlog items remain: embedded_subtitle_service (needs FFmpeg seams), diagnostic_session_header (needs injection).

## Run history

- 2026-07-22 / 29958669216 — vocabulary_models.dart, branch `test-assist/vocabulary-models-coverage`, commit `64558d7`, 49 tests.
- 2026-07-21 / 29869687091 — logging test infrastructure, merged as PR #416.
- 2026-07-20 / 29779703358 — yin_pitch pitch detection, merged as PR #398.
- 2026-07-16 / 29480365232 — asr_failure_messages dispatchers.
- 2026-07-14 / 29314396893 — ffmpeg_media_probe parsers.
- 2026-07-13 / 29235663615 — LogFileSink coverage.
- 2026-07-11 / 29144375822 — recording-client platform stub.
- 2026-07-09 / 29006069001 — media resolver.
- 2026-07-08 / 28926245588 — AI API failures.
- 2026-07-06 / 28780847692 — transcript line.
- 2026-07-02 / 28576284868 — YouTube video identity.
- 2026-07-01 / 28505844942 — app failure.
- June 2026 — merged PRs: #75 (distribution_channel), #67 (subtitle_filename), #63 (case_conversion), #58 (DiagnosticLogConfig).
