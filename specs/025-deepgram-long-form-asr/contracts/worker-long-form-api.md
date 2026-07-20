# Contract: Worker Long-Form Transcription (Flutter Consumer)

**Feature**: `025-deepgram-long-form-asr`  
**Upstream source of truth**: Enjoy Worker `apps/worker/docs/long-form-transcription.md` and `specs/011-deepgram-long-form-asr/contracts/http-api.md`  
**Base URL**: Enjoy AI / Worker origin (same as existing `AsrApi`, default `https://worker.enjoy.bot`)

Flutter consumes these endpoints via `AsrApi` + bearer auth from the existing AI API client. This document records the **client obligations**, not a re-spec of Worker internals.

## Auth

All end-user calls: `Authorization: Bearer <enjoy_access_token>`.

## Submit long-form job

`POST /audio/transcriptions`  
`Content-Type: application/json`

```json
{
  "media_reference": "<opaque-suffix>",
  "duration_seconds": 3720,
  "language": "en",
  "idempotency_key": "<client-attempt-uuid>"
}
```

| Field | Required | Client rules |
|---|---|---|
| `media_reference` | yes | Opaque id returned by [media-upload.md](media-upload.md); must already exist under the user namespace |
| `duration_seconds` | yes | Local media duration; must be `>= 900` or Worker returns `400` |
| `language` | no | BCP-47 base tag (e.g. `en`); omit for multilingual mode |
| `idempotency_key` | yes | Stable for one attempt; max 256 chars |

**Success**: `202` with `{ job_id, status, created_at }`.  
**Idempotent replay**: same user + key → same `job_id` (and current status).

**Errors the client must handle**: `400`, `401`, `402`, `404`, `409`, plus transport failures (retry with same key).

## Poll job

`GET /audio/transcriptions/:job_id`

**Client backoff**: start ~2s, exponential/linear increase, max ~30s; cancel stops further polls.

| Status | Client action |
|---|---|
| `accepted` / `processing` | Continue polling |
| `completed` | Map `transcript` (+ `usage`) → local AI track; stop |
| `failed` | Map `failure`; stop; no persist |

Polling has no Credits charge.

## Short-clip boundary (non-goals)

`POST /audio/transcriptions` with `multipart/form-data` remains the short-clip Enjoy path (`AsrApi.transcribe` today). Long-form Flutter code must **not** send ≥900s media as multipart for recognition.

## Out of scope for Flutter

- `POST .../callback` (Deepgram → Worker)
- `GET .../source/:job_id` (Deepgram → Worker)
- Deepgram API keys, pricing rates, R2 credentials
