import 'package:enjoy_player/features/ai/data/azure_assessment_runner.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_azure_speech_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/assessment_capability.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_request.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_result.dart';

/// Pronunciation assessment via user Azure Speech subscription key + region.
final class ByokAssessmentAzureCapability extends ByokAzureSpeechCapability
    implements AssessmentCapability {
  ByokAssessmentAzureCapability({
    required super.config,
    required super.secrets,
    super.sdk,
  });

  @override
  ModalityKind get kind => ModalityKind.assessment;

  @override
  String get capabilityLabel => 'Assessment';

  @override
  Future<AssessmentResult> assess(AssessmentRequest request) async {
    final (:region, apiKey: subscriptionKey) = await resolveCredentials();

    return runAzurePronunciationAssessment(
      request: request,
      sdk: sdk,
      region: region,
      subscriptionKey: subscriptionKey,
    );
  }
}
