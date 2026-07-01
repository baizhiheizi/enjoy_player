import 'package:azure_speech/azure_speech.dart';
import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/features/ai/data/azure_assessment_runner.dart';
import 'package:enjoy_player/features/ai/domain/byok_not_configured_failure.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/assessment_capability.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_request.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_result.dart';
import 'package:enjoy_player/features/ai/domain/speech_byok_kind.dart';

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
    if (_config.kind != SpeechByokKind.azureSpeech) {
      throw StateError('Assessment BYOK requires Azure Speech configuration');
    }

    final region = _config.region?.trim();
    if (region == null || region.isEmpty) {
      throw const ApiException(
        message: 'Azure region is not configured for assessment BYOK',
        statusCode: 400,
      );
    }

    final subscriptionKey = await _secrets.readApiKey(ModalityKind.assessment);
    if (subscriptionKey == null || subscriptionKey.trim().isEmpty) {
      throw const ByokNotConfiguredFailure(ModalityKind.assessment);
    }

    return runAzurePronunciationAssessment(
      request: request,
      sdk: _sdk,
      region: region,
      subscriptionKey: subscriptionKey.trim(),
    );
  }
}
