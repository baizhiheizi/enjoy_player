/// Estimates timestamped transcript entries from text + total audio duration.
library;

import 'dart:convert';

/// Splits [text] into sentences and distributes [totalDurationMs]
/// proportionally by character count.
///
/// Returns a JSON-encodable list of `{'text': ..., 'start': ..., 'duration': ...}`
/// maps suitable for the Drift `Transcripts.timelineJson` column.
List<Map<String, dynamic>> estimateTimeline({
  required String text,
  required int totalDurationMs,
}) {
  final sentences = _splitSentences(text);
  if (sentences.isEmpty || totalDurationMs <= 0) {
    return [
      {'text': text.trim(), 'start': 0, 'duration': totalDurationMs},
    ];
  }

  final charCounts = sentences.map((s) => s.trim().length).toList();
  final totalChars = charCounts.fold(0, (a, b) => a + b);
  if (totalChars == 0) {
    return [
      {'text': text.trim(), 'start': 0, 'duration': totalDurationMs},
    ];
  }

  final result = <Map<String, dynamic>>[];
  var accumulatedChars = 0;
  for (var i = 0; i < sentences.length; i++) {
    final sentence = sentences[i].trim();
    if (sentence.isEmpty) continue;
    final chars = charCounts[i];
    final startMs = (accumulatedChars / totalChars * totalDurationMs).round();
    final durationMs = (chars / totalChars * totalDurationMs).round();
    result.add({'text': sentence, 'start': startMs, 'duration': durationMs});
    accumulatedChars += chars;
  }

  return result;
}

/// Encodes the timeline as a JSON string for the `timelineJson` column.
String encodeTimelineJson({
  required String text,
  required int totalDurationMs,
}) {
  final timeline = estimateTimeline(
    text: text,
    totalDurationMs: totalDurationMs,
  );
  return jsonEncode(timeline);
}

/// Splits text into sentences on common sentence-ending punctuation
/// across languages: `.`, `。`, `！`, `？`, `!`, `?`, and newlines.
List<String> _splitSentences(String text) {
  if (text.trim().isEmpty) return [];
  // Split on sentence-ending punctuation followed by optional whitespace,
  // keeping the punctuation with the sentence.
  final regex = RegExp(r'(?<=[.。！？!?\n])\s*');
  final parts = text.split(regex).where((s) => s.trim().isNotEmpty).toList();
  // If no sentence boundaries found, return the whole text as one sentence.
  return parts.isEmpty ? [text.trim()] : parts;
}
