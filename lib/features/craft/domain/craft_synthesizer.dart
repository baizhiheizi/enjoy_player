/// Synthesis port for the Craft flow (testable abstraction over TtsService).
library;

import 'dart:typed_data';

/// One word boundary from the synthesis (for accurate transcript timestamps).
class CraftWordBoundary {
  const CraftWordBoundary({
    required this.text,
    required this.audioOffsetMs,
    required this.durationMs,
  });

  final String text;
  final int audioOffsetMs;
  final int durationMs;
}

/// Result of a synthesis call.
class CraftSynthesisResult {
  const CraftSynthesisResult({
    required this.audioBytes,
    required this.format,
    this.wordBoundaries = const [],
  });

  final Uint8List audioBytes;
  final String format;
  final List<CraftWordBoundary> wordBoundaries;
}

/// Abstract synthesis interface consumed by [CraftController].
abstract interface class CraftSynthesizer {
  Future<CraftSynthesisResult> synthesize({
    required String text,
    required String language,
    String? voice,
  });
}
