/// Maps an assessed take's word errors onto the loop lines' aligned word
/// indexes, for the wavy mispronunciation underlines (D3.8).
library;

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/transcript/application/take_assessment_notes.dart';

/// Word indexes per line index (absolute, over [lines]) that draw the wavy
/// underline, or null when there is nothing to note.
Map<int, Set<int>>? mispronouncedWordIndexes({
  required List<TranscriptLine> lines,
  required EchoState echo,
  required String? assessmentJson,
}) {
  final errorWords = takeAssessmentErrorWords(assessmentJson ?? '');
  if (errorWords.isEmpty) return null;
  return TakeAssessmentNotes.from(
    lines: lines,
    echo: echo,
    errorWords: errorWords,
  )?.byLine;
}
