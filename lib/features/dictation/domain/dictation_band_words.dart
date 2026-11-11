import 'dart:math' as math;
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/dictation/domain/dictation_diff.dart';
import 'package:enjoy_player/features/dictation/domain/dictation_models.dart';

List<DictationBandWord> buildDictationBandWords({
  required List<TranscriptLine> lines,
  required String fallbackReferenceText,
  required int regionStartMs,
  required int regionDurationMs,
}) {
  final bandWords = <DictationBandWord>[];

  final hasWordTimelines =
      lines.isNotEmpty && lines.any((l) => l.timeline?.isNotEmpty == true);

  if (hasWordTimelines) {
    for (final line in lines) {
      final lineTimeline = line.timeline;
      if (lineTimeline != null && lineTimeline.isNotEmpty) {
        for (final word in lineTimeline) {
          final letters = dictationWordOf(word.text);
          if (letters.isEmpty) {
            continue;
          }
          final width = (math.max(3, letters.length) * 9.5).round().toDouble();
          final start = line.startMs + (word.startMs ?? 0);
          final end = start + (word.durationMs ?? 0);
          bandWords.add(
            DictationBandWord(
              text: word.text,
              blockWidth: width,
              startMs: start,
              endMs: end,
            ),
          );
        }
      } else {
        final words = tokenizeDictationWords(line.text);
        if (words.isNotEmpty) {
          final totalChars = words.fold<int>(0, (sum, w) => sum + w.length);
          var cursorMs = line.startMs;
          for (final w in words) {
            final letters = dictationWordOf(w);
            final width = (math.max(3, letters.length) * 9.5)
                .round()
                .toDouble();
            final wordDuration = totalChars > 0
                ? ((w.length / totalChars) * line.durationMs).round()
                : 0;
            bandWords.add(
              DictationBandWord(
                text: w,
                blockWidth: width,
                startMs: cursorMs,
                endMs: cursorMs + wordDuration,
              ),
            );
            cursorMs += wordDuration;
          }
        }
      }
    }
  } else {
    final effectiveText = lines.isNotEmpty
        ? lines.map((l) => l.text).join(' ')
        : fallbackReferenceText;
    final words = tokenizeDictationWords(effectiveText);
    if (words.isNotEmpty) {
      final totalChars = words.fold<int>(0, (sum, w) => sum + w.length);
      var cursorMs = regionStartMs;
      for (final w in words) {
        final letters = dictationWordOf(w);
        final width = (math.max(3, letters.length) * 9.5).round().toDouble();
        final wordDuration = totalChars > 0
            ? ((w.length / totalChars) * regionDurationMs).round()
            : 0;
        bandWords.add(
          DictationBandWord(
            text: w,
            blockWidth: width,
            startMs: cursorMs,
            endMs: cursorMs + wordDuration,
          ),
        );
        cursorMs += wordDuration;
      }
    }
  }

  return bandWords;
}

int? findActiveDictationWordIndex({
  required List<DictationBandWord> words,
  required int currentPlaybackMs,
}) {
  for (var i = 0; i < words.length; i++) {
    final w = words[i];
    if (currentPlaybackMs >= w.startMs && currentPlaybackMs < w.endMs) {
      return i;
    }
  }
  return null;
}
