# Test Improver run state

## Last run

- **Run date**: 2026-06-27 (UTC)
- **Run URL**: https://github.com/baizhiheizi/enjoy_player/actions/runs/28283443986
- **Branch**: test-assist/distribution-channel-coverage
- **Files added**: `test/core/release/distribution_channel_test.dart` (17 tests)
- **PR-fallback patch**: `/tmp/gh-aw/aw-test-assist-distribution-channel-coverage.patch`

## Validation commands (validated 2026-06-27)

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Pre-existing failures on main (NOT introduced by this run):
- `test/core/logging/log_redaction_test.dart` — Windows-path shortening (Issue #23, fix branch: `repo-assist/fix-windows-path-redaction-5c65346f188bda5f` — likely already merged).
- `test/features/discover/recommended_channels_test.dart` — expects 5 channels, JSON has 1 (TDD WIP).
- `test/features/library/library_media_provider_test.dart` — compilation error, missing `test/features/support/test_path_provider.dart` and undefined `appDatabaseProvider`. Pre-existing infra gap, blocks the file from running. Worth filing a bug.

Pre-existing formatting issues in 40 unrelated test files (NOT introduced by this run):
- `test/features/discover/{discover_dedupe_test,discover_horizontal_strips_test,discover_subscribe_actions_test,discover_subscribe_sheet_test}.dart`
- `test/features/library/library_media_provider_test.dart`
- `test/features/player/{youtube_playback_stall_watchdog_test,youtube_player_engine_test}.dart`
- `test/features/share_poster/practice_poster_aggregate_test.dart`
- `test/features/transcript/transcript_scrollable_list_test.dart`
- …and others.
- The repo does not currently enforce `dart format` on the test tree; new test files I add are clean.

## Test counts

- **Before this run (main)**: 464 pass / 467 total = 3 pre-existing failures (log_redaction Windows, recommended_channels WIP, library_media_provider compile error). PRs #58, #63, #67 were merged earlier today (each +12 / +20 / +18 tests) — that accounts for the bump from the previous run's 365→464.
- **After this run (test-assist/distribution-channel-coverage)**: 481 pass / 483 total = same 3 pre-existing failures, +17 from this PR.

## Backlog (pure-Dart utility files with no test coverage)

- `lib/data/subtitle/embedded_subtitle_service.dart` (443 LOC) — heavy ffmpeg dep, MVP scope.
- `lib/data/api/json_isolate.dart` (11 LOC) — thin wrapper, indirectly covered by #63.
- `lib/core/errors/app_failure.dart` (42 LOC) — sealed class hierarchy with `NetworkFailure.statusCode`.
- ~~`lib/core/release/distribution_channel.dart` (40 LOC)~~ — **covered this run** (17 tests, PR-fallback ready).

## Recent runs (reverse chronological)

| Date (UTC) | Run | Goal | Outcome |
|---|---|---|---|
| 2026-06-27 08:46 | 28283443986 | distribution_channel coverage | 17 new tests, PR-fallback ready |
| 2026-06-26 09:09 | 28227075975 | subtitle_filename coverage | 18 new tests, PR #67 (merged) |
| 2026-06-25 08:55 | 28157522538 | case_conversion coverage | 20 new tests, PR #63 (merged) |
| 2026-06-24 08:57 | 28086120065 | diagnostic_log_config coverage + #23 bug filed | 12 new tests, PR #58 (merged); bug #23 filed |

## Open Test Improver PRs (awaiting review)

- This run: `test-assist/distribution-channel-coverage` (PR-fallback, patch at `/tmp/gh-aw/aw-test-assist-distribution-channel-coverage.patch`)

## Round-robin backlog order

Pick the next test target from the Backlog above. Prefer the smallest pure-Dart file that has real logic but is missing direct coverage. After `app_failure.dart` is covered, the next candidates are:
1. `app_failure.dart` (42 LOC) — sealed class hierarchy + `NetworkFailure.statusCode` + `toString()` contract
2. `json_isolate.dart` (11 LOC) — direct contract test
3. `embedded_subtitle_service.dart` (443 LOC) — heavy ffmpeg, large, MVP-relevant

## Pre-existing bugs filed by Test Improver

- #23: `log_redaction: Windows absolute paths are not shortened` — fix branch from Repo Assist exists, likely merged.

## Monthly activity issue

- Previous `#22` (June 2026) was closed 2026-06-27 06:03 UTC as `not_planned` (a new monthly issue was created by the workflow on the same day).
- This run opened a fresh monthly issue for the second June 2026 round.

## Notes

- The Flutter SDK is read-only at `/opt/hostedtoolcache/flutter/stable-3.44.0-x64/`; the runner must `cp -r` it to `/tmp/flutter_sdk/` and `chmod -R u+w` to allow `flutter pub get` to write. This is a runner quirk, not a repo issue.
- PRs created by the Test Improver agent are emitted as PR-fallback patches (saved to `/tmp/gh-aw/aw-*.patch`) when GH Actions lacks PR permissions. The maintainer (an-lee) opens the actual PR from the patch.
- The `library_media_provider_test.dart` compilation error is a new finding worth filing as a separate bug — it blocks the test suite from loading that file.
