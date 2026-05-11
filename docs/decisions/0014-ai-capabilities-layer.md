# ADR-0014: AI capabilities layer in Enjoy Player

## Status

Accepted

## Context

The web monorepo exposes AI features through `@enjoy/ai` (ASR, TTS, LLM, translation, dictionary, assessment) with a capability pattern and multiple backends (Enjoy worker, BYOK, local). Enjoy Player needs the same cloud surface for upcoming learning features, without coupling UI widgets to raw HTTP.

## Decision

1. Add a **feature-first `lib/features/ai/`** module with:
   - **Domain**: capability interfaces (`AsrCapability`, `LlmCapability`, …), requests/results, `AIServiceConfig` / `BYOKConfig` / `AIProvider` enums.
   - **Data**: Enjoy implementations calling typed APIs under `lib/data/api/services/ai/`; BYOK/local stubs that throw `UnimplementedError` until implemented.
   - **Application**: Riverpod providers resolve capabilities from `AiModalityConfigs` (defaults to Enjoy for every modality) and expose `AsrService`, `ChatService`, `TranslationService`, `DictionaryService`, `TtsService`, `AssessmentService`.
2. Extend **`ApiClient`** with **`postMultipartJson`** for Whisper-style `multipart/form-data` uploads.
3. Map **`ApiException` status 402** to a new **`CreditsFailure`** (distinct from generic `NetworkFailure`).
4. Ship a **Settings → Developer → AI playground** screen as the only UI in the first iteration; no transcript/shadow-reading wiring yet.
5. **TTS / assessment (Enjoy)**: keep interfaces but throw `UnimplementedError` in Flutter until Azure Speech (or worker-mediated audio) is available — mirroring the web dependency on short-lived Azure tokens + SDK.

## Consequences

- New AI features should call **services** (`asrServiceProvider`, etc.), not add parallel HTTP in widgets.
- Porting BYOK/local requires replacing stub capabilities and optionally persisting `AIServiceConfig` (e.g. Drift settings); no schema change was made in this ADR.
- Worker contract changes should be updated in **`lib/data/api/services/ai/`** and this feature spec together.

## References

- Web package: `enjoy/packages/ai` (`@enjoy/ai`)
- Feature spec: [features/ai.md](../features/ai.md)
