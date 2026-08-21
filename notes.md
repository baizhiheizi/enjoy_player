# Repo Assist — Enjoy Player

## Backlog progress
- Latest run (2026-08-21, run id 32438930318): created draft PR `repo-assist/dedupe-language-tag-separator-2026-08-21` (commit `48f9f1d0`) folding five duplicated `RegExp(r'[-_]')` literals in `lib/core/application/app_language_catalog.dart` into one file-private `_kLanguageTagSeparator` + `_splitLanguageTag` helper. Added direct unit tests for five previously-untested public helpers that share the split semantics (`primaryLanguageSubtag`, `normalizeBcp47Tag`, `tagsEqual`, `displayLocaleFromRawOrDefault`, `coerceNativeIfEqualsLearning`). Net +118 / −5 across two files. File-private on purpose — a 2026-08-14 attempt with a top-level public constant was reverted by the post-commit lint pass. Refreshed monthly summary #522.
- Also this run: reverted working-tree `pubspec.lock` drift (7 transitive packages downgraded by an unrelated `flutter pub get` against an older cached SDK) via plain `git checkout -- pubspec.lock`; no PR. Did not revert `tool/untranslated_messages.json` (real AI-providers settings content, not drift).
- Run before that (2026-08-20, run id 32323340730): extracted the blocking 'importing' progress dialog that was duplicated verbatim across `importMediaFromPicker` (file flow) and `importYoutubeFromDialog` (YouTube flow) in `lib/features/library/presentation/library_actions.dart` into a single file-private `_showImportProgressDialog(context, label)` helper. Branch `repo-assist/dedupe-import-progress-dialog-2026-08-20`, commit `924662e5`. Merged via PR #584 on 2026-08-20.
- Run before that (2026-08-18, run id 32090446771): created draft PR `repo-assist/improve-remove-orphan-toggle-word-loop-2026-08-18` (commit `14c0e842`, closed without merge on 2026-08-18) deleting the orphan `PlayerInteractions.toggleWordLoop` method (zero callers).
- Run before that (2026-08-16, run id 31921209621): shipped `test/data/files/media_resolver_test.dart` (107 LOC, no production changes) on branch `repo-assist/test-media-resolver-helpers-2026-08-16` and pushed it as a draft PR. Merged via PR #557 + #564.
- Run before that (2026-08-15, run id 31886709595): branch `repo-assist/improve-language-tag-split-helper-2026-08-15` carries commits `0523be6` + `2fcdaf8` (language-tag separator dedup + tests); never made it to a PR — the 2026-08-21 run re-attempted this on a fresh branch and successfully created the PR.
- Issues commented on: #309, #310, #355, #383, #474, #501, #527, #540 (2026-08-16).
- PRs merged by an-lee: #486, #496, #498, #499, #500, #503, #504, #516, #521 (2026-08-04), #537 (2026-08-08), #539 (2026-08-08), #545 (2026-08-12), #548 (2026-08-14), #550 (2026-08-14), #551 (2026-08-15), #557+#564 (2026-08-16/#17), **#584** (2026-08-20).
- Open Repo Assist PRs: 2 — `repo-assist/dedupe-import-progress-dialog-2026-08-20` (already merged as #584, branch can be deleted) and the new `repo-assist/dedupe-language-tag-separator-2026-08-21`.

## Pending actions for maintainer
- Review the new draft PR `repo-assist/dedupe-language-tag-separator-2026-08-21` (pure refactor: file-private `_kLanguageTagSeparator` + `_splitLanguageTag` helper, no behavior change; five new test groups for previously-untested public helpers).
- Check Repo Assist comments on #309, #310, #527, #540.
- Triage #540 (DTW Phase 3 design questions — Settings + Craft DTW wiring vs. IPA overlay next; `align` vs `alignSegments` for Craft). Top 3 priorities from an-lee's 2026-08-17 review: (a) vendor eSpeak binaries for non-Windows platforms, (b) resolve inert `transcript.timelineEnrichment` setting, (c) deprecate `TtsResult.wordBoundaries` ADR. #547 (Duplicate Code Detector auto-failure, self-managing), #552 (Test Improver auto-failure, self-managing), #555 (Repo Assist safe_outputs failure, self-managing).
- Decide whether to manually recreate ADR-0070 after workflow issue #535.
- Re-apply orphan `toggleWordLoop` deletion if desired (PR was closed without merge on 2026-08-18).
- Issue #585 (large-file-simplifier proposal for `assessment_result_dialog.dart`, expires 2026-08-22): the proposal's first slice is mechanical and behavior-preserving, but the prior proposal (#549) closed without merge — will wait for maintainer signal before starting.

## Known environment limitations
- Agentic runner Flutter SDK read-only → `dart format` / `analyze` / `test` may fail on cache writes (invariant #501 / #503). The formatter itself runs cleanly; only the wrapper exit code is non-zero on read-only SDK cache.
- No git credentials for network operations; use safeoutputs for PRs.
- Linter pass may revert working-tree changes after a safe-outputs PR creates — cosmetic, NOT blocking merges (verified via #499, #500, #503, #550, #551). The 2026-08-14 run2 lang-tag-separator refactor was reverted externally before the PR could be created; not a blocker.
- Workaround for lint-pass revert: prefer file-private helpers over top-level public constants when extracting dedup candidates. Confirmed works in 2026-08-21 run.
- `safeoutputs create_pull_request` requires JSON via a file, not a heredoc, on this sandbox (recovered by piping from `/tmp/gh-aw/agent/pr_payload.json`).

## Carry-over queues
- Perf: `_VirtualItems` rebuild memoization (transcript_scrollable_list already memoizes); per-line post-frame translate requests in any scrollable list.
- Architectural dedupe (#17, #39, #40).
- `settings_screen.dart` below ~120 LOC requires per-section sliver extraction (already 105 LOC with `_EditorialHeaderSlot`).
- Issue #527 follow-up (Phase 1): `TranscriptWord.ipa?: String` + Worker KV `(locale, word) → ipa` cache + LLM batched endpoint + renderer word-segmenting span builder + Settings toggle; gated on ADR-0070 maintainer decisions.
- Issue #549 (large-file-simplifier proposal) auto-closed 2026-08-16 without maintainer action; superseded by #585 (fresh proposal with same target file `assessment_result_dialog.dart`).
- Issue #540 dead-code trio (items 9-11): confirm `wordPracticeSettingsProvider` consumers, decide `timelineEnrichmentSettingsProvider` future, per-phone inspection UI for the persisted `TranscriptPhone.startTime/endTime`.
- Issue #585 large-file-simplifier proposal (expires 2026-08-22): first slice = `assessment_result_widgets.dart` (~310 LOC, includes `_OverallScoreRing`, `_ScoreBar`, `_WordChip`, `_SelectedWordPanel`, `_wordColors`) + `assessment_error_messages.dart` (~30 LOC). Gated on maintainer signal given the prior proposal (#549) closed without merge.