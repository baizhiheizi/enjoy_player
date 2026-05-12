# azure_pronunciation_assessment

Flutter plugin wrapping **Microsoft Azure Cognitive Services Speech SDK** for **pronunciation assessment** (one-shot, file-based WAV input, authorization-token auth).

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
import 'package:azure_pronunciation_assessment/azure_pronunciation_assessment.dart';

final result = await AzurePronunciationAssessment.instance.assess(
  AzurePronunciationAssessmentParams(
    audioPath: '/path/to/file.wav',
    referenceText: 'Hello world',
    language: 'en-US',
    token: azureAuthorizationToken,
    region: 'eastus',
  ),
);

final scores = result.primaryScores;
```

Audio should be **16 kHz, 16-bit, mono WAV** (same convention as the web `azure-assessment-core` flow).

## Errors

Failures surface as [`AzurePronunciationAssessmentException`](lib/src/azure_pronunciation_assessment_exception.dart) or `PlatformException` with codes such as `no_speech` and `azure_speech_error`.

## Extraction

The package is a normal Flutter federated-style **plugin** (`flutter.plugin.platforms` in `pubspec.yaml`) under `packages/` so it can be moved to a standalone repo with minimal changes.
