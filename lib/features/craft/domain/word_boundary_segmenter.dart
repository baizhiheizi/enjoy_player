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

final _sentenceEnd = RegExp(r'[.。！？!?]\s*$');
final _punctuationOnly = RegExp(r'^[.。！？!?]+$');

/// Whether [text] is sentence-ending / clause punctuation with no letters.
bool isPunctuationOnlyToken(String text) =>
    _punctuationOnly.hasMatch(text.trim());

/// Merges punctuation-only tokens onto the previous word and extends timing
/// so punctuation never starts a segment alone.
List<CraftWordBoundary> mergePunctuationTokens(
  List<CraftWordBoundary> wordBoundaries,
) {
  if (wordBoundaries.isEmpty) return const [];

  final merged = <CraftWordBoundary>[];
  for (final token in wordBoundaries) {
    final trimmed = token.text.trim();
    if (trimmed.isEmpty) continue;

    if (isPunctuationOnlyToken(trimmed)) {
      if (merged.isEmpty) {
        // Leading punct with no prior word — skip so a line cannot start with it.
        continue;
      }
      final prev = merged.removeLast();
      final prevEnd = prev.audioOffsetMs + prev.durationMs;
      final punctEnd = token.audioOffsetMs + token.durationMs;
      final newEnd = punctEnd > prevEnd ? punctEnd : prevEnd;
      merged.add(
        CraftWordBoundary(
          text: '${prev.text}$trimmed',
          audioOffsetMs: prev.audioOffsetMs,
          durationMs: newEnd - prev.audioOffsetMs,
        ),
      );
      continue;
    }

    merged.add(token);
  }
  return merged;
}

/// Splits word boundaries into segments suitable for shadow-reading practice.
///
/// 1. Merge punctuation-only tokens onto the previous word.
/// 2. Prefer flush at sentence-ending punctuation.
/// 3. Within a long sentence, chunk every [preferredWordsPerSegment] words.
///
/// Returns an empty list if [wordBoundaries] is empty or only punctuation.
List<TranscriptSegment> segmentWordBoundaries(
  List<CraftWordBoundary> wordBoundaries, {
  int preferredWordsPerSegment = 6,
}) {
  final words = mergePunctuationTokens(wordBoundaries);
  if (words.isEmpty) return [];

  final segments = <TranscriptSegment>[];
  var currentStart = words.first.audioOffsetMs;
  final currentWords = <CraftWordBoundary>[words.first];

  void flush() {
    if (currentWords.isEmpty) return;
    final segmentText = currentWords.map((w) => w.text).join(' ').trim();
    if (segmentText.isEmpty || isPunctuationOnlyToken(segmentText)) {
      currentWords.clear();
      return;
    }
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

  for (var i = 1; i < words.length; i++) {
    final word = words[i];
    if (currentWords.isEmpty) {
      currentStart = word.audioOffsetMs;
      currentWords.add(word);
      continue;
    }

    final previousEndsSentence = _sentenceEnd.hasMatch(currentWords.last.text);
    // Prefer sentence breaks; only chop by word count inside a sentence.
    final reachedSegmentSize =
        !previousEndsSentence &&
        currentWords.length >= preferredWordsPerSegment;

    if (previousEndsSentence || reachedSegmentSize) {
      flush();
      currentStart = word.audioOffsetMs;
      currentWords.add(word);
    } else {
      currentWords.add(word);
    }
  }
  flush();

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

/// Builds Craft primary `timelineJson` when timings are solid.
///
/// Returns `null` when [wordBoundaries] is empty or segmentation yields no
/// valid lines (blank transcript — learner generates via STT in the player).
String? buildCraftPrimaryTimelineJson(
  List<CraftWordBoundary> wordBoundaries, {
  int preferredWordsPerSegment = 6,
}) {
  final segments = segmentWordBoundaries(
    wordBoundaries,
    preferredWordsPerSegment: preferredWordsPerSegment,
  );
  if (segments.isEmpty) return null;
  return segmentsToTimelineJson(segments);
}
