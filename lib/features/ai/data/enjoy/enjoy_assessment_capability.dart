import 'package:enjoy_player/features/ai/domain/capabilities/assessment_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_request.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_result.dart';

/// Enjoy assessment uses Azure Speech SDK on web; Flutter pending.
final class EnjoyAssessmentCapability implements AssessmentCapability {
  const EnjoyAssessmentCapability();

  @override
  Future<AssessmentResult> assess(AssessmentRequest request) {
    throw UnimplementedError(
      'Enjoy pronunciation assessment requires Azure Speech (see ADR-0014).',
    );
  }
}
