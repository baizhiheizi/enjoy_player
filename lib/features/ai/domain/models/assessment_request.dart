import 'dart:typed_data';

final class AssessmentRequest {
  const AssessmentRequest({
    required this.audioBytes,
    required this.referenceText,
    required this.language,
    this.durationMs,
  });

  final Uint8List audioBytes;
  final String referenceText;
  final String language;
  final int? durationMs;
}
