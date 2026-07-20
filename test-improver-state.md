# Test Improver run state

## Last run

- **Run date**: 2026-07-20 19:30 UTC
- **Run URL**: https://github.com/baizhiheizi/enjoy_player/actions/runs/29779703358
- **Round-robin tasks**: Task 1 (skipped — commands validated recently), Task 3 (yin_pitch tests: implemented, branch committed, PR-fallback patch created), Task 4 (no open test-improver PRs to maintain), Task 5 (no other testing issues besides monthly summary), Task 6 (pumpL10n infra skipped — duplication doesn't exist in repo tree), Task 7 (monthly issue #166 rewritten with 2026-07-16 and 2026-07-20 entries).
- **Branch**: `test-assist/yin-pitch-coverage`
- **Commit**: `194bb70` (`test: cover yin_pitch.dart pitch estimation and envelope mapping`)
- **Files**: `test/features/shadow_reading/domain/yin_pitch_test.dart` (new, 13 tests, 228 lines)
- **PR-fallback patch**: `/tmp/gh-aw/aw-test-assist-yin-pitch-coverage.patch` (9,470 bytes); bundle at `/tmp/gh-aw/aw-test-assist-yin-pitch-coverage.bundle` (3,126 bytes); maintainer opens the actual PR from the patch.
- **Monthly issue**: #166 updated with the mandatory exact structure (Suggested Actions first, reverse chronological Run History). This run folded in the missing 2026-07-16 (asr_failure_messages), 2026-07-14 (ffmpeg_media_probe), and 2026-07-13 (log_file_sink) run history entries alongside the new 2026-07-20 entry.

## Work completed

Added 13 unit tests for `lib/features/shadow_reading/domain/yin_pitch.dart` (164 LOC):

1. **`estimatePitchYin` (7 tests)** — empty samples, zero/negative sample rate, short buffer padding to frameSize, pure 440 Hz sine wave estimation (within 5%), custom frameSize/hopSize, yinThreshold=0 rejects all frames.
2. **`pitchAtEnvelopeTimes` (6 tests)** — empty envelope, zero pitch frames (all nulls), nearest-frame mapping, index clamping, voiced/unvoiced filter via minVoicedProb, non-positive/non-finite pitch rejection (negative, infinity, NaN, zero).

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

- Focused suite: 13 pass / 0 fail.
- Full suite: 1652 pass / 2 skip / 0 fail (was 1380/2/0 at 2026-07-16 baseline; net +272 tests from other landed work in the repo).
- `flutter analyze` → `No issues found!`
- `dart format`: Clean (after fixing one const/lint issue).
- Runner quirk: the installed Flutter SDK is read-only; copy it under `/tmp/gh-aw/agent/flutter_sdk/flutter/` and put that writable SDK first on `PATH`.

## Coverage impact

Not measured precisely this run — yin_pitch.dart is pure math and doesn't affect the coverage gate. Previous gate was 45.24% (≥32%). Sine wave test covers the main algorithmic path; threshold boundary covers the rejection path.

## Testing backlog (priority order)

1. `lib/data/subtitle/embedded_subtitle_service.dart` — highest behavioral risk (track filtering, language dedupe, fallback extraction, temp cleanup) but needs FFmpeg/process/platform seams first.
2. `lib/core/logging/setup_logging.dart` — startup filtering and one-time hook; needs root-listener/output injection and reset to avoid suite leakage.
3. `lib/core/logging/diagnostic_session_header.dart` — locale/WebView field inclusion and privacy contracts; needs metadata/sink injection.
4. `lib/features/sync/data/sync_upload_service.dart` (64 LOC) — needs `HttpClient`/`MultipartRequest` injection.
5. Issue #310 follow-up if streaming lands — SSE/NDJSON chunking, multibyte boundaries, cancellation, first-delta UI, final-only caching.
6. Issue #309 follow-up if word-recall lands — scorer boundaries, Azure word decoding, and feedback when pronunciation score is null.

Completed and removed from the active backlog:

- `lib/features/shadow_reading/domain/yin_pitch.dart` — covered this run (13 tests, commit `194bb70`).
- `lib/features/asr/application/asr_failure_messages.dart` — covered 2026-07-16 (20 tests, 47/47 lines).
- `lib/data/files/ffmpeg_media_probe.dart` — covered 2026-07-14 (26 tests, 27/36 lines).
- `lib/core/logging/log_file_sink.dart` — covered 2026-07-13 (6 tests, 60/60 lines).
- `lib/data/api/recording_client_platform_stub.dart` — covered 2026-07-11 (4 tests).
- `lib/data/files/media_resolver.dart` — covered 2026-07-09 (31 tests).
- `lib/features/ai/application/ai_api_failures.dart` — covered 2026-07-08 (11 tests).
- `lib/data/subtitle/transcript_line.dart` — covered 2026-07-06 (32 tests).
- `lib/core/utils/youtube_video_identity.dart` — covered 2026-07-02 (38 tests).
- `lib/core/errors/app_failure.dart` — covered 2026-07-01 (28 tests).

## Test infrastructure notes

- CI has a real coverage pipeline: `.github/workflows/ci.yml` runs `flutter test --coverage`, enforces 32% through `.github/scripts/check_coverage_gate.sh`, and uploads to Codecov.
- Stateful singleton/global services remain hard to isolate. Reset seams now exist for `LogFileSink` and `FfmpegMediaProbe` (`@visibleForTesting`); `setup_logging.dart` and `diagnostic_session_header.dart` still need similar seams.
- `TestPathProvider` is the preferred existing filesystem fake for application-support/document/temp paths.
- The `pumpL10n` AppLocalizations bootstrap duplication (noted in the previous run) doesn't exist in the repo tree — `asr_failure_messages_test.dart` was never merged. Only `ai_byok_error_mapping_test.dart` uses the inline pattern; extraction is premature until a second consumer materializes.
- PR creation requires GH Actions write permissions; when unavailable, the safe-output tool records a PR intent and falls back to a patch + bundle under `/tmp/gh-aw/`. Maintainer opens the actual PR from the patch. Older PR-fallback patches under `/tmp/gh-aw/` are not persistent across runs.

## GitHub state verified 2026-07-20

- Open Test Improver PRs before this run: none (no PR-fallback patch has been promoted by the maintainer yet).
- Only open automation PR is #393 from Perf Improver (discover refresh single-flight), not Test Improver concern.
- Monthly issue #166 updated this run with all missing entries and the new 2026-07-20 entry.
- No maintainer comments or checkbox changes on #166 since last run (still no human interaction).
- No other testing-labeled issues exist in the repo.

## Run history

- 2026-07-20 / 29779703358 — yin_pitch pitch detection, branch `test-assist/yin-pitch-coverage`, commit `194bb70`, 13 tests.
- 2026-07-16 / 29480365232 — asr_failure_messages dispatchers, branch `test-assist/asr-failure-messages-coverage`, commit `43ba892`, 20 tests, 47/47 target lines.
- 2026-07-14 / 29314396893 — ffmpeg_media_probe parsers, branch `test-assist/ffmpeg-media-probe-coverage`, commit `b6543e1`, 26 tests, 27/36 target lines.
- 2026-07-13 / 29235663615 — LogFileSink coverage, branch `test-assist/log-file-sink-coverage`, commit `97ed06e`, 6 tests, 60/60 target lines.
- 2026-07-11 / 29144375822 — recording-client platform stub, commit `172474a`, 4 tests.
- 2026-07-09 / 29006069001 — media resolver, commit `3b185eb`, 31 tests.
- 2026-07-08 / 28926245588 — AI API failures, commit `1484e0f`, 11 tests.
- 2026-07-06 / 28780847692 — transcript line, commit `75e414a`, 32 tests.
- 2026-07-02 / 28576284868 — YouTube video identity, commit `f896981`, 38 tests.
- 2026-07-01 / 28505844942 — app failure, commit `d93cf61`, 28 tests.
- 2026-06-27 / 28283443986 — distribution channel, 17 tests, merged #75.
- 2026-06-26 / 28227075975 — subtitle filename, 18 tests, merged #67.
- 2026-06-25 / 28157522538 — case conversion, 20 tests, merged #63.
- 2026-06-24 / 28086120065 — diagnostic log config, 12 tests, merged #58; bug #23 later fixed.
