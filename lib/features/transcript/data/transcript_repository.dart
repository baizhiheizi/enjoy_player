/// Persist imported subtitles for a media item.
library;

import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../data/db/app_database.dart';
import '../../../data/subtitle/subtitle_parser.dart';
import '../../../data/subtitle/transcript_line.dart';
import '../domain/transcript_track.dart';

class _LinesCacheEntry {
  _LinesCacheEntry(this.updatedAt, this.lines);
  final DateTime updatedAt;
  final List<TranscriptLine> lines;
}

List<TranscriptLine> _decodeLines(String linesJson) {
  final decoded =
      (jsonDecode(linesJson) as List).cast<Map<String, dynamic>>();
  return decoded.map(TranscriptLine.fromJson).toList();
}

TranscriptTrack _trackFromRow(TranscriptRow row) {
  return TranscriptTrack(
    id: row.id,
    mediaId: row.mediaId,
    language: row.language,
    source: row.source,
    label: row.label,
    isEmbedded: row.isEmbedded,
    trackIndex: row.trackIndex,
  );
}

class TranscriptRepository {
  TranscriptRepository(this._db);

  // ignore: prefer_const_constructors
  static final Uuid _uuid = Uuid();

  final AppDatabase _db;

  final Map<String, _LinesCacheEntry> _linesCache = {};

  /// Decodes [row.linesJson] with memoization on `(id, updatedAt)`.
  List<TranscriptLine> linesForRow(TranscriptRow row) {
    final hit = _linesCache[row.id];
    if (hit != null && hit.updatedAt == row.updatedAt) return hit.lines;
    final decoded = _decodeLines(row.linesJson);
    _linesCache[row.id] = _LinesCacheEntry(row.updatedAt, decoded);
    return decoded;
  }

  Future<List<TranscriptLine>> linesForTranscriptId(String transcriptId) async {
    final row = await _db.transcriptDao.getById(transcriptId);
    if (row == null) return [];
    return linesForRow(row);
  }

  Future<TranscriptRow?> primaryTranscriptRowForMedia(String mediaId) async {
    final playback = await _db.sessionDao.getForMedia(mediaId);
    final id = playback?.primaryTranscriptId;
    if (id == null) return null;
    return _db.transcriptDao.getById(id);
  }

  Stream<List<TranscriptTrack>> watchTracks(String mediaId) =>
      _db.transcriptDao.watchAllForMedia(mediaId).map(
            (rows) => rows.map(_trackFromRow).toList(),
          );

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

  Future<void> deleteTranscript(String transcriptId) async {
    _linesCache.remove(transcriptId);
    await _db.transcriptDao.deleteId(transcriptId);
  }
}
