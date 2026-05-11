import 'package:enjoy_player/features/ai/domain/models/assessment_request.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_result.dart';

/// Pronunciation assessment (Azure Speech on web; Flutter pending).
abstract class AssessmentCapability {
  Future<AssessmentResult> assess(AssessmentRequest request);
}
