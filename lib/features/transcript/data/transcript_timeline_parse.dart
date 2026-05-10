/// Parse `timeline` arrays from Enjoy API JSON (after [convertKeysToCamel]).
///
/// Nested cue maps are often [Map<dynamic, dynamic>], not [Map<String, dynamic>],
/// so a naive `e is Map<String, dynamic>` check drops every line.
library;

import '../../../data/subtitle/transcript_line.dart';

List<TranscriptLine> transcriptLinesFromApiTimeline(dynamic timeline) {
  final lines = <TranscriptLine>[];
  if (timeline is! List) return lines;
  for (final e in timeline) {
    final m = _stringKeyMapFromJson(e);
    if (m == null) continue;
    lines.add(TranscriptLine.fromJson(m));
  }
  return lines;
}

Map<String, dynamic>? _stringKeyMapFromJson(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return Map<String, dynamic>.from(
      value.map((k, v) => MapEntry(k.toString(), v)),
    );
  }
  return null;
}
