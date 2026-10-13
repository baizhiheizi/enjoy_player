# azure_speech

Flutter plugin wrapping the **Microsoft Azure Cognitive Services Speech SDK** on Android, iOS, macOS, Windows, and Linux.

The Dart API starts with **pronunciation assessment** (one-shot WAV file, authorization-token auth); additional Speech scenarios can be added over time without renaming the package.

## Supported platforms

| Platform | Native SDK |
|----------|------------|
| Android | `com.microsoft.cognitiveservices.speech:client-sdk` (Maven) |
| iOS | `MicrosoftCognitiveServicesSpeech-iOS` (CocoaPods) |
| macOS | `MicrosoftCognitiveServicesSpeech-macOS` (CocoaPods) |
| Windows | `Microsoft.CognitiveServices.Speech` (NuGet, fetched at CMake configure) |
| Linux | `Microsoft.CognitiveServices.Speech` (same NuGet, `runtimes/linux-x64` or `linux-arm64`, fetched at CMake configure) |

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

The Linux plugin (`linux/`) uses the Speech SDK's C++ API with the same pinned
NuGet package as Windows. CMake copies `libMicrosoft.CognitiveServices.Speech.core.so`
and the OpenSSL platform shims (`libpal_azure_c_shared*.so`) next to the plugin
and exports them as bundled libraries, so the app bundle loads them from
`lib/` via `$ORIGIN`. Runtime requirement: the host's OpenSSL (3.x or 1.1).
See [ADR-0096](../../docs/decisions/0096-native-azure-speech-sdk-on-linux.md).

## Errors

Failures surface as [`AzureSpeechException`](lib/src/azure_speech_exception.dart) or `PlatformException` with codes such as `no_speech` and `azure_speech_error`.

## Layout

The package is a Flutter **plugin** (`flutter.plugin.platforms` in `pubspec.yaml`) under `packages/` so it can be moved to a standalone repo with minimal changes.
