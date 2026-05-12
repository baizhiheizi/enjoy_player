/// Flutter plugin: Microsoft Azure Cognitive Services Speech SDK (native).
///
/// Currently exposes pronunciation assessment; the surface may grow with
/// additional Speech SDK scenarios.
library;

export 'src/azure_speech_exception.dart';
export 'src/azure_speech_params.dart';
export 'src/azure_speech_platform.dart';
export 'src/models.dart';

import 'src/azure_speech_params.dart';
import 'src/azure_speech_platform.dart';
import 'src/models.dart';

/// Entry point for Azure Speech operations from Dart.
final class AzureSpeech {
  AzureSpeech._();

  static final AzureSpeech instance = AzureSpeech._();

  /// One-shot pronunciation assessment from a WAV file (token auth).
  Future<AzurePronunciationAssessmentResult> assess(
    AzurePronunciationAssessmentParams params,
  ) => AzureSpeechPlatform.instance.assess(params);
}
