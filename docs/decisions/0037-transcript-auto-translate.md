# ADR-0037: Transcript auto-translate (AI secondary track)

## Status

Accepted (orchestration superseded by [ADR-0038](0038-viewport-per-line-auto-translate.md); AI display/identity supplemented by [ADR-0039](0039-auto-translate-primary-text-keyed-overlay.md)).

Superseded by [ADR-0038](0038-viewport-per-line-auto-translate.md) for orchestration (viewport per-line requests). Persistence and picker shape below still apply unless ADR-0038 says otherwise. ADR-0039 changes how AI secondary text is **resolved in the UI** (index + `sourceKey` instead of `TranscriptSecondaryMatcher`).

## Context

Learners can pick primary and optional translation subtitle tracks, but many
media items lack a translation caption file. The product already exposes single-line
`POST /translations` via the AI capability layer (ADR-0014) and stores transcripts
in Drift with `source: ai` reserved but unused. YouTube bilingual fetch
(ADR-0036) can populate a native caption as secondary, yet learners still need
generated translation from the **current primary text** when no suitable track
exists—or when they prefer AI translation.

Requirements:

- Selectable **Auto translate** in the translation picker list
- Lazy, playback-priority scheduling with graceful retries
- Progressive display without blocking playback
- Persist/resume and **Re-translate**
- Coexist with existing translation tracks and YouTube bilingual captions

## Decision

1. **Persistence**: Auto-translated output is stored as a durable `Transcripts`
   row with `source: 'ai'`, deterministic id via `enjoyTranscriptId(..., language, 'ai')`,
   and `referenceId` pointing at the primary transcript id used as source.
   `echo_sessions.secondaryTranscriptId` references this row when Auto translate
   is selected. **No schema migration** in v1.

2. **Timeline shape**: On start/resume, ensure a **skeleton** timeline mirroring
   primary cue count and timings; `text` is empty until each line succeeds. This
   keeps `TranscriptSecondaryMatcher` alignment correct without a parallel render
   path.

3. **Orchestration**: `AutoTranslateCtrl` (Riverpod, per `mediaId`) reads
   `effectiveNativeLanguage` in the application layer (not the repository), calls
   `translationServiceProvider` line-by-line, caps concurrency at **2**, retries
   failed lines up to **3** with exponential backoff, and re-prioritizes by
   `transcriptPlaybackHighlightProvider` on seek.

4. **Picker UX**: Translation list order is **None → Auto translate → other tracks**;
   `source: ai` rows are hidden from the generic list to avoid duplicate selectors.
   **Per-line re-translate** is an inline refresh control on each translated cue
   (not a whole-track action).

5. **Staleness**: If primary id or primary timings/count change, rebuild or block
   with Re-translate—never show mismatched bilingual pairs silently.

6. **Coexistence**: YouTube bilingual secondary tracks remain selectable; Auto
   translate is an additional option, not a replacement.

## Consequences

**Positive**

- Reuses existing secondary rendering, matcher, and translation capability
- Resume/reopen avoids re-translating finished lines (credit savings)
- Feature-first boundary preserved (`transcript` application + data helpers)

**Trade-offs**

- Single-line API implies many requests for long transcripts; mitigated by lazy
  priority and concurrency cap
- Job-level state is mostly in-memory in v1; process death leaves empty lines
  pending but persisted skeleton/ready lines survive
- No per-job target language picker in v1 (native language default)

**Follow-up**

- Optional Drift job table if durable job errors/progress across process death
  become necessary
- Batch translate API if the worker adds one
