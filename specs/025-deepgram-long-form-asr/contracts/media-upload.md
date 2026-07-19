# Contract: ASR Media Upload (Flutter ↔ Worker)

**Feature**: `025-deepgram-long-form-asr`  
**Status**: Required dependency — **Worker endpoint not implemented yet** (as of 2026-07-19). Flutter implements the client against this contract; Worker must land the matching route before product E2E.

## Purpose

Place audio bytes into Worker bucket `DEEPGRAM_ASR` at:

```text
media/{authenticated_user_id}/{media_reference}
```

so long-form `POST /audio/transcriptions` can `head` the object and Deepgram can later fetch via the Worker source route.

## Proposed endpoint

`PUT /audio/media/:media_reference`  
(or equivalently `POST /audio/media` with server-generated reference — if POST, response must return `media_reference`)

**Headers**:

| Header | Required | Notes |
|---|---|---|
| `Authorization: Bearer <token>` | yes | Same Enjoy auth as ASR |
| `Content-Type` | yes | e.g. `audio/wav`, `audio/mpeg` |
| `Content-Length` | yes | When known |

**Path / body**:

- `:media_reference` — client-generated opaque id (UUID + safe extension recommended), **without** `media/` or `userId/` prefix.
- Body — raw audio bytes (prefer extracted recognition audio from Flutter ASR pipeline, not full video containers when avoidable).

**Success**: `201` or `200`

```json
{
  "media_reference": "a1b2c3d4-e5f6-7890-abcd-ef1234567890.wav",
  "byte_length": 12345678
}
```

**Errors**:

| Status | Meaning |
|---|---|
| `401` | Unauthorized |
| `400` | Invalid reference or content type |
| `413` | Too large for configured / provider limits |
| `429` | Rate limited |

## Client rules (Flutter)

1. Generate `media_reference` before upload (UUID + `.wav` / source extension).
2. Upload only after extraction (video) or direct read (audio), respecting the existing size guard.
3. On success, pass `media_reference` into long-form submit.
4. Do not log full bearer tokens or raw signed URLs.
5. Cancel during upload aborts the HTTP request; do not submit a job for a partial object unless the Worker documents overwrite semantics (v1: treat cancel as failed attempt, new attempt gets a new reference).

## Server rules (Worker — implement in enjoy monorepo)

1. Authorize user; write exclusively under `media/{user.id}/{media_reference}`.
2. Reject path traversal / absolute-looking references.
3. Bind to `DEEPGRAM_ASR` only.
4. Overwrite of the same reference by the same user is allowed (simplifies retries of upload before submit).

## Test doubles

Flutter unit tests mock this client; they must not require a live R2 bucket. Staging E2E uses the real Worker route once deployed.
