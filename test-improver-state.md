# Test Improver run state

## Last run

- **Run date**: 2026-06-26 (UTC)
- **Run URL**: https://github.com/baizhiheizi/enjoy_player/actions/runs/28227075975
- **Branch**: test-assist/subtitle-filename-coverage
- **Files added**: `test/data/subtitle/subtitle_filename_test.dart` (18 tests)

## Validation commands (validated 2026-06-26)

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Pre-existing failures on main (NOT introduced by this run):
- `test/core/logging/log_redaction_test.dart` — Windows-path shortening (Issue #23, fix branch: `repo-assist/fix-windows-path-redaction-5c65346f188bda5f`)
- `test/features/discover/recommended_channels_test.dart` — expects 5 channels, JSON has 1 (TDD WIP)

## Test counts

- **Before this run (main)**: 365 pass / 367 total = 2 pre-existing failures
- **After this run (test-assist/subtitle-filename-coverage)**: 383 pass / 385 total = 2 pre-existing failures unchanged

## Backlog (pure-Dart utility files with no test coverage)

- `lib/data/subtitle/embedded_subtitle_service.dart` (443 LOC) — heavy ffmpeg dep
- `lib/data/api/json_isolate.dart` (11 LOC) — thin wrapper, indirectly covered
- `lib/core/errors/app_failure.dart` (42 LOC) — sealed class hierarchy
- `lib/core/release/distribution_channel.dart` (40 LOC) — enum resolver

## Recent runs (reverse chronological)

| Date (UTC) | Run | Goal | Outcome |
|---|---|---|---|
| 2026-06-26 09:09 | 28227075975 | subtitle_filename coverage | 18 new tests, PR ready |
| 2026-06-25 08:55 | 28157522538 | case_conversion coverage | 20 new tests, PR #35 ready |
| 2026-06-24 08:57 | 28086120065 | diagnostic_log_config coverage + #23 bug filed | 12 new tests, PR #21 ready; bug #23 filed |

## Open Test Improver PRs (awaiting review)

- This run: `test-assist/subtitle-filename-coverage` (subtitle_filename)
- #35: `test-assist/case-conversion-coverage-45e30a6d38691c07` (case_conversion)
- #21: `test-assist/diagnostic-log-config-6ae66a7f74fac2b3` (diagnostic_log_config)

## Round-robin backlog order

Pick the next test target from the Backlog above. Prefer the smallest pure-Dart file that has real logic but is missing direct coverage.

## Pre-existing bugs filed by Test Improver

- #23: `log_redaction: Windows absolute paths are not shortened` — fix branch from Repo Assist exists.
