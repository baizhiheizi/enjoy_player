# Research: Deepgram Long-Form ASR (Flutter Client)

**Feature**: `025-deepgram-long-form-asr`  
**Date**: 2026-07-19  
**Spec**: [spec.md](spec.md)

## 1. Enjoy-path routing (short vs long)

**Decision**: On the Enjoy ASR capability path only, branch by declared media duration:

| Duration | Client path |
|---|---|
| `< 900` seconds | Existing sync `multipart/form-data` `POST /audio/transcriptions` (Whisper short-clip) |
| `≥ 900` seconds | Upload media → JSON `POST /audio/transcriptions` → poll `GET /audio/transcriptions/:job_id` |

BYOK ASR (Azure / OpenAI Whisper) is unchanged and never enters the Deepgram job flow.

**Rationale**: Matches the worker Content-Type split in `apps/worker/docs/long-form-transcription.md`. Flutter today always uses multipart; long media never hits Deepgram.

**Alternatives considered**:

- Route all Enjoy ASR through Deepgram jobs — rejected; short-clip sync UX and pricing remain Whisper.
- Keep uploading long files as multipart — rejected; worker multipart path is Whisper-only and unsuitable for multi-hour / large payloads.

---

## 2. Media upload / `media_reference` (cross-repo dependency)

**Decision**: Treat authenticated upload into Worker `DEEPGRAM_ASR` as a **required dependency**. Flutter implements a client against the contract in [contracts/media-upload.md](contracts/media-upload.md). The Worker must expose that upload API (it does **not** exist today). Object key layout is already fixed by worker code:

```text
media/{userId}/{media_reference}
```

where `media_reference` is an opaque suffix (e.g. UUID + extension), **not** a full `media/...` path (to avoid double-prefixing via `mediaKey`).

**Rationale**: Submit does `bucket.head(mediaKey(user.id, media_reference))` before creating a job. Without an upload API, Flutter cannot productize long-form end-to-end.

**Alternatives considered**:

- Ops-only R2 put for QA — fine for worker quickstart, not for learners.
- Rails Active Storage `DirectUploadsApi` — wrong bucket / ownership model; Deepgram source reads `DEEPGRAM_ASR` only.
- Embed upload in this Flutter-only PR without a Worker route — impossible; R2 writes must be authorized server-side.

**Implementation sequencing**:

1. Land Worker upload endpoint (enjoy monorepo) matching `contracts/media-upload.md`.
2. Land Flutter client + long-form branch (this feature).
3. Until (1) ships, Flutter unit tests mock the upload client; manual E2E waits on staging Worker.

---

## 3. Where to branch in Flutter

**Decision**: Keep `AsrCapability.transcribe(AsrRequest)` as the Enjoy entry. Inside `EnjoyAsrCapability` (or a dedicated helper it owns):

1. If `durationSeconds == null` or `< 900` → existing `AsrApi.transcribe` multipart.
2. If `≥ 900` → `AsrMediaUploadClient` → `AsrApi.submitLongForm` → poll → map to `AsrResult`.

`AsrGenerationController` gains phases `uploading` / `polling`, progress updates, cancel token propagation, and idempotency-key lifecycle. It does **not** call HTTP directly.

**Rationale**: BYOK resolution stays in `resolveAsrCapability`; UI / controller keep a single `AsrService.transcribe` call; short vs long is an Enjoy implementation detail.

**Alternatives considered**:

- Controller-only branching with raw `AsrApi` — rejected; leaks HTTP into application layer and duplicates auth/error mapping.
- New `LongFormAsrCapability` interface — unnecessary indirection if Enjoy can encapsulate both paths.

---

## 4. Idempotency and resume

**Decision**:

- Each user-visible **attempt** gets a new UUID `idempotency_key`.
- Transport retries / process resume for the **same** attempt reuse that key and, once known, the returned `job_id`.
- Persist in-flight attempt metadata locally (mediaId, idempotencyKey, jobId?, startedAt) via a small Drift table or existing prefs store so app restart can reattach poll without a second billable submit.
- Explicit cancel stops client polling; it does not require a Worker cancel API (none exists). A later **Re-generate** starts a new attempt (new key).
- After terminal `failed` with `retryable: true`, UI offers retry as a **new** attempt.

**Rationale**: Worker guarantees one provider job per `(user, idempotency_key)`. Client must preserve the key across flaky networks (FR-007 / FR-008).

**Alternatives considered**:

- Memory-only keys — fails SC for app kill mid-job.
- Always new key on every button press including network retry — risks double charge / double jobs.

---

## 5. Completed payload → local transcript

**Decision**: Map worker `transcript` object into existing `AsrResult` (`text`, `language`, `segments` with optional `words`, `duration` from `actual_duration_seconds`), then reuse `buildAsrTranscriptLines` + `TranscriptRepository.upsertAsrGeneratedTrack`.

Word-level array at transcript root (worker shape) is folded into segments or a synthetic segment list so the timeline builder’s word path can run.

**Rationale**: Avoid a second segmentation pipeline; format parity (US5) is already proven for Whisper-like `AsrResult`.

**Alternatives considered**:

- Persist worker JSON verbatim — rejected; breaks Drift / feature consumers expecting `TranscriptLine`.
- New Deepgram-specific line builder — deferred unless mapping quality fails QA.

---

## 6. Long-media confirm threshold

**Decision**: Change Enjoy long-media confirm from **30 minutes** to **15 minutes (900s)** to match the worker gate (FR-014). BYOK may keep a softer warning or the same 15-minute confirm for credit/time awareness; product default: one shared 900s confirm for all Generate paths when duration ≥ 900.

**Rationale**: Spec FR-014; current 30-minute dialog leaves 15–30 minute Enjoy jobs without the Credit warning before upload.

---

## 7. Failure and Credits UX

**Decision**: Map Worker / `ApiException` categories to existing ASR ARB keys where possible; add keys only for new long-form categories:

| Category / status | UX |
|---|---|
| `402` / `credits_exhausted` | Existing credits-exhausted + upgrade |
| `billing_exhausted` (failed job) | Credits / upgrade; no transcript applied |
| `provider_timeout` / `provider_failure` (`retryable: true`) | Retry CTA (new attempt) |
| `unsupported_media` | Non-retryable media message |
| `404` media | Upload/media missing message |
| `401` | Sign-in prompt |

Surface `usage.credits_charged` on success via existing credits patterns when cheap (snack/log); do not invent a new billing UI in v1 beyond consistency with other AI surfaces (FR-018 SHOULD).

---

## 8. Documentation and ADR

**Decision**:

- Update `docs/features/asr.md` (short Whisper vs long Deepgram job; 900s gate; remove stale “Enjoy Azure continuous” wording).
- Add ADR for **Enjoy long-form ASR via Worker Deepgram jobs + required media upload**, superseding any prior Azure long-form Enjoy assumption from `012`.

**Rationale**: Constitution V — costly-to-reverse vendor/path change and cross-repo upload dependency.

---

## 9. Performance budgets

**Decision**:

- Upload: stream/chunk when Worker supports it; never load multi-GB files into UI isolate as a single blocking read beyond existing 500 MB extract cap — for long-form prefer uploading the **extracted WAV/audio** (already capped) rather than the full mezzanine video when video was the source.
- Poll backoff: start 2s, cap 30s (worker client guidance).
- UI: phases `uploading` / `polling` with progress; playback remains usable (SC-006).

**Rationale**: Spec QR-004 / SC-006; extracted audio is what recognition needs and matches short-clip prep.

---

## 10. Test plan (research summary)

| Area | Tests |
|---|---|
| Routing | Enjoy duration 899 → multipart; 900 → long-form sequence (mocked HTTP) |
| Idempotency | Same attempt retries reuse key; new generate uses new key |
| Mapper | Completed job JSON → `AsrResult` → non-empty `TranscriptLine`s |
| Failures | 402, failed retryable/non-retryable → ARB mapping |
| Controller | Cancel during poll; resume from persisted job id |
| Dialog | Confirm shown at 900s, not only 1800s |
| Regression | Existing short-clip Enjoy + BYOK controller tests stay green |

Manual: Pro account, ≥15 min local file, staging Worker with upload enabled — see [quickstart.md](quickstart.md).
