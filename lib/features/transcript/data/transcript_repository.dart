/// Persist imported subtitles for a media item.
library;

import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../data/db/app_database.dart';
import '../../../data/subtitle/subtitle_parser.dart';

class TranscriptRepository {
  TranscriptRepository(this._db);

  // ignore: prefer_const_constructors
  static final Uuid _uuid = Uuid();

  final AppDatabase _db;

  Future<void> importSubtitle({
    required String mediaId,
    required XFile file,
    String? label,
  }) async {
    final text = await file.readAsString();
    final lines = const SubtitleParserFacade().parseWithHint(
      text,
      fileName: file.name,
    );
    final json = jsonEncode(lines.map((e) => e.toJson()).toList());
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.transcriptDao.upsert(
      TranscriptRow(
        id: id,
        mediaId: mediaId,
        language: 'und',
        source: 'import',
        linesJson: json,
        label: label ?? p.basenameWithoutExtension(file.name),
        trackIndex: null,
        isEmbedded: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
    // Auto-select as primary if none is set yet.
    final session = await _db.sessionDao.getForMedia(mediaId);
    if (session?.primaryTranscriptId == null) {
      await _db.sessionDao.updatePrimaryTranscript(mediaId, id);
    }
  }

  /// Upserts pre-built rows extracted from the media container.
  Future<void> upsertEmbeddedTracks(List<TranscriptRow> rows) async {
    for (final row in rows) {
      await _db.transcriptDao.upsert(row);
    }
  }

  Future<void> setActiveTranscript(String mediaId, String transcriptId) =>
      _db.sessionDao.updatePrimaryTranscript(mediaId, transcriptId);

  Future<void> setSecondaryTranscript(String mediaId, String? transcriptId) =>
      _db.sessionDao.updateSecondaryTranscript(mediaId, transcriptId);

  Future<void> deleteTranscript(String transcriptId) =>
      _db.transcriptDao.deleteId(transcriptId);
}
