# Data Model: Transcript Auto-Translate

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

> **No Drift schema migration for v1.** Auto-translated cues reuse `Transcripts`
> (`source: 'ai'`) and `EchoSessions.secondaryTranscriptId`. Job progress is
> derived from line text emptiness + in-memory controller state.

## Entities

### TranscriptRow — AI translation track (`Transcripts`)

One durable row per `(targetType, targetId, targetLanguage, source='ai')`.

| Field | Type | Auto-translate usage |
|-------|------|----------------------|
| `id` | text (PK) | `enjoyTranscriptId(targetType, targetId, language, 'ai')` |
| `targetType` / `targetId` | text | Same media as primary |
| `language` | text | Target reading language (profile native BCP-47 / base as stored consistently with other tracks) |
| `source` | text | Always `'ai'` |
| `timelineJson` | text | JSON array of `{text, start, duration}` — **same length and timings as primary**; `text` empty until line succeeds |
| `referenceId` | text? | **Primary transcript id** this AI track was generated from (staleness key) |
| `label` | text | User-facing label, e.g. localized “Auto translate” + language; may embed a short content fingerprint token for staleness (see below) |
| `trackIndex` | int? | `null` |
| `syncStatus` | text? | Prefer `'local'` (generated on device / worker, not library cloud sync) |
| `createdAt` / `updatedAt` | datetime | Bump `updatedAt` on progressive upserts |

**Id derivation**: unchanged `enjoyTranscriptId` — language + `ai` source yields a
stable id so resume upserts in place.

**Fingerprint (v1, no new column)**: compute
`fingerprint = hash(primaryId + lineCount + Σ(startMs, durationMs, text.length))`
and store a short prefix in `label` metadata convention **or** compare live
primary against skeleton timings + `referenceId` only. Prefer **`referenceId` +
timing/length check against current primary** at resume; full text hash optional
if primary edits become common.

### EchoSessionRow — selection wiring

| Field | Auto-translate usage |
|-------|----------------------|
| `transcriptId` | Unchanged — primary source of truth for translation input |
| `secondaryTranscriptId` | Set to AI track id when Auto translate is selected; cleared/`null` for None; other track ids for imported/official translations |

### AutoTranslateJob (logical, in-memory + derived)

Not a Drift table in v1. Owned by `AutoTranslateCtrl` per `mediaId`.

| Field | Notes |
|-------|-------|
| `mediaId` | Job key |
| `primaryTranscriptId` | Must match `referenceId` on AI row when healthy |
| `aiTranscriptId` | Deterministic AI row id |
| `targetLanguage` | Native language used for this run |
| `status` | `idle` \| `running` \| `paused` \| `blocked` \| `completed` \| `failed` |
| `blockReason` | Optional: `signedOut` \| `sameLanguage` \| `noPrimary` \| `credits` \| `auth` \| … |
| `pendingLineIndexes` | Lines with empty text still eligible |
| `failedLineIndexes` | Exhausted retries (calm per-line / summary UX) |
| `generation` | Monotonic; Re-translate increments so stale completions discard |
| `priorityAnchorIndex` | Current playback cue index for ordering |

### AutoTranslatedLine (logical view of one timeline entry)

| Field | Notes |
|-------|-------|
| `index` | Position in primary / AI timeline |
| `startMs` / `durationMs` | Copied from primary |
| `text` | Empty = pending; non-empty = ready |
| `attemptCount` | In-memory retry counter |
| `lineStatus` | `pending` \| `inFlight` \| `ready` \| `failed` (UI) |

## Relationships

```text
Primary TranscriptRow ──(1)──▶ EchoSession.transcriptId
        │
        │  Auto translate generates
        ▼
AI TranscriptRow (source=ai, referenceId=primary.id)
        │
        └──▶ EchoSession.secondaryTranscriptId  (when Auto translate selected)
```

## Validation rules

1. AI timeline length MUST equal primary timeline length after skeleton ensure.
2. AI `startMs`/`durationMs` MUST match primary per index after skeleton ensure.
3. Do not schedule translate when `workerLanguageBase(source) == workerLanguageBase(target)`.
4. Do not call the translation service when signed out; surface blocked status.
5. Selecting None / another secondary MUST stop displaying AI text (clear or
   retarget `secondaryTranscriptId`) and SHOULD pause/cancel the scheduler for
   this media.
6. Re-translate MUST increment `generation` and clear AI line texts (or rebuild
   skeleton) before rescheduling.
7. Deleting the AI track (if offered) MUST clear secondary when it pointed at
   that id (existing `deleteTranscript` behavior).

## State transitions

```text
                    select Auto translate
                            │
                            ▼
                   eligibility OK?
                     /         \
                   no           yes
                   │             │
                   ▼             ▼
               blocked      ensure AI skeleton
               (friendly)   set secondary = aiId
                                 │
                                 ▼
                            status=running
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                  │
              ▼                  ▼                  ▼
         translate line     seek/reprioritize   line fails
         (concurrency≤2)    pending queue       retry≤3 / mark failed
              │
              ▼
         upsert timelineJson (progressive)
              │
              ▼
         all ready? ──yes──▶ status=completed
              │
             no (continue)

  Re-translate ──▶ generation++ ──▶ clear texts ──▶ running
  Select None/other ──▶ pause job; secondary retargeted
  Primary changed (stale) ──▶ rebuild / prompt Re-translate
```

## UI state mapping (non-persisted)

| Job / line state | Learner-facing cue |
|------------------|--------------------|
| `running`, line empty | Compact “Translating…” under cue or subtle placeholder |
| line ready | Secondary text under primary (existing hierarchy) |
| line failed | Calm per-line hint; job continues |
| `blocked` signedOut | Auth required callout in picker / panel |
| `blocked` sameLanguage | Explanation; no spinner forever |
| `failed` job-level | Friendly summary + Retry / Re-translate |
| `completed` | Normal bilingual display; Re-translate still available |
