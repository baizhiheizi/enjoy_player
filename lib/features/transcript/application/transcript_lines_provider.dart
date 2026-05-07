/// Reactive subtitle lines for the active primary and secondary transcripts.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database_provider.dart';
import '../../../data/subtitle/transcript_line.dart';

List<TranscriptLine> _decodeLines(String linesJson) {
  final decoded =
      (jsonDecode(linesJson) as List).cast<Map<String, dynamic>>();
  return decoded.map(TranscriptLine.fromJson).toList();
}

/// Lines for the primary (shadow-reading) transcript.
/// Reacts to changes in the active primary transcript ID from the session table.
final transcriptLinesForMediaProvider =
    StreamProvider.family<List<TranscriptLine>, String>((ref, mediaId) {
  final db = ref.watch(appDatabaseProvider);
  return db.sessionDao.watchForMedia(mediaId).asyncExpand((session) {
    final activeId = session?.primaryTranscriptId;
    if (activeId == null) return Stream.value(<TranscriptLine>[]);
    return db.transcriptDao.watchForMedia(mediaId).map((rows) {
      final row = rows.where((r) => r.id == activeId).firstOrNull;
      if (row == null) return <TranscriptLine>[];
      return _decodeLines(row.linesJson);
    });
  });
});

/// Lines for the secondary (translation) transcript.
/// Reacts to changes in the secondary transcript ID from the session table.
final secondaryTranscriptLinesForMediaProvider =
    StreamProvider.family<List<TranscriptLine>, String>((ref, mediaId) {
  final db = ref.watch(appDatabaseProvider);
  return db.sessionDao.watchForMedia(mediaId).asyncExpand((session) {
    final secondaryId = session?.secondaryTranscriptId;
    if (secondaryId == null) return Stream.value(<TranscriptLine>[]);
    return db.transcriptDao.watchForMedia(mediaId).map((rows) {
      final row = rows.where((r) => r.id == secondaryId).firstOrNull;
      if (row == null) return <TranscriptLine>[];
      return _decodeLines(row.linesJson);
    });
  });
});
