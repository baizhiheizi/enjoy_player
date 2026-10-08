# azure_speech

Flutter plugin wrapping the **Microsoft Azure Cognitive Services Speech SDK** on Android, iOS, macOS, and Windows.

The Dart API starts with **pronunciation assessment** (one-shot WAV file, authorization-token auth); additional Speech scenarios can be added over time without renaming the package.

## Supported platforms

| Platform | Native SDK |
|----------|------------|
| Android | `com.microsoft.cognitiveservices.speech:client-sdk` (Maven) |
| iOS | `MicrosoftCognitiveServicesSpeech-iOS` (CocoaPods) |
| macOS | `MicrosoftCognitiveServicesSpeech-macOS` (CocoaPods) |
| Windows | `Microsoft.CognitiveServices.Speech` (NuGet, fetched at CMake configure) |

**Web** is not supported (`UnsupportedError`).

## Usage

```dart
import 'package:azure_speech/azure_speech.dart';

final outcome = await AzureSpeech.instance.assess(
  AzurePronunciationAssessmentParams(
    audioPath: '/path/to/file.wav',
    referenceText: 'Hello world',
    language: 'en-US',
    token: azureAuthorizationToken,
    region: 'eastus',
  ),
);

final scores = outcome.detail.primaryScores;
```

Audio should be **16 kHz, 16-bit, mono WAV** (same convention as the web `azure-assessment-core` flow).

## Linux

The plugin ships no native Speech SDK implementation for Linux. `synthesize`
therefore goes over Azure's REST TTS endpoint (`cognitiveservices/v1`) in pure
Dart there: same WAV output (16 kHz mono), same token / subscription-key auth,
but no word boundaries (a native-SDK event stream). Synthesis on Linux
requires an explicit `voice`; `assess` and `transcribe` throw
`AzureSpeechException` with code `unsupported_platform` until the native SDK
is vendored for Linux.

## Errors

Failures surface as [`AzureSpeechException`](lib/src/azure_speech_exception.dart) or `PlatformException` with codes such as `no_speech` and `azure_speech_error`.

## Layout

The package is a Flutter **plugin** (`flutter.plugin.platforms` in `pubspec.yaml`) under `packages/` so it can be moved to a standalone repo with minimal changes.
