/// Parse `timeline` arrays from Enjoy API JSON (after [convertKeysToCamel]).
///
/// Nested cue maps are often [Map<dynamic, dynamic>], not [Map<String, dynamic>],
/// so a naive `e is Map<String, dynamic>` check drops every line; see
/// [castJsonObjectOrNull].
library;

import 'package:enjoy_player/core/json/json_cast.dart';

import '../../../data/subtitle/transcript_line.dart';

List<TranscriptLine> transcriptLinesFromApiTimeline(dynamic timeline) {
  final lines = <TranscriptLine>[];
  if (timeline is! List) return lines;
  for (final e in timeline) {
    final m = castJsonObjectOrNull(e);
    if (m == null) continue;
    lines.add(TranscriptLine.fromJson(m));
  }
  return lines;
}
