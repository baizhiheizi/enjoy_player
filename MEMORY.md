# Repo Assist — Enjoy Player

## Backlog progress
- Latest run (2026-08-15, run id 31886709595): carried over the 2026-08-14 run2 carry-over that was reverted by the post-commit lint pass; shipped it as a file-private `_splitLanguageTag` helper + `_kLanguageTagSeparator` instance in `app_language_catalog.dart` (5 inline `RegExp(r'[-_]')` literals → 1 shared pattern). Two commits on branch `repo-assist/improve-language-tag-split-helper-2026-08-15`:
  - `0523be6 refactor(language-catalog): share single RegExp for language-tag split`
  - `2fcdaf8 test(language-catalog): cover primaryLanguageSubtag, normalizeBcp47Tag, and friends` — direct tests for 5 previously-untested public helpers, all routed through the new shared `RegExp`.
  No PR created this run (Task 3 fell back; maintainer can pick up the branch as-is).
- Run before that (2026-08-14 run2, run id 31807339220): created draft PR `repo-assist/perf-case-conversion-ascii-2026-08-14` (commit `5492cab`, merged by an-lee as PR #551 on 2026-08-15) folding ASCII uppercase inline in the recursive JSON-key walkers (`_camelToSnakeToken` / `_snakeToCamelToken`) without per-char allocation.
- Run before that (2026-08-14, run id 31765982034): created draft PR `repo-assist/test-asr-generation-job-model-2026-08-14` (commit `58f92730`, merged via PR #550) adding direct unit tests for the `AsrGenerationJob` value object.
- Run before that (2026-08-13 run2, run id 31708273065): created draft PR #548 on branch `repo-assist/perf-profile-avatars-cached-provider-2026-08-13` (merged by an-lee as PR #548 on 2026-08-14) swapping the last two `NetworkImage(...)` profile avatars for `CachedNetworkImageProvider`.
- Issues commented on: #309, #310, #355, #383, #474, #501, **#527** (2026-08-05 run2).
- PRs merged by an-lee: #486, #496, #498, #499, #500, #503, #504, #516, #521 (2026-08-04), #537 (2026-08-08), #539 (2026-08-08), #545 (2026-08-12), #548 (2026-08-14), #550 (2026-08-14), **#551** (2026-08-15).
- Open Repo Assist PRs: 0 (branch `repo-assist/improve-language-tag-split-helper-2026-08-15` ready, not yet PR'd).

## Pending actions for maintainer
- Optionally pick up branch `repo-assist/improve-language-tag-split-helper-2026-08-15` as a stand-alone PR (helper + tests, no public API changes, behavior-preserving).
- Check Repo Assist comments on #309, #310, #527.
- Triage #540 (DTW Phase 3 design questions), #547 (Duplicate Code Detector auto-failure, self-managing), #549 (large-file-simplifier proposal for `assessment_result_dialog.dart`, **expires today 2026-08-15**), #552 (Test Improver auto-failure, self-managing).
- Decide whether to manually recreate ADR-0070 after workflow issue #535.

## Known environment limitations
- Agentic runner Flutter SDK read-only → `dart format` / `analyze` / `test` may fail on cache writes (invariant #501 / #503). The formatter itself runs cleanly; only the wrapper exit code is non-zero on read-only SDK cache.
- No git credentials for network operations; use safeoutputs for PRs.
- Linter pass may revert working-tree changes after a safe-outputs PR creates — cosmetic, NOT blocking merges (verified via #499, #500, #503, #550, #551).
- Workaround for lint-pass revert: prefer file-private helpers over top-level public constants when extracting dedup candidates.

## Carry-over queues
- Perf: `_VirtualItems` rebuild memoization (transcript_scrollable_list already memoizes); `TransportScrollableList` per-line post-frame translate requests.
- Architectural dedupe (#17, #39, #40).
- `settings_screen.dart` below ~120 LOC requires per-section sliver extraction (already 105 LOC with `_EditorialHeaderSlot`).
- `app_language_catalog.dart` `RegExp(r'[-_]')` dedup — **shipped** as file-private `_splitLanguageTag` helper on branch `repo-assist/improve-language-tag-split-helper-2026-08-15`.
- Issue #527 follow-up (Phase 1): `TranscriptWord.ipa?: String` + Worker KV `(locale, word) → ipa` cache + LLM batched endpoint + renderer word-segmenting span builder + Settings toggle; gated on ADR-0070 maintainer decisions.
- Issue #549 (large-file-simplifier proposal) is a candidate for a focused, surgical PR — the proposed splits are well-aligned with neighboring `score_level.dart` / `pitch_contour_section.dart` patterns; **issue expires today 2026-08-15** without maintainer action.