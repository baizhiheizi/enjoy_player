/// Flutter plugin: Azure Cognitive Services Speech — pronunciation assessment.
library;

export 'src/azure_pronunciation_assessment_exception.dart';
export 'src/azure_pronunciation_assessment_params.dart';
export 'src/azure_pronunciation_assessment_platform.dart';
export 'src/models.dart';

import 'src/azure_pronunciation_assessment_params.dart';
import 'src/azure_pronunciation_assessment_platform.dart';
import 'src/models.dart';

/// Facade for one-shot pronunciation assessment.
final class AzurePronunciationAssessment {
  AzurePronunciationAssessment._();

  static final AzurePronunciationAssessment instance =
      AzurePronunciationAssessment._();

  Future<AzurePronunciationAssessmentResult> assess(
    AzurePronunciationAssessmentParams params,
  ) => AzurePronunciationAssessmentPlatform.instance.assess(params);
}
