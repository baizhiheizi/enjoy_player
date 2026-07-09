# Contract: Auto-Translate Scheduler & Translation Calls

**Feature**: [spec.md](../spec.md) · **Plan**: [plan.md](../plan.md) · **Data model**: [data-model.md](../data-model.md)

Application-level contract for `AutoTranslateCtrl` (name may vary) and its use
of the existing translation capability. No new public HTTP surface is added;
this documents the **client orchestration** contract tests must pin.

## Translation capability (existing)

Each line uses the existing service façade:

```text
translationService.translate(
  text: <primary line plain text>,
  sourceLanguage: <primary track language>,
  targetLanguage: <effective native language>,
  forceRefresh: <true only on explicit Re-translate line pass when needed>,
)
```

- Wire path remains Enjoy `POST /translations` or BYOK translation capability
  per modality routing (ADR-0014, ADR-0033).
- Languages sent to Enjoy worker MUST use base codes via `workerLanguageBase`.
- Markup: strip subtitle markup to plain text before translate; store plain
  translated text in the AI timeline (v1).

## Scheduling rules

| Rule | Requirement |
|------|-------------|
| S1 | Prefer lines whose index is closest to the current playback cue index |
| S2 | On seek/scrub, re-order the pending queue; do not re-translate ready lines |
| S3 | Max **2** concurrent in-flight translate calls per media job |
| S4 | Per-line retries: max **3** attempts with exponential backoff (≥1s base) |
| S5 | Transient failures retry; `AuthFailure` / `CreditsFailure` stop **new**
  scheduling and set job `blocked`/`failed` with friendly reason |
| S6 | Successful line → write text into AI `timelineJson` at that index → upsert |
| S7 | Empty text = pending; non-empty = ready (UI) |
| S8 | Selecting away from Auto translate pauses the job; selecting back resumes |
| S9 | Re-translate bumps `generation`; completions from older generation are ignored |
| S10 | Stale primary (`referenceId` / fingerprint mismatch) must not present old
  AI text as valid without rebuild or Re-translate |

## Progressive persistence

1. Ensure AI row + full timing skeleton before first display as secondary.
2. Upsert after each success (or coalesced micro-batch ≤ N lines) so process
   death loses at most the in-flight set.
3. Reopen: load AI timeline; schedule only empty (and optionally failed) indexes.

## Observability

- Log via `logNamed` (job start, block reasons, retry exhaustion) — never `print`.
- Do not surface raw exception strings as primary UI copy (`guardAiCall` /
  friendly mapping).

## Test doubles

Unit tests MUST inject a fake `TranslationCapability` / `TranslationService`
that can:

- delay, fail transiently, fail permanently, or succeed per line index;
- assert call ordering prioritizes the anchor index;
- assert concurrency never exceeds 2.
