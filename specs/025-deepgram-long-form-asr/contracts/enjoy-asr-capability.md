# Contract: Enjoy ASR Capability (short + long)

**Feature**: `025-deepgram-long-form-asr`  
**Implements**: `AsrCapability.transcribe(AsrRequest)` for the Enjoy provider

## Input (`AsrRequest`)

Unchanged fields. For routing, **`durationSeconds` is required** on the Enjoy path whenever the controller knows media duration (already forwarded today).

| Condition | Behavior |
|---|---|
| `durationSeconds == null` or `< 900` | Short-clip multipart Whisper (`AsrApi.transcribe`) |
| `durationSeconds >= 900` | Long-form: upload → JSON submit → poll → map |

## Output (`AsrResult`)

Same shape for both paths so `buildAsrTranscriptLines` is shared.

Long-form mapping sources:

- `text` ← `transcript.text`
- `language` ← `transcript.language`
- `duration` ← `transcript.actual_duration_seconds` or `usage.actual_duration_seconds`
- `segments` ← `transcript.segments` (and/or synthesized from `transcript.words`)

## Errors

Throw / surface `ApiException` (or existing ASR-mapped exceptions) such that `AsrGenerationController` / failure mappers can show localized copy. Long-form terminal `failed` jobs become errors with category + retryable flag available to the mapper (extend exception payload if needed).

## Non-goals

- BYOK capabilities
- Worker callback / source routes
- UI widgets calling HTTP
