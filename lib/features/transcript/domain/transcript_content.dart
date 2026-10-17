/// Decoded transcript content plus the row metadata callers used to read off
/// the whole row.
library;

import 'package:enjoy_player/data/subtitle/transcript_line.dart';

class TranscriptContent {
  const TranscriptContent({
    required this.id,
    required this.language,
    required this.source,
    required this.referenceId,
    required this.updatedAt,
    required this.lines,
  });

  final String id;
  final String language;
  final String source;
  final String? referenceId;
  final DateTime updatedAt;
  final List<TranscriptLine> lines;
}
