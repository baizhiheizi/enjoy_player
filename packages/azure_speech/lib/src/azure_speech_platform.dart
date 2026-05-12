import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'azure_pronunciation_assessment_params.dart';
import 'method_channel_azure_pronunciation_assessment.dart';
import 'models.dart';

/// Platform abstraction for Azure pronunciation assessment.
abstract class AzurePronunciationAssessmentPlatform extends PlatformInterface {
  AzurePronunciationAssessmentPlatform() : super(token: _token);

  static final Object _token = Object();

  static AzurePronunciationAssessmentPlatform _instance =
      MethodChannelAzurePronunciationAssessment();

  static AzurePronunciationAssessmentPlatform get instance => _instance;

  static set instance(AzurePronunciationAssessmentPlatform impl) {
    PlatformInterface.verifyToken(impl, _token);
    _instance = impl;
  }

  Future<AzurePronunciationAssessmentResult> assess(
    AzurePronunciationAssessmentParams params,
  );
}
