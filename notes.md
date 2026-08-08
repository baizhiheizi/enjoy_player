# Repo Assist — Enjoy Player

## Backlog progress
- Latest run (2026-08-08 run2, run id 31259673871): no-action run; confirmed PR #537 + #539 merged; refreshed monthly summary #522.
- Run before that (2026-08-08, run id 31235204537): shared whitespace normalization refactor on `repo-assist/improve-text-normalization` (`#aw_txtnorm1`, commit `159c5c3`, now PR #539 — merged).
- Issues commented on: #309, #310, #355, #383, #474, #501, **#527** (2026-08-05 run2).
- PRs merged by an-lee: #486, #496, #498, #499, #500, #503, #504, #516, **#521** (2026-08-04), **#537** (2026-08-08), **#539** (2026-08-08).
- Draft branches awaiting maintainer review (if recreated as PRs):
  - `repo-assist/payurl-typed-exception-2026-08-04`
  - `repo-assist/coding-and-tests-improvements-2026-08-02`
  - `repo-assist/perf-image-network-cache-2026-08-05`
  - `repo-assist/ipa-phase2-word-timings-2026-08-05` (Phase 2 of #527).

## Pending actions for maintainer
- Review prior draft branches listed above if recreated as PRs.
- Check Repo Assist comments on #309, #310, #527.
- Decide whether to manually recreate ADR-0070 after workflow issue #535.

## Known environment limitations
- Agentic runner Flutter SDK read-only → `dart format` / `analyze` / `test` may fail on cache writes (invariant #501 / #503).
- No git credentials for network operations.
- Linter pass may revert working-tree changes after a safe-outputs PR creates — cosmetic, NOT blocking merges (verified via #499, #500, #503).

## Carry-over queues
- Perf: `_VirtualItems` rebuild memoization (transcript_scrollable_list already memoizes); `TransportScrollableList` per-line post-frame translate requests.
- Testing: `asr_generation_job.dart` model has no direct test (covered indirectly by controller tests); reassess next run.
- Architectural dedupe (#17, #39, #40).
- `settings_screen.dart` below ~120 LOC requires per-section sliver extraction.
- Issue #527 follow-up (Phase 1): `TranscriptWord.ipa?: String` + Worker KV `(locale, word) → ipa` cache + LLM batched endpoint + renderer word-segmenting span builder + Settings toggle; gated on ADR-0070 maintainer decisions.