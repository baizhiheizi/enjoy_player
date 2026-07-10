import 'dart:typed_data';

import 'package:meta/meta.dart';

/// One word boundary event from Azure Speech synthesis.
@immutable
final class AzureWordBoundary {
  const AzureWordBoundary({
    required this.text,
    required this.audioOffsetMs,
    required this.durationMs,
  });

  /// The word text.
  final String text;

  /// Audio offset from the start, in milliseconds.
  final int audioOffsetMs;

  /// Duration of this word, in milliseconds.
  final int durationMs;
}

/// Result of Azure Speech text-to-speech (audio bytes + word-level timing).
@immutable
final class AzureSpeechSynthesisOutcome {
  const AzureSpeechSynthesisOutcome({
    required this.audioBytes,
    this.format = 'wav',
    this.wordBoundaries = const [],
  });

  final Uint8List audioBytes;
  final String format;

  /// Word-level timing data captured from Azure's wordBoundary events.
  /// Empty if the SDK did not fire any events.
  final List<AzureWordBoundary> wordBoundaries;
}
