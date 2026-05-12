# ADR-0017: Azure pronunciation assessment via Flutter plugin (native SDK)

## Status

Accepted

## Context

ADR-0014 left Enjoy-backed pronunciation assessment as `UnimplementedError` in Flutter because Azure ships no Dart/Flutter SDK. The web stack uses the JavaScript Speech SDK with short-lived tokens from the Enjoy worker (`POST /azure/tokens`). Enjoy Player targets Android, iOS, macOS, and Windows and needs the same assessment semantics for future shadow-reading UX.

## Decision

1. Add a **path dependency plugin** at [`packages/azure_speech/`](../../packages/azure_speech/) that wraps the **official Azure Cognitive Services Speech SDK** per platform:
   - **Android** — Maven `com.microsoft.cognitiveservices.speech:client-sdk` (Kotlin host).
   - **iOS / macOS** — CocoaPods `MicrosoftCognitiveServicesSpeech-iOS` / `MicrosoftCognitiveServicesSpeech-macOS` (Swift).
   - **Windows** — NuGet `Microsoft.CognitiveServices.Speech` (C++), downloaded at CMake configure time and DLLs bundled via `PLUGIN_BUNDLED_LIBRARIES`.
2. Expose a **narrow Dart API** over a single `MethodChannel` (`azure_speech`): token + region + WAV path + reference text + language → parsed `AzurePronunciationAssessmentResult` (typed mirror of `SpeechServiceResponse_JsonResult`). The plugin package is named **`azure_speech`** so additional Speech SDK features can ship in the same package without another rename.
3. **Enjoy path**: [`EnjoyAssessmentCapability`](../../lib/features/ai/data/enjoy/enjoy_assessment_capability.dart) obtains tokens through [`AzureTokenCache`](../../lib/data/api/services/ai/azure_token_cache.dart) (9-minute in-memory TTL, same idea as web `@enjoy/ai`), then calls the plugin. **BYOK** remains unimplemented (ADR-0014 scope).
4. **Web** remains unsupported (`UnimplementedError` / plugin `UnsupportedError`); the app’s primary targets are desktop/mobile native.
5. **App minimum Android API** is raised to **24** where needed so the Speech SDK binary requirements are satisfied.

## Consequences

- iOS/macOS builds require **CocoaPods** with `use_frameworks!` (see root [`ios/Podfile`](../../ios/Podfile), [`macos/Podfile`](../../macos/Podfile)); first Windows build may **download** the Speech NuGet package (network).
- The plugin is intentionally **stateless** (no token storage, no recording) so it can be extracted as a standalone package later with minimal API surface.
- Pronunciation assessment **cost and auth** remain tied to the Enjoy worker token endpoint; misuse or token expiration surfaces as `AzureSpeechException` / `PlatformException` with `no_speech` / `azure_speech_error` codes.

## References

- [ADR-0014](0014-ai-capabilities-layer.md) — AI capabilities layer (Enjoy + stubs).
- [features/ai.md](../features/ai.md) — AI feature spec.
- [Azure-Samples/cognitive-services-speech-sdk](https://github.com/Azure-Samples/cognitive-services-speech-sdk) — official samples.
