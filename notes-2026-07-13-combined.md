---
name: run-2026-07-13-combined
description: Combined notes from Repo Assist runs 2026-07-13 (29223679540) + 2026-07-13-run2 (29262626511)
metadata:
  type: project
---

# 2026-07-13 — Two Repo Assist runs

## Run 1 (29223679540) — selected 5, 3, 2 + 11
- **Task 5** Branch `repo-assist/improve-api-client-bearer-helper-2026-07-13` (commit `dfdfc7e`). Extracted duplicated bearer-token resolution shared between `ApiClient._dispatch()` and `ApiClient.postMultipartJson()` into a single `_resolveBearerToken({requireAuth})` helper. Net −10 LOC. Added `test/data/api/api_client_test.dart` with **7 MockClient tests**. PR-fallback patch: `/tmp/gh-aw/aw-repo-assist-api-client-bearer-helper-2026-07-13.patch` (11,445 bytes).
- **Task 3** Fell back to Task 2 (no fixable `bug`/`help wanted`/`good first issue`).
- **Task 2** Posted `#aw_3GlnFO3Q` on **#310** (Stream AI responses incrementally). Verified S1–S7 citations on `main` (`8b151ea`). Proposed per-endpoint phasing (parser foundation → one capability first, suggested contextual translation). Flagged `_staleSuccess` + StreamProvider interaction risk in `contextual_translation_lookup_section.dart:94, 257-273`. Offered parser as separate PR.
- **Task 11** Posted `#aw_nl48O9eb` on #165 (comment-only; body at 10 KB ceiling).
- **Verification**: `check_dart_format.sh` ok; `flutter analyze` 0 issues; `flutter test test/data/api/` 54/54; `flutter test` 1297/1298 (1 pre-existing flake in `test/features/settings/application/settings_section_collapse_provider_test.dart` verified by stashing).

## Run 2 (29262626511) — selected 2, 4, 10 + 11
- **Task 2** Posted `#aw_utSp5wsV` on **#309** (word-recall feedback). Verified R1–R4 against `main` (`b65450f`):
  - R1 `recording_assessment_controller.dart:111-115` + `stub_ai_capabilities.dart:164-173` (ADR-0014 §5) → `UnimplementedError` for `AIProvider.local`.
  - R2 `azure_assessment_runner.dart:184-225` consumes `AzureWordAssessment.pronunciationAssessment.errorType` (`:212`) and `displayText` (`:193`, `:221`); controller at `:143-164` flattens to `pronScore` and JSON blob.
  - R3 `lib/data/db/tables/recordings.dart` 17 columns; `recordingDao.updateAssessment` (`app_database.dart:636-648`) writes only `pronunciationScore` + `assessmentJson`.
  - R4 `grep -rnE "(Levenshtein|Jaccard|editDistance|lemmat)" lib/` returns 0 hits.
  - Surfaced ASR wiring reuse: `AsrRequest` already takes `audioBytes + filename + language` — file bytes + `asrServiceProvider.transcribe(req)` reuses existing worker-Whisper / BYOK / `UnimplementedAsrCapability` symmetry. Proposed 5-step phasing (schema bump → pure-Dart scorer → Layer 1 surface Azure `Words[]` → Layer 2 offline path → Speech-framework follow-up). Two design nudges: (a) ja/ko/zh tokenizers can't be whitespace-based; (b) reuse `azure_assessment_runner.dart:191-193` `displayLooksEmpty` for typed `WordRecallStatus.noSpeech`.
- **Task 4** Filed issue flagging **Codegen drift CI failure** blocking every push. Root cause: commit `10f20e4` added `registerOn401RefreshCallback(...)` + `ref.onDispose(clearOn401RefreshCallback)` to `auth_repository.dart:38-49`, mutating the provider's hashable surface, but `.g.dart` wasn't regenerated. One-line maintainer fix: `bash .github/scripts/check_codegen_drift.sh --fix`. (Resolved 2026-07-14 by `0e50999`.)
- **Task 10** Identified `resolvePracticePosterHeroText` in `lib/features/share_poster/domain/practice_poster_data.dart` as pure dead code. Branch `repo-assist/remove-dead-practice-poster-hero-text-2026-07-13` (commit `efca21f`). 12-line deletion. PR-fallback: `/tmp/gh-aw/aw-repo-assist-remove-dead-practice-poster-hero-text-2026-07-13.patch`. **Merged** as PR #334 (commit `8569a99 chore(share_poster): remove unused resolvePracticePosterHeroText (#334)`).
- **Task 11** Posted `#aw_XWe9QSxY` on #165 (comment-only; body still at 10 KB ceiling).

## Backlog cursor
- `comments_made` (cumulative): `#aw_3GlnFO3Q` on #310; `#aw_nl48O9eb` on #165; `#aw_utSp5wsV` on #309; `#aw_XWe9QSxY` on #165.
- `prs_attempted` (cumulative): `repo-assist/improve-api-client-bearer-helper-2026-07-13` commit `dfdfc7e` (PR-fallback); `repo-assist/remove-dead-practice-poster-hero-text-2026-07-13` commit `efca21f` (PR-fallback, **merged as #334**).
- `monthly_summary`: #165 received comment-only updates both runs (body at 10 KB ceiling).
- `codegen_drift_issue`: filed, then closed 2026-07-14 by `0e50999`.

## Why (one-liners)
- **Run 1, T5**: ApiClient had two near-identical bearer blocks; consolidated; streaming-parser work in #310 builds on it without re-touching auth.
- **Run 1, T2**: #310 is a detailed maintainer proposal; verified citations, proposed smallest-first phasing + `_staleSuccess` cancellation edge case.
- **Run 2, T2**: #309 is a fresh, well-scoped maintainer proposal; verified R1–R4 and offered 5-step phasing with two design nudges.
- **Run 2, T4**: Codegen drift blocks every PR touching `lib/`, `pubspec.yaml`, or `pubspec.lock`. One bash command to fix. Filed the issue vs opening the PR to let the maintainer choose.
- **Run 2, T10**: Lowest-risk, highest-signal cleanup. `@deprecated` + zero callers + 12-line deletion. Same pattern as #62.

## Related
- [[historical-rollup-through-2026-07-09]]
- [[run-2026-07-14]]
