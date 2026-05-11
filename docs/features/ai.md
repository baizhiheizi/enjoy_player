# AI capabilities (Enjoy worker)

Enjoy Player calls the same Enjoy / worker HTTP surface as the web `@enjoy/ai` package for cloud-backed AI. This document describes what is implemented in the Flutter app and where to extend it.

## Implemented (Enjoy provider)

| Modality | Worker route | Flutter entry |
|----------|----------------|---------------|
| ASR | `POST /audio/transcriptions` | `asrServiceProvider` → `AsrCapability` |
| LLM / chat | `POST /chat/completions` | `chatServiceProvider` → `LlmCapability` |
| Translation | `POST /translations` | `translationServiceProvider` → `TranslationCapability` |
| Dictionary | `POST /dictionary/query` | `dictionaryServiceProvider` → `DictionaryCapability` |
| Azure token | `POST /azure/tokens` | `azureTokenApiProvider` (reserved for TTS/assessment) |

## Not wired yet

- **TTS** and **pronunciation assessment** on the Enjoy path rely on Azure Speech SDK in the web stack. The player exposes capabilities that throw `UnimplementedError` until a native or server-mediated path exists ([ADR-0014](../decisions/0014-ai-capabilities-layer.md)).
- **BYOK** and **local** providers are typed (`AIServiceConfig`, `BYOKConfig`) but implementations throw `UnimplementedError`.

## Code layout

- Domain contracts and DTO-style models: `lib/features/ai/domain/`
- Enjoy + stub implementations: `lib/features/ai/data/`
- Riverpod services and capability wiring: `lib/features/ai/application/`
- HTTP clients (paths only): `lib/data/api/services/ai/`
- Debug UI: **Settings → Developer → AI playground** (`AiPlaygroundScreen`)

## Consumers

Feature screens should depend on `*ServiceProvider` types in `application/`, not on `ApiClient` directly, so modality and provider selection stay in one place.
