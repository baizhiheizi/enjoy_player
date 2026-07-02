# Test Improver run state

## Last run

- **Run date**: 2026-07-02 (UTC)
- **Run URL**: https://github.com/baizhiheizi/enjoy_player/actions/runs/28576284868
- **Branch**: test-assist/youtube-video-identity-coverage
- **Commit**: f896981 `test: add coverage for core/utils/youtube_video_identity.dart`
- **Files added/modified**: `test/core/utils/youtube_video_identity_test.dart` (38 tests — replaces 5-test scaffold; net +33)
- **PR-fallback patch**: `/tmp/gh-aw/agent/aw-test-assist-youtube-video-identity.patch` (11148 bytes)

## Validation commands (validated 2026-07-02)

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Pre-existing failures on main: **NONE this run.** Full suite is 764/2/0 (pass/skip/fail).

Two earlier pre-existing failures are now fixed upstream:

- `test/features/shadow_reading/echo_segment_pcm_extractor_test.dart::extractEntireFileMonoF32 returns null when media file is missing` — fixed by commit `b0a16e6` (2026-07-01, returns null up front when media file is missing, so ffmpeg-kit is never invoked).
- `test/core/logging/log_redaction_test.dart` Windows path shortening — fixed earlier (memory 2026-07-01 already noted it; confirmed fixed again this run).

Note: the `library_media_provider_test.dart` compilation error noted in 2026-06-29 memory is still not present (already fixed in the interim).

Note: pre-existing formatting issues in 75 unrelated test files (NOT introduced by this run). The repo does not currently enforce `dart format` on the test tree; new test files I add are clean.

## Test counts

- **Before this run (main)**: 731 pass / 0 fail / 2 skipped.
- **After this run (test-assist/youtube-video-identity-coverage)**: 764 pass / 0 fail / 2 skipped = net +33 from this PR (38 tests - 5 pre-existing scaffold tests).

## Backlog (pure-Dart utility files with no test coverage)

- `lib/data/subtitle/embedded_subtitle_service.dart` (443 LOC) — subtitle parsing/embedding in MVP scope. Heavy ffmpeg dep.
- `lib/data/api/recording_client_platform_stub.dart` (12 LOC) — platform-interface stub; documents the `UnsupportedError` contract on non-supported targets.
- `lib/data/api/query_params.dart` (`buildQuery`, 26 LOC) — null/empty-string filtering for `ApiClient` GETs.
- `lib/data/api/api_exception.dart` (31 LOC) — `isUnauthorized` (status==401) + `isDuplicateEntity` (4xx + body contains "already exists").
- `lib/core/ids/enjoy_ids.dart` (47 LOC) — UUID v5 / SHA-256 helpers (uses `package:uuid`, `package:crypto`).
- `lib/core/utils/remote_thumbnail_url.dart`, `sliver_key_index.dart`, `stream_distinct.dart`, `local_thumbnail.dart` — still candidates.
- ~~`lib/core/utils/youtube_video_identity.dart`~~ — **covered this run** (38 tests, PR-fallback ready).
- ~~`lib/core/errors/app_failure.dart`~~ — covered 2026-07-01 (28 tests, PR-fallback ready).
- ~~`lib/core/release/distribution_channel.dart`~~ — covered 2026-06-27 (17 tests, merged #75).
- ~~`lib/core/logging/diagnostic_log_config.dart`~~ — covered by #58 (merged).
- ~~`lib/data/api/case_conversion.dart`~~ — covered by #63 (merged).
- ~~`lib/data/subtitle/subtitle_filename.dart`~~ — covered by #67 (merged).
- ~~`lib/core/utils/time_format.dart`~~ — already has a test file (`test/core/utils/time_format_test.dart`, 16 tests, added between runs).
- ~~`lib/core/utils/byok_secret_mask.dart`~~ — already has a test file (`test/core/validation/byok_secret_mask_test.dart`, 1 test, added between runs).
- ~~`lib/core/validation/byok_url_guard.dart`~~ — already has a test file (added between runs).
- ~~`lib/core/json/json_cast.dart`~~ — already has a test file (added between runs).

## Recent runs (reverse chronological)

| Date (UTC) | Run | Goal | Outcome |
|---|---|---|---|
| 2026-07-02 | 28576284868 | youtube_video_identity coverage | 38 tests (replaces 5-test scaffold; net +33), PR-fallback ready, full suite green |
| 2026-07-01 | 28505844942 | app_failure coverage (round 2, redo) | 28 tests, PR-fallback ready |
| 2026-06-29 | 28364261078 | app_failure coverage (round 1) | 24 tests, PR-fallback lost between runs |
| 2026-06-27 | 28283443986 | distribution_channel coverage | 17 tests, merged #75 |
| 2026-06-26 | 28227075975 | subtitle_filename coverage | 18 tests, PR #67 (merged) |
| 2026-06-25 | 28157522538 | case_conversion coverage | 20 tests, PR #63 (merged) |
| 2026-06-24 | 28086120065 | diagnostic_log_config coverage + #23 bug filed | 12 tests, PR #58 (merged); bug #23 filed |

## Open Test Improver PRs / PR-fallbacks (awaiting review)

- 2026-07-01 round: `test-assist/app-failure-coverage` (commit `d93cf61`, PR-fallback patch at `/tmp/gh-aw/agent/aw-test-assist-app-failure-coverage.patch`) — awaiting PR creation by maintainer.
- 2026-07-02 round: `test-assist/youtube-video-identity-coverage` (commit `f896981`, PR-fallback patch at `/tmp/gh-aw/agent/aw-test-assist-youtube-video-identity.patch`) — awaiting PR creation by maintainer.

## Round-robin backlog order

After this run, the next candidates (lowest LOC, highest signal first):

1. `lib/data/api/recording_client_platform_stub.dart` (12 LOC) — small contract test for the `UnsupportedError` path.
2. `lib/data/api/query_params.dart` (26 LOC) — null/empty-string filtering, has multiple call sites per its comment.
3. `lib/data/api/api_exception.dart` (31 LOC) — `isUnauthorized` + `isDuplicateEntity` getters, cross-cutting error surface for the API layer.
4. `lib/core/ids/enjoy_ids.dart` (47 LOC) — UUID v5 / SHA-256 helpers; pure-Dart, dep on `package:uuid` + `package:crypto`.
5. `lib/data/subtitle/embedded_subtitle_service.dart` (443 LOC) — large, MVP-relevant, but heavy ffmpeg dep makes it a higher-cost candidate.

## Pre-existing bugs filed by Test Improver

- #23: `log_redaction: Windows absolute paths are not shortened` — fix branch from Repo Assist exists; **now confirmed fixed on main** (test no longer fails).

## Monthly activity issue

- #22 (June round 1) — closed 2026-06-27
- #76 (June round 2) — closed 2026-06-29
- (June round 3) was never created successfully (the 2026-06-29 run's `create_issue` may have failed silently; no record of it on the issue tracker)
- #166 `[test-improver] Monthly Activity 2026-07` — opened 2026-07-01, updated this run.

## Notes

- The Flutter SDK is read-only at `/opt/hostedtoolcache/flutter/stable-3.44.0-x64/`; the runner must `cp -r` it to `/tmp/flutter_sdk/` and `chmod -R u+w` to allow `flutter pub get` to write. Runner quirk, not a repo issue.
- PRs created by the Test Improver agent are emitted as PR-fallback patches (saved to `/tmp/gh-aw/agent/aw-*.patch`) when GH Actions lacks PR permissions. The maintainer (an-lee) opens the actual PR from the patch. `create_pull_request` returns success but stores the patch rather than pushing.
- Several backlog items get covered between runs by other agents or maintainers. **Always check the current test tree against the backlog before picking** — `Glob "test/**/*.dart"` for the source path, or `Grep` the file under test to find existing test files. This run discovered 4 stale backlog items (`time_format`, `byok_secret_mask`, `byok_url_guard`, `json_cast`) before settling on `youtube_video_identity`.
- The `update_issue` safe-output tool has a 10240-byte body limit (per-tool). The July issue body had to be compressed from ~10.9 KB to ~10.2 KB by trimming the older run-history entries' verbose test counts.
- **Patch retention note**: patches under `/tmp/gh-aw/agent/aw-*.patch` are NOT persistent across runs (the agent directory is recreated per workflow). If a patch is critical, copy it to the repo-memory folder. The 2026-06-29 run's patch was lost; this run hit the same pattern by re-creating work from scratch when `youtube_video_identity_test.dart` was found to have a 5-test scaffold added between runs.