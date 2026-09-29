part of 'transcript_repository.dart';

/// Module-private helpers shared by the [TranscriptRepository] part files:
/// track-summary mapping, source normalization / ordering, and robust server
/// date parsing. (Timeline decoding, cache keying, and the preload threshold
/// live in `transcript_timeline_codec.dart` — issue #766.)

TranscriptTrack _trackFromSummary(TranscriptTrackSummary summary) {
  return TranscriptTrack(
    id: summary.id,
    targetType: summary.targetType,
    targetId: summary.targetId,
    language: summary.language,
    source: summary.source,
    label: summary.label,
    trackIndex: summary.trackIndex,
  );
}

int _sourcePriority(String source) {
  switch (source) {
    case 'official':
      return 0;
    case 'auto':
      return 1;
    case 'ai':
      return 2;
    case 'user':
      return 3;
    default:
      return 4;
  }
}

void _sortTranscriptRows(List<TranscriptRow> rows) {
  rows.sort((a, b) {
    final pa = _sourcePriority(a.source);
    final pb = _sourcePriority(b.source);
    if (pa != pb) return pa.compareTo(pb);
    return a.createdAt.compareTo(b.createdAt);
  });
}

void _sortTranscriptSummaries(List<TranscriptTrackSummary> summaries) {
  summaries.sort((a, b) {
    final pa = _sourcePriority(a.source);
    final pb = _sourcePriority(b.source);
    if (pa != pb) return pa.compareTo(pb);
    return a.createdAt.compareTo(b.createdAt);
  });
}

TranscriptTimelineRevision _revisionOf(TranscriptRow row) =>
    (updatedAt: row.updatedAt, jsonLength: row.timelineJson.length);

String _normalizeSource(String raw) {
  switch (raw) {
    case 'official':
    case 'auto':
    case 'ai':
    case 'user':
      return raw;
    default:
      return 'official';
  }
}

DateTime _parseServerDate(dynamic v, DateTime fallback) {
  if (v is String) {
    return DateTime.tryParse(v) ?? fallback;
  }
  return fallback;
}

final Logger _log = logNamed('TranscriptRepository');
