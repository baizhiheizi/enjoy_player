/// Segments word-level timing data from Azure TTS into readable chunks.
library;

import 'dart:convert';

import 'package:enjoy_player/features/craft/domain/craft_synthesizer.dart';

/// One transcript segment: a chunk of text with audio timing.
class TranscriptSegment {
  const TranscriptSegment({
    required this.text,
    required this.startMs,
    required this.durationMs,
  });

  final String text;
  final int startMs;
  final int durationMs;
}

/// Splits word boundaries into segments suitable for shadow-reading practice.
///
/// Algorithm (simplified port of the web app's segmentation):
/// 1. Group words into sentences based on sentence-ending punctuation.
/// 2. Within each sentence, chunk into segments of `preferredWordsPerSegment`
///    words (default 6) or at sentence boundaries if shorter.
/// 3. Each segment's text is the joined words; start/duration come from the
///    first/last word's Azure-provided timings.
///
/// Returns an empty list if [wordBoundaries] is empty.
List<TranscriptSegment> segmentWordBoundaries(
  List<CraftWordBoundary> wordBoundaries, {
  int preferredWordsPerSegment = 6,
}) {
  if (wordBoundaries.isEmpty) return [];

  // Sentence boundaries.
  final sentenceEnd = RegExp(r'[.。！？!?]\s*$');

  final segments = <TranscriptSegment>[];
  var currentStart = wordBoundaries.first.audioOffsetMs;
  final currentWords = <CraftWordBoundary>[wordBoundaries.first];

  // Flush helper: emits a segment from currentWords if non-empty.
  void flush(bool isLastWord) {
    if (currentWords.isEmpty) return;
    final segmentText = currentWords.map((w) => w.text).join(' ');
    final lastEnd =
        currentWords.last.audioOffsetMs + currentWords.last.durationMs;
    segments.add(
      TranscriptSegment(
        text: segmentText,
        startMs: currentStart,
        durationMs: lastEnd - currentStart,
      ),
    );
    currentWords.clear();
  }

  for (var i = 1; i < wordBoundaries.length; i++) {
    final word = wordBoundaries[i];
    // If currentWords is empty (after a previous flush), seed with the
    // current segment's start time and add this word as the first.
    if (currentWords.isEmpty) {
      currentStart = word.audioOffsetMs;
      currentWords.add(word);
      continue;
    }
    // Check if the LAST word in currentWords ends a sentence; if so, the
    // sentence boundary is between the previous word and this new word.
    final previousEndsSentence = sentenceEnd.hasMatch(currentWords.last.text);
    final reachedSegmentSize = currentWords.length >= preferredWordsPerSegment;
    if (previousEndsSentence || reachedSegmentSize) {
      // Emit the current segment (without including the new word yet).
      flush(false);
      // Start a new segment at this word.
      currentStart = word.audioOffsetMs;
      currentWords.add(word);
    } else {
      currentWords.add(word);
    }
  }
  // Flush the final segment.
  flush(true);

  return segments;
}

/// Encodes the segments as a JSON string for the Drift `timelineJson` column.
String segmentsToTimelineJson(List<TranscriptSegment> segments) {
  return jsonEncode(
    segments
        .map(
          (s) => {'text': s.text, 'start': s.startMs, 'duration': s.durationMs},
        )
        .toList(),
  );
}
