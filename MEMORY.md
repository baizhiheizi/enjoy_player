# Repo Assist — Enjoy Player

## Backlog progress
- Latest run (2026-08-13, run id 31663168346): no-action run; refreshed monthly summary #522 with the new #547 (Duplicate Code Detector auto-failure) entry.
- Run before that (2026-08-12, run id 31604747330): opened test-only draft branch `repo-assist/test-youtube-id-and-negative-duration-2026-08-12` (`0cc213a`); Flutter gate blocked by read-only SDK cache.
- Run before that (2026-08-11 late, run id 31499461058): local commit `0b34271` adds negative duration-component coverage; no PR opened.
- Earlier 2026-08-08 (run2, run id 31259673871): no-action run; confirmed PR #537 + #539 merged; refreshed monthly summary #522.
- Issues commented on: #309, #310, #355, #383, #474, #501, **#527** (2026-08-05 run2).
- PRs merged by an-lee: #486, #496, #498, #499, #500, #503, #504, #516, #521 (2026-08-04), #537 (2026-08-08), #539 (2026-08-08), #545 (2026-08-12).

## Pending actions for maintainer
- Review prior draft branches listed above if recreated as PRs.
- Check Repo Assist comments on #309, #310, #527.
- Triage #540 (DTW Phase 3 design questions) and #547 (Duplicate Code Detector auto-failure).
- Decide whether to manually recreate ADR-0070 after workflow issue #535.

## Known environment limitations
- Agentic runner Flutter SDK read-only → `dart format` / `analyze` / `test` may fail on cache writes (invariant #501 / #503).
- No git credentials for network operations.
- Linter pass may revert working-tree changes after a safe-outputs PR creates — cosmetic, NOT blocking merges (verified via #499, #500, #503).

## Carry-over queues
- Perf: `_VirtualItems` rebuild memoization (transcript_scrollable_list already memoizes); `TransportScrollableList` per-line post-frame translate requests.
- Testing: `asr_generation_job.dart` model has no direct test (covered indirectly by controller tests); reassess next run.
- Architectural dedupe (#17, #39, #40).
- `settings_screen.dart` below ~120 LOC requires per-section sliver extraction (already 105 LOC with `_EditorialHeaderSlot`).
- Issue #527 follow-up (Phase 1): `TranscriptWord.ipa?: String` + Worker KV `(locale, word) → ipa` cache + LLM batched endpoint + renderer word-segmenting span builder + Settings toggle; gated on ADR-0070 maintainer decisions.