/// Synthesis port for the Craft flow (testable abstraction over TtsService).
library;

import 'dart:typed_data';

/// Result of a synthesis call.
class CraftSynthesisResult {
  const CraftSynthesisResult({required this.audioBytes, required this.format});

  final Uint8List audioBytes;
  final String format;
}

/// Abstract synthesis interface consumed by [CraftController].
///
/// The adapter implementation wraps [TtsService.synthesize] so the
/// controller stays testable without a live AI capability stack.
abstract interface class CraftSynthesizer {
  Future<CraftSynthesisResult> synthesize({
    required String text,
    required String language,
    String? voice,
  });
}
