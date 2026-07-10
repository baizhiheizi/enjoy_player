import 'dart:typed_data';

/// One word boundary captured from Azure Speech synthesis.
final class TtsWordBoundary {
  const TtsWordBoundary({
    required this.text,
    required this.audioOffsetMs,
    required this.durationMs,
  });

  final String text;
  final int audioOffsetMs;
  final int durationMs;
}

/// Result of a TTS call.
final class TtsResult {
  const TtsResult({
    this.audioBytes,
    this.format,
    this.durationMs,
    this.wordBoundaries = const [],
  });

  final Uint8List? audioBytes;
  final String? format;
  final int? durationMs;

  /// Word-level timing from Azure's wordBoundary events. Empty if not available.
  final List<TtsWordBoundary> wordBoundaries;
}
