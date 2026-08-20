# Repo Assist — Enjoy Player

## Backlog progress
- Latest run (2026-08-20, run id 32323340730): extracted the blocking 'importing' progress dialog that was duplicated verbatim across `importMediaFromPicker` (file flow) and `importYoutubeFromDialog` (YouTube flow) in `lib/features/library/presentation/library_actions.dart` into a single file-private `_showImportProgressDialog(context, label)` helper. The label is resolved via `String Function(AppLocalizations)` so each call site passes its own localized string. Branch `repo-assist/dedupe-import-progress-dialog-2026-08-20`, commit `924662e5`. Net -45 / +34 (file shrunk from 367 to 322 LOC). Pure refactor, no production behavior change. Refreshed monthly summary #522 — removed closed `repo-assist/improve-remove-orphan-toggle-word-loop-2026-08-18` (closed without merge on 2026-08-18), added new `repo-assist/dedupe-import-progress-dialog-2026-08-20` entry, trimmed verbose "Test status" lines and older non-actionable history entries.
- Run before that (2026-08-18, run id 32090446771): created draft PR `repo-assist/improve-remove-orphan-toggle-word-loop-2026-08-18` (commit `14c0e842`, closed without merge on 2026-08-18) deleting the orphan `PlayerInteractions.toggleWordLoop` method (zero callers).
- Run before that (2026-08-16, run id 31921209621): shipped `test/data/files/media_resolver_test.dart` (107 LOC, no production changes) on branch `repo-assist/test-media-resolver-helpers-2026-08-16` and pushed it as a draft PR via `safeoutputs create_pull_request`. Covers `isVideoFileName` / `isAudioFileName` / `isImportableLocalMediaFileName` and the three picker extension lists, including case-insensitivity, no-extension rejection, and disjoint audio/video sets. Posted a substantive check-in comment on #540 summarising the three shipped DTW slices (PRs #553, #554, #556) and the two open decisions (which slice next; `align` vs `alignSegments` for Craft). Refreshed monthly summary #522 — removed merged PR #548 and merged case_conversion PR #551, removed closed #549, added new automation items #552 (Test Improver) and #555 (Repo Assist safe_outputs).
- Run before that (2026-08-15, run id 31886709595): branch `repo-assist/improve-language-tag-split-helper-2026-08-15` carries commits `0523be6` + `2fcdaf8` (language-tag separator dedup + tests). The 2026-08-14 run2 carry-over was finally shipped by switching from a top-level public constant to a file-private helper so the post-commit lint pass has no public API to revert. No PR created this run; branch only.
- Run before that (2026-08-14 run2, run id 31807339220): created draft PR `repo-assist/perf-case-conversion-ascii-2026-08-14` (commit `5492cab`, merged by an-lee as PR #551 on 2026-08-15).
- Run before that (2026-08-14, run id 31765982034): created draft PR `repo-assist/test-asr-generation-job-model-2026-08-14` (commit `58f92730`, merged via PR #550) adding direct unit tests for `AsrGenerationJob`.
- Run before that (2026-08-13 run2, run id 31708273065): created draft PR #548 (merged by an-lee as PR #548 on 2026-08-14) swapping the last two `NetworkImage(...)` profile avatars for `CachedNetworkImageProvider`.
- Issues commented on: #309, #310, #355, #383, #474, #501, #527, **#540** (2026-08-16).
- PRs merged by an-lee: #486, #496, #498, #499, #500, #503, #504, #516, #521 (2026-08-04), #537 (2026-08-08), #539 (2026-08-08), #545 (2026-08-12), #548 (2026-08-14), #550 (2026-08-14), #551 (2026-08-15).
- Open Repo Assist PRs: 1 — draft `repo-assist/dedupe-import-progress-dialog-2026-08-20` (import progress dialog dedup, pure refactor).

## Pending actions for maintainer
- Review the new draft PR `repo-assist/dedupe-import-progress-dialog-2026-08-20` (pure refactor: file-private `_showImportProgressDialog` helper, no behavior change).
- Optionally pick up branch `repo-assist/improve-language-tag-split-helper-2026-08-15` as a stand-alone PR (helper + tests, no public API changes, behavior-preserving).
- Check Repo Assist comments on #309, #310, #527, **#540**.
- Triage #540 (DTW Phase 3 design questions — Settings + Craft DTW wiring vs. IPA overlay next; `align` vs `alignSegments` for Craft). Top 3 priorities from an-lee's 2026-08-17 review: (a) vendor eSpeak binaries for non-Windows platforms, (b) resolve inert `transcript.timelineEnrichment` setting, (c) deprecate `TtsResult.wordBoundaries` ADR. #547 (Duplicate Code Detector auto-failure, self-managing), #552 (Test Improver auto-failure, self-managing), #555 (Repo Assist safe_outputs failure, self-managing).
- Decide whether to manually recreate ADR-0070 after workflow issue #535.
- Re-apply orphan `toggleWordLoop` deletion if desired (PR was closed without merge on 2026-08-18).

## Known environment limitations
- Agentic runner Flutter SDK read-only → `dart format` / `analyze` / `test` may fail on cache writes (invariant #501 / #503). The formatter itself runs cleanly; only the wrapper exit code is non-zero on read-only SDK cache.
- No git credentials for network operations; use safeoutputs for PRs.
- Linter pass may revert working-tree changes after a safe-outputs PR creates — cosmetic, NOT blocking merges (verified via #499, #500, #503, #550, #551).
- Workaround for lint-pass revert: prefer file-private helpers over top-level public constants when extracting dedup candidates.
- `safeoutputs create_pull_request` requires JSON via a file, not a heredoc, on this sandbox (recovered this run by piping from `/tmp/gh-aw/agent/pr_payload.json`).

## Carry-over queues
- Perf: `_VirtualItems` rebuild memoization (transcript_scrollable_list already memoizes); per-line post-frame translate requests in any scrollable list.
- Architectural dedupe (#17, #39, #40).
- `settings_screen.dart` below ~120 LOC requires per-section sliver extraction (already 105 LOC with `_EditorialHeaderSlot`).
- `app_language_catalog.dart` `RegExp(r'[-_]')` dedup — **shipped** on branch `repo-assist/improve-language-tag-split-helper-2026-08-15` (no PR yet).
- Issue #527 follow-up (Phase 1): `TranscriptWord.ipa?: String` + Worker KV `(locale, word) → ipa` cache + LLM batched endpoint + renderer word-segmenting span builder + Settings toggle; gated on ADR-0070 maintainer decisions.
- Issue #549 (large-file-simplifier proposal) auto-closed 2026-08-16 without maintainer action; the proposal text is still on file in the issue body if the maintainer wants the focused `assessment_result_dialog.dart` split anyway.
- Issue #540 dead-code trio (items 9-11): confirm `wordPracticeSettingsProvider` consumers, decide `timelineEnrichmentSettingsProvider` future, per-phone inspection UI for the persisted `TranscriptPhone.startTime/endTime`. The 2026-08-18 `toggleWordLoop` draft PR addressed item 8 but was closed without merge.