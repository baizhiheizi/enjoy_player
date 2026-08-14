# Repo Assist — Enjoy Player

## Backlog progress
- Latest run (2026-08-14, run id 31765982034): created draft PR `repo-assist/test-asr-generation-job-model-2026-08-14` (commit `58f92730`) adding direct unit tests for the `AsrGenerationJob` value object; refreshed monthly summary #522.
- Run before that (2026-08-13 run2, run id 31708273065): created draft PR #548 on branch `repo-assist/perf-profile-avatars-cached-provider-2026-08-13` swapping the last two `NetworkImage(...)` profile avatars for `CachedNetworkImageProvider`.
- Run before that (2026-08-13, run id 31663168346): no-action run; refreshed monthly summary #522 with the new #547 (Duplicate Code Detector auto-failure) entry.
- Issues commented on: #309, #310, #355, #383, #474, #501, **#527** (2026-08-05 run2).
- PRs merged by an-lee: #486, #496, #498, #499, #500, #503, #504, #516, #521 (2026-08-04), #537 (2026-08-08), #539 (2026-08-08), #545 (2026-08-12).
- Open Repo Assist PRs: #548 (profile avatars), `repo-assist/test-asr-generation-job-model-2026-08-14` (AsrGenerationJob direct tests).

## Pending actions for maintainer
- Review PR #548 + the AsrGenerationJob test PR if/when the bridge records the number.
- Check Repo Assist comments on #309, #310, #527.
- Triage #540 (DTW Phase 3 design questions), #547 (Duplicate Code Detector auto-failure, self-managing), #549 (large-file-simplifier proposal for `assessment_result_dialog.dart`, expires 2026-08-15).
- Decide whether to manually recreate ADR-0070 after workflow issue #535.

## Known environment limitations
- Agentic runner Flutter SDK read-only → `dart format` / `analyze` / `test` may fail on cache writes (invariant #501 / #503).
- No git credentials for network operations.
- Linter pass may revert working-tree changes after a safe-outputs PR creates — cosmetic, NOT blocking merges (verified via #499, #500, #503).

## Carry-over queues
- Perf: `_VirtualItems` rebuild memoization (transcript_scrollable_list already memoizes); `TransportScrollableList` per-line post-frame translate requests.
- Architectural dedupe (#17, #39, #40).
- `settings_screen.dart` below ~120 LOC requires per-section sliver extraction (already 105 LOC with `_EditorialHeaderSlot`).
- Issue #527 follow-up (Phase 1): `TranscriptWord.ipa?: String` + Worker KV `(locale, word) → ipa` cache + LLM batched endpoint + renderer word-segmenting span builder + Settings toggle; gated on ADR-0070 maintainer decisions.
- Issue #549 (large-file-simplifier proposal) is a candidate for a focused, surgical PR — the proposed splits are well-aligned with neighboring `score_level.dart` / `pitch_contour_section.dart` patterns; would only start once maintainer signals approval.