# AI capabilities (Enjoy worker)

Enjoy Player calls the same Enjoy / worker HTTP surface as the web `@enjoy/ai` package for cloud-backed AI. This document describes what is implemented in the Flutter app and where to extend it.

## Implemented (Enjoy provider)

| Modality | Worker route | Flutter entry |
|----------|----------------|---------------|
| ASR | `POST /audio/transcriptions` | `asrServiceProvider` → `AsrCapability` |
| LLM / chat | `POST /chat/completions` | `chatServiceProvider` → `LlmCapability` |
| Translation | `POST /translations` | `translationServiceProvider` → `TranslationCapability` |
| Dictionary | `POST /dictionary/query` | `dictionaryServiceProvider` → `DictionaryCapability` |
| Azure token | `POST /azure/tokens` | `azureTokenApiProvider` + `azureTokenCacheProvider` (9 min TTL) |
| Pronunciation assessment | `POST /azure/tokens` + **native Azure Speech SDK** | `assessmentServiceProvider` → `EnjoyAssessmentCapability` → [`packages/azure_speech`](../../packages/azure_speech/) |

### Native pronunciation plugin

- **Package**: [`packages/azure_speech/README.md`](../../packages/azure_speech/README.md) (Speech SDK wrapper; pronunciation assessment implemented first)
- **Capability**: [`lib/features/ai/data/enjoy/enjoy_assessment_capability.dart`](../../lib/features/ai/data/enjoy/enjoy_assessment_capability.dart) (token cache + WAV path or temp file from bytes). Before calling the SDK, recordings are re-encoded via **FFmpeg** to **16 kHz mono 16-bit PCM WAV** ([`azure_assessment_wav_normalizer.dart`](../../lib/features/ai/data/azure_assessment_wav_normalizer.dart)) so legacy float / odd-RIFF WAVs do not trigger Azure **SPXERR_UNEXPECTED_EOF**. The normalizer uses an **`aresample` + `aformat` filter graph** for reliable Windows decodes, rejects silent FFmpeg output via a peak/RMS scan ([`wav_signal_peak.dart`](../../lib/core/audio/wav_signal_peak.dart)), and the capability falls back to assessing the original recording if the normalized run comes back blank.
- **Language codes**: [`lib/features/ai/data/azure_language_mapper.dart`](../../lib/features/ai/data/azure_language_mapper.dart) maps short / transcript codes to Azure locales (aligned with the browser extension mapper).
- **Persistence**: `assessment_json` stores the **decoded native SDK JSON** (PascalCase keys from `SpeechServiceResponse_JsonResult`), not `AzurePronunciationAssessmentResult.toJson()`, so `jsonEncode` round-trips correctly when reopening the assessment dialog.
- **Observability**: Logger `ai.enjoy.assessment` logs recognition status, aggregate scores, word/omission counts, and audio metadata (file name, byte size, whether FFmpeg normalization ran). All-zero aggregate scores emit a **warning** (often silent or mismatched audio vs reference, skipped normalization, or locale mismatch).

Assessment is **not available on web** in this app. **Shadow reading** exposes per-take assess + result dialog (see [echo-mode](echo-mode.md)).

## Not wired yet

- **TTS** on the Enjoy path still throws `UnimplementedError` (extend [`packages/azure_speech`](../../packages/azure_speech/) when needed).
- **BYOK** and **local** providers are typed (`AIServiceConfig`, `BYOKConfig`) but implementations throw `UnimplementedError`.

## Code layout

- Domain contracts and DTO-style models: `lib/features/ai/domain/`
- Enjoy + stub implementations: `lib/features/ai/data/`
- Riverpod services and capability wiring: `lib/features/ai/application/`
- HTTP clients (paths only): `lib/data/api/services/ai/`
- Debug UI: **Settings → Developer → AI playground** (`AiPlaygroundScreen`) — includes **pronunciation assessment** (pick WAV + reference text + language).

## Consumers

Feature screens should depend on `*ServiceProvider` types in `application/`, not on `ApiClient` directly, so modality and provider selection stay in one place.
