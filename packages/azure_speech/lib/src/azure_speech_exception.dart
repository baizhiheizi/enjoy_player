/// Thrown when native Azure Speech assessment fails or returns no usable JSON.
final class AzurePronunciationAssessmentException implements Exception {
  const AzurePronunciationAssessmentException({
    required this.code,
    required this.message,
    this.details,
  });

  /// Machine-readable: `no_speech`, `canceled`, `parse_error`, `platform_error`, etc.
  final String code;
  final String message;
  final Object? details;

  @override
  String toString() =>
      'AzurePronunciationAssessmentException($code): $message';
}
