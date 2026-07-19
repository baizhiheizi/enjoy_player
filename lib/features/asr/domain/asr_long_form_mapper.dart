/// Maps Worker long-form transcript payloads into [AsrResult].
library;

import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';
import 'package:enjoy_player/features/asr/domain/asr_long_form_models.dart';

/// Convert a completed long-form job transcript into the Whisper-shaped
/// [AsrResult] consumed by [buildAsrTranscriptLines].
AsrResult mapLongFormTranscriptToAsrResult(AsrLongFormTranscript transcript) {
  final words = transcript.words
      .map(
        (w) => AsrWord(
          word: w['word'] as String? ?? '',
          start: (w['start'] as num?)?.toDouble() ?? 0,
          end: (w['end'] as num?)?.toDouble() ?? 0,
        ),
      )
      .where((w) => w.word.trim().isNotEmpty)
      .toList();

  final segments = transcript.segments.map((s) {
    final segWordsRaw = s['words'] as List<dynamic>?;
    final segWords = segWordsRaw
        ?.whereType<Map>()
        .map(
          (e) => AsrWord(
            word: e['word'] as String? ?? '',
            start: (e['start'] as num?)?.toDouble() ?? 0,
            end: (e['end'] as num?)?.toDouble() ?? 0,
          ),
        )
        .where((w) => w.word.trim().isNotEmpty)
        .toList();
    return AsrSegment(
      start: (s['start'] as num?)?.toDouble() ?? 0,
      end: (s['end'] as num?)?.toDouble() ?? 0,
      text: s['text'] as String? ?? '',
      words: segWords,
    );
  }).toList();

  // Prefer segment list; if empty but root words exist, wrap words in one
  // synthetic segment so the timeline builder's word path can run.
  List<AsrSegment>? outSegments = segments.isEmpty ? null : segments;
  if ((outSegments == null || outSegments.isEmpty) && words.isNotEmpty) {
    outSegments = [
      AsrSegment(
        start: words.first.start,
        end: words.last.end,
        text: transcript.text,
        words: words,
      ),
    ];
  }

  return AsrResult(
    text: transcript.text,
    language: transcript.language,
    duration: transcript.actualDurationSeconds,
    segments: outSegments,
  );
}
