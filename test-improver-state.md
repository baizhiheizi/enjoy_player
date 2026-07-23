# Test Improver run state

## Last run

- **Run date**: 2026-07-23 21:22 UTC
- **Run URL**: https://github.com/baizhiheizi/enjoy_player/actions/runs/30045571456
- **Run ID**: 30045571456
- **Round-robin tasks**: Task 2/3 (asr_long_form_models.dart — 51 tests), Task 4 (no open PRs), Task 7 (monthly issue #166 updated).
- **Branch**: `test-assist/asr-long-form-models-coverage`
- **Commit**: `603df4d` (`test: add 51 unit tests for ASR long-form domain models`)
- **Files changed**: `test/features/asr/domain/asr_long_form_models_test.dart` (new, 525 lines, 51 tests)
- **PR**: Draft PR created via safeoutputs: `[test-improver] test: add 51 unit tests for ASR long-form domain models`
- **Monthly issue**: #166 updated with new 2026-07-23 entry prepended to Run History, Suggested Actions cleaned up.

## Work completed

Added 51 unit tests for `lib/features/asr/domain/asr_long_form_models.dart`:

1. **AsrLongFormJobStatus** (17 tests): `parse` for all 5 known values + unknown/null/empty; `isTerminal` for all 5 values; `isPending` for all 5 values.
2. **AsrLongFormFailure** (4 tests): Constructor, `fromJson` with all/missing/null fields, default fallback values.
3. **AsrLongFormUsage** (6 tests): Constructor, camelCase/snake_case parsing, key precedence, numeric coercion (int→double), missing defaults.
4. **AsrLongFormTranscript** (7 tests): Constructor, full JSON parse, null/missing segments/words, non-map filtering, snake_case fallback.
5. **AsrLongFormJob** (7 tests): Constructor, full nested parse, minimal job, snake_case keys, unknown status, null nested objects.
6. **AsrLongFormAttempt** (10 tests): Constructor, `fromJson` all/missing/empty fields, missing startedAt epoch fallback, `toJson` all/omits nulls, `copyWith` semantics.

## Validation commands (validated 2026-07-23)

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
- New tests: 51 pass / 0 fail
- `flutter analyze` — No issues found
- `dart format` — Clean

## Testing backlog (priority order)

1. `lib/data/subtitle/embedded_subtitle_service.dart` — highest behavioral risk (track filtering, language dedupe, fallback extraction, temp cleanup) but needs FFmpeg/process/platform seams first.
2. `lib/core/logging/diagnostic_session_header.dart` — locale/WebView field inclusion and privacy contracts; needs metadata/sink injection.

Completed and removed from the active backlog:

- `lib/features/asr/domain/asr_long_form_models.dart` — **51 tests added this run** (draft PR created)
- `lib/features/vocabulary/domain/vocabulary_models.dart` — **49 tests added 2026-07-22** (merged as PR #432)
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
- Flutter 3.44.0 toolchain on this runner has read-only engine cache (overlayfs); copy to `/tmp/gh-aw/agent/flutter_copy/` works as workaround for `flutter pub get` and `flutter test`.

## GitHub state verified 2026-07-23

- Open Test Improver PRs: 1 draft PR (this run — asr-long-form-models-coverage).
- Merged Test Improver PRs this month: #432 (vocabulary_models), #416 (logging infrastructure), #398 (yin_pitch), plus earlier PRs #75, #67, #63, #58.
- Monthly issue #166 updated this run.
- No maintainer comments or checkbox changes on #166 since last run.
- No other testing-labeled issues exist in the repo.
- Top backlog items remain: embedded_subtitle_service (needs FFmpeg seams), diagnostic_session_header (needs injection).

## Run history

- 2026-07-23 / 30045571456 — asr_long_form_models.dart, branch `test-assist/asr-long-form-models-coverage`, commit `603df4d`, 51 tests.
- 2026-07-22 / 29958669216 — vocabulary_models.dart, merged as PR #432.
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
