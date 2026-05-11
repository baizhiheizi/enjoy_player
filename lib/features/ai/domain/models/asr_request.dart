import 'dart:typed_data';

/// Request for worker `POST /audio/transcriptions` (OpenAI-compatible).
final class AsrRequest {
  const AsrRequest({
    required this.audioBytes,
    required this.filename,
    this.mimeType,
    this.model,
    this.language,
    this.prompt,
    this.responseFormat = 'json',
    this.durationSeconds,
  });

  final Uint8List audioBytes;
  final String filename;
  final String? mimeType;
  final String? model;
  final String? language;
  final String? prompt;

  /// `json` | `text` | `vtt`
  final String responseFormat;
  final double? durationSeconds;
}
