import 'models.dart';

/// Result of native pronunciation assessment: parsed model + original JSON map.
///
/// [rawJson] is the object returned by [jsonDecode] of the Speech SDK
/// `SpeechServiceResponse_JsonResult` string (PascalCase keys). It is safe to pass
/// to [jsonEncode] for persistence — unlike [AzurePronunciationAssessmentResult.toJson],
/// which embeds Dart model instances in nested lists.
final class AzureSpeechAssessmentOutcome {
  const AzureSpeechAssessmentOutcome({
    required this.detail,
    required this.rawJson,
  });

  final AzurePronunciationAssessmentResult detail;

  /// Decoded JSON root map (same structure the native SDK returned).
  final Map<String, dynamic> rawJson;
}
