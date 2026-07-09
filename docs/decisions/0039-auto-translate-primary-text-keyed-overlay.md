# ADR-0039 — Auto-translate as primary-text keyed overlay

**Status**: Accepted  
**Date**: 2026-07-09

**Supplements**: [ADR-0037](0037-transcript-auto-translate.md) persistence, [ADR-0038](0038-viewport-per-line-auto-translate.md) orchestration.

**Partial supersession**: ADR-0037 decision (2) that AI timelines exist so `TranscriptSecondaryMatcher` stays correct. For AI tracks, display no longer uses the time matcher.

## Context

Auto translate wrote translations by primary **array index** but rendered them through `TranscriptSecondaryMatcher` (time midpoint / fallback), the same path as YouTube and imported caption tracks. That split could attach a neighbor cue when timings were tight or briefly out of sync. Staleness also ignored primary **text** changes that kept the same timings, so an edited cue could keep an old translation.

Auto translate is not an independent caption track: each string is `f(primaryPlainText, srcLang, tgtLang)`.

## Decision

1. **Index overlay for AI display** — When the active secondary is the AI auto-translate track, resolve secondary text as `aiLines[i]` for primary line `i`. Do **not** call `TranscriptSecondaryMatcher` for AI. Keep the matcher for real translation caption tracks.

2. **Content key (`sourceKey`)** — On each successful translate, store a truncated SHA-256 of `normalize(plain(primary.text)) | workerLang(src) | workerLang(tgt)` on the AI cue JSON (`sourceKey` in `timelineJson`; no Drift schema migration). Display and cache hits require the stored key to match the current primary line + language pair. Mismatch is **soft stale**: treat the slot as empty and re-request without wiping the whole track.

3. **Same-key reuse** — Before calling the API, copy a non-empty AI cue that already has the same `sourceKey` into the requested index (credit savings for repeated lines).

4. **Hard staleness unchanged** — `referenceId` + cue count/timings still rebuild the skeleton when the primary track identity or timing skeleton changes.

## Consequences

**Positive**

- AI translations cannot attach to the wrong primary line via time fallback
- Primary text edits invalidate that line without a full-track rebuild
- Identical cues share one translation within the media AI track

**Trade-offs**

- Legacy AI cues without `sourceKey` look empty until re-translated once
- Cross-media global translation cache remains a future option
