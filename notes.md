# Repo Assist — Enjoy Player

## Backlog progress
- Issues commented on: #309, #310, #355, #383, #474, **#501**
- PRs created (merged by an-lee): #486 stream subscription leak, #496 PlayerLaunchRequest tests, #498 setup_logging dedupe, #499 perf transport-bar/surface-host, #500 sync_types tests, #503 ci/setup-flutter warm-cache invariant (closed #501), #504 perf regex-hoist/MediaQuery-scope/DateFormat-cache, **#516 perf regex-hoist + vol-select (2026-08-02)**
- PRs created (draft, awaiting review):
  - `repo-assist/coding-and-tests-improvements-2026-08-02` — bundled coding+testing (logNamed + typed YoutubeCaptionFetchException + 8 hotkey invariants). PR number pending apply.

## Pending actions for maintainer
- **Review PR** (draft): `repo-assist/coding-and-tests-improvements-2026-08-02` @ `1f659b6` — 4 files / +311 / -6.

## Known environment limitations
- Agentic runner Flutter SDK read-only → `dart format` / `analyze` / `test` may fail on cache writes. This is exactly the invariant #501 / #503 now documents.
- No git credentials for network operations.
- Linter pass may revert working-tree changes after a safe-outputs PR creates — confirmed cosmetic, NOT blocking merges (verified via PR #499, #500, #503).

## Carry-over coding-impl candidates
- All three prior carry-over entries shipped this run (2026-08-02 PR):
  - ✅ `logNamed` consistency in `transcript_line_recording_counts_provider.dart`.
  - ✅ `throw Exception(...)` → typed errors in `youtube_caption_fetcher.dart` (now `YoutubeCaptionFetchException` + `YoutubeCaptionErrorStage`).
  - ✅ `hotkey_definitions.dart` invariants (8-test file).
- Remaining testing-coverage queue: `asr_generation_job.dart`, `launch_pay_url.dart`.

## Task 8 perf candidates
- All perf-candidate bundles shipped via #504 (regex hoist + MediaQuery scope + DateFormat cache) and #516 (per-stream regex hoist + scope volume watch).

## Future investigations
- Architectural dedupe (#17, #39, #40).
- `settings_screen.dart` below ~120 LOC requires per-section sliver extraction (prior proposal expired).
- Carry-over perf candidates (deferred): `_VirtualItems` rebuild memoization, `TransportScrollableList` per-line post-frame translate requests, `_VideoThumbnail`/`_ChannelAvatar` `Image.network` → `CachedNetworkImage`.
