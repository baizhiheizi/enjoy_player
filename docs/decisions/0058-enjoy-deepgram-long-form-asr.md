# ADR-0058: Enjoy long-form ASR via Worker Deepgram jobs

## Status

Accepted

## Context

Enjoy Player already generates local-file transcripts through `AsrCapability`.
Short clips on the Enjoy path use Worker Whisper (`multipart`). Longer media
previously assumed Azure continuous recognition on the Enjoy path, which no
longer matches the Worker. The Worker now exposes Deepgram long-form jobs
(`application/json` submit + poll) for clips ≥ 900 seconds, requiring media
already stored under `DEEPGRAM_ASR` at `media/{userId}/{media_reference}`.

## Decision

1. On the Enjoy ASR path, route by duration: **&lt; 900s** keep Whisper multipart;
   **≥ 900s** upload recognition audio via `PUT /audio/media/:media_reference`,
   then submit/poll the Worker long-form API.
2. Keep BYOK Azure / OpenAI Whisper unchanged (no Enjoy Deepgram billing).
3. Persist in-flight long-form attempt metadata (idempotency key, job id, media
   reference) so retries and restarts reattach safely.
4. Align the long-media confirm dialog threshold with the Worker gate (15
   minutes).
5. Map completed job transcripts into existing `AsrResult` /
   `buildAsrTranscriptLines` / `source: ai` upsert paths.

## Consequences

- Product E2E depends on the Worker media-upload route being deployed.
- Flutter must not send multi-hour files as Whisper multipart.
- Docs (`docs/features/asr.md`) describe Whisper short vs Deepgram long Enjoy
  routing; stale “Enjoy Azure continuous” wording is retired.
- Credits for long-form are settled server-side from provider duration; Free
  tier remains blocked at preflight for ≥ 15 minute jobs.
- Surfacing `usage.credits_charged` on long-form success is deferred until it
  fits the existing credits notice pattern without a new UI surface.
