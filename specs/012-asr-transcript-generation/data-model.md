# Data Model — ASR Transcript Generation

**Branch**: `012-asr-transcript-generation` | **Date**: 2026-07-10

This document captures the entities introduced or reused by the ASR
transcript generation feature. It is the authoritative source for the
schema-level decisions in `plan.md` and `contracts/`.

---

## 1. Existing entities (reused, no schema change)

### 1.1 `TranscriptRow` (Drift, `data/db/tables/transcripts.dart`)

The Drift table already supports `source = 'ai'` with deterministic id
generation. No migration is required for the feature.

| Column | Role for ASR |
|---|---|
| `id` | `enjoyTranscriptId(targetType, targetId, language, source: 'ai')` — deterministic, so re-generation upserts in place (FR-010, SC-004). |
| `targetType` | `'Video'` for video items, `'Audio'` for audio-only items (matches `dexieTargetTypeForId` outputs). |
| `targetId` | `mediaId` from the open media. |
| `language` | BCP47 tag — either user-selected (`request.language`) or auto-detected (`AsrResult.language`). |
| `source` | `'ai'` (matches existing `official | auto | ai | user`). |
| `timelineJson` | `jsonEncode(lines.map((l) => l.toJson()).toList())` — `TranscriptLine[]` with `text`, `startMs`, `durationMs`. |
| `label` | `'Generated ($language)'` when no specific label is provided; for re-generation we preserve the prior label so the user keeps a familiar name. |
| `trackIndex` | `null` — ASR is not bound to a media_kit subtitle stream. |
| `referenceId` | `null` for ASR (no upstream subtitle file to reference). |
| `syncStatus` | `'local'` — ASR is local-first; no cloud sync in this change. |
| `serverUpdatedAt` | `null` for the same reason. |
| `createdAt` / `updatedAt` | Now; on re-generation `updatedAt` advances and `createdAt` is preserved. |

The DAO `TranscriptDao.upsert` already handles deterministic-id
replacement; no DAO change is needed.

### 1.2 `TranscriptLine` (`data/subtitle/transcript_line.dart`)

```dart
final class TranscriptLine {
  final String text;
  final int startMs;
  final int durationMs;
  final String? sourceKey;
}
```

ASR produces lines in the same shape as imported `.srt` / `.vtt`
transcripts (FR-007). The new `AsrTimelineBuilder` is the only producer
on the `ai` source path; every downstream consumer (highlight, lookup,
echo, blur, auto-translate) is already wired to `TranscriptLine`.

### 1.3 `AsrRequest` / `AsrResult` / `AsrSegment` / `AsrWord`
(`lib/features/ai/domain/models/`)

Already implemented. No schema change. The new flow converts these into
`TranscriptLine[]` via `AsrTimelineBuilder` (see §3.2).

### 1.4 `TranscriptFetchStates` (Drift, `transcript_fetch_states.dart`)

Persisted cloud-fetch state. **Not** used by ASR — generation is local and
its success/failure is observable from the resulting row + UI feedback.

---

## 2. New entities

### 2.1 `AsrGenerationJob` (in-memory, application layer)

Lives only in `AsrGenerationController`. Not persisted.

```dart
final class AsrGenerationJob {
  final String mediaId;            // media row id
  final String language;            // BCP47 chosen (or media's stored lang)
  final String? detectedLanguage;   // populated after recognition
  final AsrGenerationPhase phase;   // extracting | recognizing | persisting | success | error
  final double? progress;           // 0..1, best-effort
  final String? errorMessage;       // friendly, localized
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? trackId;            // resulting enjoyTranscriptId (after persist)
}

enum AsrGenerationPhase {
  idle,
  extracting,    // ffmpeg audio extraction (video only)
  recognizing,   // AsrService.transcribe
  persisting,    // upsert TranscriptRow
  success,
  error,
  cancelled,
}
```

**Validation rules**:
- `mediaId` must resolve to a non-null `dexieTargetTypeForId` (else
  controller refuses to start with `errorMessage = 'No media'`).
- `language` must be a non-empty BCP47 tag (else friendly error).
- `progress` is best-effort (FFmpeg duration parser provides a coarse
  estimate for video extraction; ASR streaming is opaque on most
  providers, so 0..1 maps to phase in the absence of real numbers).
- One in-flight job per `mediaId`; starting a new one cancels the prior
  `Future` cleanly (FR-015). The controller keeps a
  `Map<String, AsrGenerationJob>` and replaces on restart.

### 2.2 `AsrGeneratedTrackInput` (repository input)

```dart
final class AsrGeneratedTrackInput {
  final String mediaId;
  final String language;
  final List<TranscriptLine> lines;
  final String? label;             // preserved across re-generation
  final bool activateAsPrimary;    // FR-021
}
```

The repository helper `TranscriptRepository.upsertAsrGeneratedTrack`
takes this input, builds the deterministic row id, persists, and (when
`activateAsPrimary == true`) calls `ensurePrimaryTranscript` so the
active session points to the new track.

### 2.3 `AsrTimelineBuilder` (pure function, in `domain/`)

Pure-Dart function that turns an `AsrResult` into `List<TranscriptLine>`:

```dart
List<TranscriptLine> buildAsrTranscriptLines({
  required AsrResult result,
  required int mediaDurationMs, // for plain-text fallback
  int minLineDurationMs = 800,
  int maxLineDurationMs = 6000,
  int maxLineChars = 140,
});
```

Behaviour (mirrors the webapp's `transcript-segmentation` pipeline):

1. **Word-level path**: when `AsrResult.segments[i].words` is non-empty
   with timings, group consecutive words until any of `maxLineDurationMs`
   / `maxLineChars` / a sentence terminator (`.|?|!|。|？|！`) / a long
   pause (`> 350 ms` between words) is reached. Each group becomes a
   `TranscriptLine` with `startMs = words.first.startMs * 1000` and
   `durationMs = words.last.endMs * 1000 - words.first.startMs * 1000`.
2. **Segment-level path**: when no words, fall back to
   `AsrSegment.start/end`. Coalesce adjacent short segments until
   `minLineDurationMs` / sentence terminator / `maxLineDurationMs`.
3. **Plain-text fallback**: when neither timings nor segments are
   available, distribute the full text evenly across `mediaDurationMs`
   with one line per sentence terminator or `maxLineChars`.
4. **Empty input**: return `[]`; the controller surfaces a friendly
   "no speech detected" message and does **not** persist a row.

The builder is intentionally deterministic so unit tests can pin its
output and so re-generation of the same input produces an identical row.

### 2.4 Media row language update

When `AsrResult.language` is non-null and differs from the media row's
stored language (FR-012 / US6), the controller (or a small repository
helper) calls:

- `db.videoDao.updateLanguage(mediaId, language)` for video items.
- `db.audioDao.updateLanguage(mediaId, language)` for audio items.

(If those DAOs do not already expose `updateLanguage`, the change adds
the method; this is the only schema-adjacent drift in this feature and
stays inside the existing `media_*` table contract.)

---

## 3. State transitions

### 3.1 Controller state machine

```
       start(mayPreconfirm)
              │
              ▼
            idle ───────────────► error ──► (terminal; user retries)
              │                      ▲
              ▼                      │
        extracting (video only) ─────┤
              │                      │
              ▼                      │
        recognizing ────────────────┤
              │                      │
              ▼                      │
        persisting                   │
              │                      │
              ▼                      │
           success ──► (terminal; row written; primary updated)
              ▲
              │ (cancel + restart cancels prior in-flight future)
           cancelled (only if user explicitly cancels; on restart, prior
                     job's future completes with cancelled and is ignored)
```

### 3.2 Upsert semantics (repository)

```
upsertAsrGeneratedTrack(input):
  tt = dexieTargetTypeForId(input.mediaId)        // null → no-op + error
  id = enjoyTranscriptId(tt, input.mediaId,
                         input.language, source: 'ai')
  existing = transcriptDao.getById(id)
  label = existing?.label ?? input.label ?? 'Generated (${input.language})'
  rows = jsonEncode(input.lines.map((l) => l.toJson()).toList())
  transcriptDao.upsert(TranscriptRow(id, tt, input.mediaId,
                                     input.language, 'ai', rows,
                                     referenceId: null,
                                     label: label,
                                     trackIndex: null,
                                     syncStatus: 'local',
                                     serverUpdatedAt: null,
                                     createdAt: existing?.createdAt ?? now,
                                     updatedAt: now))
  if (input.activateAsPrimary) ensurePrimaryTranscript(input.mediaId)
  return id
```

The deterministic id guarantees that calling `upsertAsrGeneratedTrack`
twice for the same `(mediaId, language)` produces exactly one row
(SC-004). Drift's `upsert` either inserts or replaces; either way the
row count is unchanged.

---

## 4. Storage summary

| Store | New? | Purpose |
|---|---|---|
| `transcripts` (Drift) | no | persists the resulting `source: ai` row (FR-007 / SC-004). |
| `media_videos` / `media_audios` (Drift) | no | language field updated when ASR auto-detects a different language (FR-012). |
| `transcript_fetch_states` (Drift) | no | **not** used by ASR. |
| In-memory `AsrGenerationJob` | yes (transient) | UI status, in-flight guard, cancel. |
| Temp audio file on disk | yes (transient) | FFmpeg extract / Azure SDK input; deleted in `finally`. |