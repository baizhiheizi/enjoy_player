# Repo Assist — Enjoy Player

## Backlog progress
- Latest run (2026-08-08): shared whitespace normalization refactor on `repo-assist/improve-text-normalization` (`#aw_txtnorm1`, commit `159c5c3`); no new issue comments because #309, #310, and #527 had no new human activity.
- Issues commented on: #309, #310, #355, #383, #474, #501, **#527** (2026-08-05 run2 — Phase 2 of IPA research shipped)
- PRs created (merged by an-lee): #486 stream subscription leak, #496 PlayerLaunchRequest tests, #498 setup_logging dedupe, #499 perf transport-bar/surface-host, #500 sync_types tests, #503 ci/setup-flutter warm-cache invariant (closed #501), #504 perf regex-hoist/MediaQuery-scope/DateFormat-cache, #516 perf regex-hoist + vol-select (2026-08-02), **#521** typed PayUrlLaunchException (2026-08-04)
- PRs created (draft, awaiting review):
  - `repo-assist/improve-text-normalization` (`#aw_txtnorm1`, commit `159c5c3`, 11 files / +57 / -18) — shared cached whitespace normalization helper + four tests.
  - `repo-assist/payurl-typed-exception-2026-08-04` (commit `efce7118`, 2 files / +135 / -6) — bundled coding+testing on `launchPayUrl`.
  - `repo-assist/coding-and-tests-improvements-2026-08-02` (commit `1f659b6`, 4 files / +311 / -6) — bundled coding+testing (logNamed + typed YoutubeCaptionFetchException + 8 hotkey invariants).
  - `repo-assist/perf-image-network-cache-2026-08-05` (commit `1bddded`, 3 files / +11 / -8) — Image.network → CachedNetworkImageProvider in discover_feed_tile + discover_channel_avatar + youtube_video_poster.
  - **`repo-assist/ipa-phase2-word-timings-2026-08-05` (commit `f66b9fcf`, 4 files / +445 / -9)** — Phase 2 of issue #527: `TranscriptWord` model + optional `words: List<TranscriptWord>?` on `TranscriptLine` + per-word spans attached by `buildAsrTranscriptLines` + 13 tests.

## Pending actions for maintainer
- Review onboarding test PR #537.
- Review draft `#aw_txtnorm1` shared normalization PR.
- Review prior draft branches listed above if they are recreated as pull requests.
- Check Repo Assist comments on #309, #310, and #527.
- Decide whether to manually recreate ADR-0070 after workflow issue #535.

## Known environment limitations
- Agentic runner Flutter SDK read-only → `dart format` / `analyze` / `test` may fail on cache writes. This is exactly the invariant #501 / #503 now documents.
- No git credentials for network operations.
- Linter pass may revert working-tree changes after a safe-outputs PR creates — confirmed cosmetic, NOT blocking merges (verified via PR #499, #500, #503).

## Carry-over perf candidates
- Last carry-over shipped via this run (2026-08-05 PR): `_VideoThumbnail` / `_ChannelAvatar` `Image.network` → `CachedNetworkImageProvider`. ✅
- Remaining perf queue (deferred):
  - `_VirtualItems` rebuild memoization (transcript_scrollable_list already memoizes via `_cachedVirtualItems`; verify there's no per-frame rebuild outside the cached path).
  - `TransportScrollableList` per-line post-frame translate requests.

## Carry-over testing-impl candidates
- `asr_generation_job.dart` model has no direct test, but `asr_generation_controller_test.dart` + `asr_generation_controller_long_form_test.dart` already exercise the model indirectly. Re-evaluate next run whether a dedicated model test is worth adding.

## Future investigations
- Architectural dedupe (#17, #39, #40).
- `settings_screen.dart` below ~120 LOC requires per-section sliver extraction (prior proposal expired).
- **Issue #527 follow-up (now unblocked by Phase 2 merge)**: extend `TranscriptWord` with `ipa?: String`; add Worker KV `(locale, word) → ipa` cache + LLM batched endpoint; extend `transcript_markup.dart` with a word-segmenting span builder; add the Settings toggle.
