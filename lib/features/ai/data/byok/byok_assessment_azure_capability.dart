import 'package:azure_speech/azure_speech.dart';
import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/features/ai/data/azure_assessment_runner.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_speech_guards.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/assessment_capability.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_request.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_result.dart';

/// Pronunciation assessment via user Azure Speech subscription key + region.
final class ByokAssessmentAzureCapability implements AssessmentCapability {
  ByokAssessmentAzureCapability({
    required this._config,
    required this._secrets,
    AzureSpeech? sdk,
  }) : _sdk = sdk ?? AzureSpeech.instance;

  final SpeechByokConfig _config;
  final ByokSecretStoreBase _secrets;
  final AzureSpeech _sdk;

  @override
  Future<AssessmentResult> assess(AssessmentRequest request) async {
    final (:region, apiKey: subscriptionKey) = await guardAzureSpeechConfig(
      config: _config,
      secrets: _secrets,
      kind: ModalityKind.assessment,
      capabilityLabel: 'assessment',
    );

    return runAzurePronunciationAssessment(
      request: request,
      sdk: _sdk,
      region: region,
      subscriptionKey: subscriptionKey,
    );
  }
}
