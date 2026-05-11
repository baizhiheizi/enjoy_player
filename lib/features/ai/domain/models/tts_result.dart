import 'dart:typed_data';

/// Placeholder result for future TTS implementations.
final class TtsResult {
  const TtsResult({this.audioBytes, this.format, this.durationMs});

  final Uint8List? audioBytes;
  final String? format;
  final int? durationMs;
}
