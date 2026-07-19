# Data Model: Deepgram Long-Form ASR (Flutter Client)

**Feature**: `025-deepgram-long-form-asr`  
**Date**: 2026-07-19

Local Drift transcript/media schemas are unchanged. This feature adds **transient** and optional **in-flight attempt** state, plus client DTOs that mirror the Worker job contract.

## Entities

### AsrLongFormJob (DTO — Worker response)

| Field | Type | Notes |
|---|---|---|
| `jobId` | string | Worker UUID |
| `status` | enum | `accepted` \| `processing` \| `completed` \| `failed` |
| `createdAt` | DateTime | |
| `updatedAt` | DateTime? | |
| `completedAt` | DateTime? | Terminal success |
| `failure` | AsrLongFormFailure? | When `failed` |
| `usage` | AsrLongFormUsage? | When `completed` |
| `transcript` | AsrLongFormTranscript? | When `completed` |

**Terminal states**: `completed`, `failed`. Non-terminal: `accepted`, `processing`.

### AsrLongFormFailure

| Field | Type | Notes |
|---|---|---|
| `category` | string | `provider_failure`, `provider_timeout`, `unsupported_media`, `billing_exhausted`, … |
| `retryable` | bool | Drives Retry vs Upgrade / change-media UX |
| `message` | string | Safe server message; UI prefers localized mapping |

### AsrLongFormUsage

| Field | Type | Notes |
|---|---|---|
| `actualDurationSeconds` | double | Provider-measured; billing authority |
| `creditsCharged` | int | Settled Credits |

### AsrLongFormTranscript

| Field | Type | Notes |
|---|---|---|
| `text` | string | Full text |
| `language` | string? | BCP-47 / base tag from Worker |
| `actualDurationSeconds` | double? | |
| `segments` | list | `{ start, end, text }` seconds |
| `words` | list | `{ word, start, end, confidence? }` seconds |
| `generatedAt` | DateTime? | |
| `provider` | string? | Informational (`deepgram`) |
| `model` | string? | Informational |

**Mapping rule**: Convert to existing `AsrResult` before `buildAsrTranscriptLines`. Prefer word timings when present; else segments; else plain text + media duration.

### AsrMediaReference

| Field | Type | Notes |
|---|---|---|
| `mediaReference` | string | Opaque suffix under `media/{userId}/` |
| `contentType` | string? | e.g. `audio/wav` |
| `byteLength` | int? | Optional client bookkeeping |

### AsrLongFormAttempt (local in-flight record)

Persisted so app restart can resume polling for the same attempt.

| Field | Type | Notes |
|---|---|---|
| `mediaId` | string | Local library media id (PK or part of PK) |
| `idempotencyKey` | string | UUID for this attempt |
| `jobId` | string? | Set after `202` / idempotent return |
| `language` | string? | Requested language (null = multilingual) |
| `declaredDurationSeconds` | double | Preflight duration sent to Worker |
| `mediaReference` | string? | After successful upload |
| `startedAt` | DateTime | |
| `status` | enum | `uploading` \| `submitted` \| `polling` \| `cancelled` \| `terminal` |

**Validation**:

- Only one active non-terminal attempt per `mediaId`.
- Clearing on `success` / user dismiss after `failed` / superseded attempt.
- New Generate after terminal → new row / new `idempotencyKey`.

### AsrGenerationPhase (extend existing)

Existing enum gains:

| Value | Meaning |
|---|---|
| `uploading` | Media bytes transferring to Worker storage |
| `polling` | Job accepted; waiting for terminal status |

Existing: `idle`, `extracting`, `recognizing` (short-clip), `persisting`, `success`, `error`, `cancelled`.

### Existing entities (unchanged contracts)

- **`AsrRequest` / `AsrResult`**: short-clip path unchanged; long-form maps into `AsrResult`.
- **`Transcript` row `source: ai`**: deterministic id upsert via `upsertAsrGeneratedTrack`.
- **Media language field**: still updated when recognition returns a detected language.

## State transitions (long-form Enjoy)

```text
idle
  → extracting (video) | uploading (audio-only may skip extract if already suitable)
  → uploading
  → polling (after 202)
  → persisting (completed + mapped lines)
  → success
  → error | cancelled (from uploading/polling; no persist)
```

Worker job status while `polling`: `accepted` / `processing` → continue; `completed` → persist; `failed` → error.

## Relationships

```text
AsrLongFormAttempt 1──1 local mediaId
AsrLongFormAttempt 0..1──1 AsrLongFormJob (via jobId)
AsrLongFormJob 0..1──1 AsrLongFormTranscript
AsrLongFormTranscript ──maps──→ AsrResult ──→ TranscriptLine[] ──→ source:ai track
```
