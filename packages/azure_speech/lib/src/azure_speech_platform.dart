import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'azure_speech_assessment_outcome.dart';
import 'azure_speech_params.dart';
import 'method_channel_azure_speech.dart';

/// Platform abstraction for Azure Speech (native SDK).
abstract class AzureSpeechPlatform extends PlatformInterface {
  AzureSpeechPlatform() : super(token: _token);

  static final Object _token = Object();

  static AzureSpeechPlatform _instance = MethodChannelAzureSpeech();

  static AzureSpeechPlatform get instance => _instance;

  static set instance(AzureSpeechPlatform impl) {
    PlatformInterface.verifyToken(impl, _token);
    _instance = impl;
  }

  Future<AzureSpeechAssessmentOutcome> assess(
    AzurePronunciationAssessmentParams params,
  );
}
