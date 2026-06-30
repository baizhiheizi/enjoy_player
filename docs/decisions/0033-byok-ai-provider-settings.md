# ADR-0033: BYOK AI provider settings

## Status

Accepted

## Context

ADR-0014 introduced the AI capabilities layer with Enjoy worker implementations and `UnimplementedError` stubs for BYOK/local. Users of the web `@enjoy/ai` package can supply their own LLM and speech credentials; Enjoy Player learners need the same option on native platforms without routing BYOK traffic through the Enjoy worker (no `/byok-proxy`).

Requirements (spec `003-byok-ai`):

- Per-modality provider choice: **Enjoy AI** vs **BYOK** (LLM, ASR, TTS, assessment).
- Secrets stored on-device only; non-secret config (base URL, model, region, API spec) in Drift settings JSON.
- Direct HTTPS to user endpoints for LLM; OpenAI-compatible Whisper/TTS; Azure Speech native plugin for assessment/ASR/TTS BYOK.
- Missing BYOK credentials must surface a typed, localized error with a link to settings — never silent fallback to Enjoy.

## Decision

1. **Persistence**
   - Settings key `ai.modality_configs_v1` holds per-modality `AIServiceConfig` (provider + `llmByok` / `speechByok` payloads).
   - API keys and Azure subscription keys live in **`ByokSecretStore`** (platform secure storage), keyed by `ModalityKind`.
   - Translation and dictionary configs mirror the LLM snapshot when LLM settings change.

2. **Capability routing** (`ai_capability_providers.dart`)
   - `AIProvider.enjoy` → existing `Enjoy*Capability` implementations.
   - `AIProvider.byok` → `Byok*Capability` classes under `lib/features/ai/data/byok/`.
   - `AIProvider.local` → `Unimplemented*Capability` (on-device models deferred).
   - Incomplete BYOK config at runtime → `ByokNotConfigured*Capability` throwing `ByokNotConfiguredFailure`.

3. **LLM BYOK**
   - `ai_sdk_dart` clients (`openAiCompatible`, `anthropicCompatible`, `googleCompatible`) with user `baseUrl`, model, and bearer key.
   - Presets (DeepSeek, Groq, etc.) are UI-only shortcuts; stored as non-secret metadata.
   - Translation, dictionary, and contextual translation BYOK reuse `ByokLlmCapability` with Enjoy-equivalent prompts.

4. **Speech BYOK**
   - **OpenAI-compatible**: HTTP clients for Whisper (`/audio/transcriptions`) and TTS (`/audio/speech`).
   - **Azure Speech**: extend `packages/azure_speech` with `transcribe` and `synthesize` (subscription-key auth); assessment BYOK uses the same plugin with subscription key instead of Enjoy token.

5. **Settings UI**
   - Route `/settings/ai-providers` with one [`ModalityProviderCard`][modality-card] per `ModalityKind` so the page reads as a cohesive settings surface (no per-modality fragmentation).
   - Each card uses a **segmented provider control** (`SegmentedButton<AIProvider>`) for Enjoy / BYOK, a **modality badge** (`_ProviderPill`) in the header that reflects the saved provider, and an **inset BYOK panel** (`_ByokPanel`) revealed via `AnimatedSwitcher` when BYOK is selected.
   - LLM and speech BYOK forms expose their own `SegmentedButton` for API spec / provider choice; assessment stays Azure-only (subscription key + region).
   - Card footer is calmer: a `Divider`-separated row with a provider-status icon, privacy/explainer text, optional **Remove BYOK**, and primary **Save** (with spinner during save).
   - Masked saved keys (e.g. `sk-…1234`) are shown as a preview chip so users can confirm a secret is persisted without revealing it.
   - Per-modality remove-BYOK with confirmation dialog; validation errors surface inline via `AppNotice.error` with localized keys from `byok_validation_messages.dart`.

   [modality-card]: ../../lib/features/ai/presentation/settings/widgets/modality_provider_card.dart

6. **Observability**
   - Log capability failures at warning level without API keys, subscription keys, or bearer tokens in message or attached objects.

## Consequences

- Enjoy credits and worker rate limits apply only to `AIProvider.enjoy` paths; BYOK errors are vendor-native.
- Enjoy TTS remains unimplemented; TTS BYOK is available via OpenAI-compatible or Azure synthesis.
- `AIProvider.local` stays a typed placeholder until on-device models are scoped.
- Schema changes to modality config require updating `AiModalityConfigRepository` encode/decode and the feature spec together.

## References

- Feature spec: [features/ai.md](../features/ai.md)
- Spec: `specs/003-byok-ai/`
- Supersedes the BYOK stub portion of [ADR-0014](0014-ai-capabilities-layer.md) (Enjoy path unchanged)
