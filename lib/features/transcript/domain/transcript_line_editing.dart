/// Pure editing transforms over [TranscriptLine] for the transcript editor.
library;

import '../../../data/subtitle/transcript_line.dart';

/// Formats [ms] as decimal seconds without trailing zeros (`0`, `1.25`, `12.345`).
String formatTranscriptTimingMs(int ms) {
  var text = (ms / 1000.0).toStringAsFixed(3);
  while (text.endsWith('0')) {
    text = text.substring(0, text.length - 1);
  }
  if (text.endsWith('.')) {
    text = text.substring(0, text.length - 1);
  }
  return text;
}

/// Parses decimal seconds into whole milliseconds; null when [input] is
/// blank, not a number, or negative.
int? parseTranscriptTimingMs(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  final seconds = double.tryParse(trimmed);
  if (seconds == null || seconds < 0) return null;
  return (seconds * 1000).round();
}

/// [line] with edited [text] and timing, keeping [TranscriptLine.sourceKey]
/// and [TranscriptLine.confidence]. Nested word timings survive only while
/// the text is unchanged; once the text moves they no longer match any word
/// and are dropped.
TranscriptLine editedTranscriptLine(
  TranscriptLine line, {
  required String text,
  required int startMs,
  required int durationMs,
}) {
  return TranscriptLine(
    text: text,
    startMs: startMs,
    durationMs: durationMs,
    sourceKey: line.sourceKey,
    confidence: line.confidence,
    timeline: text == line.text ? line.timeline : null,
  );
}
