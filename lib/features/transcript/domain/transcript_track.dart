/// UI-facing subtitle track metadata (decoupled from persistence rows).
library;

class TranscriptTrack {
  const TranscriptTrack({
    required this.id,
    required this.mediaId,
    required this.language,
    required this.source,
    required this.label,
    required this.isEmbedded,
    this.trackIndex,
  });

  final String id;
  final String mediaId;
  final String language;
  final String source;
  final String label;
  final bool isEmbedded;
  final int? trackIndex;
}
