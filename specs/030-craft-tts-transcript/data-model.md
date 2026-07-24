# Data Model: Craft TTS Transcript Quality

**Feature**: `030-craft-tts-transcript` | **Date**: 2026-07-24

No new Drift tables or columns. Behavior changes how Craft fills (or omits) existing `Transcripts` rows.

## Entities

### Craft practice text (unchanged)

| Field | Role |
|-------|------|
| `Audios.sourceText` | Original / express raw or advanced source text retained on the media row |
| Normalized synth text | Dedup key input; wording source for solid cue lines |

### Synthesis timing token (`CraftWordBoundary`)

| Field | Type | Notes |
|-------|------|-------|
| `text` | string | May be a word or punctuation-only token from Azure |
| `audioOffsetMs` | int | Start offset in synthesized audio |
| `durationMs` | int | Token duration |

### Transcript segment (domain → `timelineJson`)

| Field | JSON key | Notes |
|-------|----------|-------|
| `text` | `text` | Joined words; never punctuation-only line start after builder |
| `startMs` | `start` | From first token in segment |
| `durationMs` | `duration` | Through last token end |

### Solid vs blank primary transcript

| State | Persistence |
|-------|-------------|
| **Solid** | One `Transcripts` row: `targetType=Audio`, `targetId=<audioId>`, `language=<learning>`, `source='ai'`, `timelineJson` = JSON array of segments |
| **Blank** | **No** primary timed transcript row for that media (create), or existing rows removed (update). Player treats as empty lines → empty state |

### Media identity (unchanged)

| Field | Value |
|-------|-------|
| `Audios.provider` | `'craft'` |
| `Audios.source` | `craft-express` \| `craft-translate` \| `craft-direct` |
| Content hash / dedupe | Unchanged (`sourceFlag\|lang\|normalizedText\|voice`) |

## Validation rules

1. Solid gate: `wordBoundaries.isNotEmpty` ∧ `segments.isNotEmpty` ∧ every saved line `text.trim().isNotEmpty`.
2. After punctuation merge, no line `text` matches `^[.。！？!?]+$` (or starts with those as sole content).
3. Blank save MUST still create/update the `Audios` row and local audio file (FR-011).
4. Repository MUST NOT coerce `primaryTimelineJson == null` into a single synthetic cue object.

## State transitions (Craft save)

```text
[previewAudioBytes + optional wordBoundaries]
        │
        ▼
   segment + solid gate
        │
   ┌────┴────┐
   │ solid   │ blank
   ▼         ▼
 write AI    omit/delete
 transcript  transcript
 + audio     + audio only
```

## Relationships

- Craft audio **1 — 0..1** solid primary AI transcript (this feature); STT later may add/replace via existing ASR upsert (`source` conventions per ASR feature).
- STT generate/replace is **not** modeled in Craft domain; it uses `transcript` / `asr` features against the same `Audios.id`.

## Lifecycle notes

- **Edit-in-place** (`updateCraftedFromText`): re-run solid gate; blank clears prior Craft AI transcript so estimated/solid cues cannot linger incorrectly.
- **Dedupe hit**: returns existing id without rewrite (existing behavior); out of scope to retro-fix old estimated timelines on dedupe.
