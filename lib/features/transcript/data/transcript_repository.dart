/// Persist imported subtitles for a media item.
library;

import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:logging/logging.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:path/path.dart' as p;

import '../../../core/ids/enjoy_ids.dart';
import '../../../core/logging/log.dart';
import '../../../data/api/services/transcript_api.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/media_target_resolver.dart';
import '../../../data/subtitle/embedded_subtitle_service.dart';
import '../../../data/subtitle/subtitle_parser.dart';
import '../../../data/subtitle/transcript_line.dart';
import '../domain/transcript_track.dart';
import 'transcript_timeline_parse.dart';

class _LinesCacheEntry {
  _LinesCacheEntry(this.updatedAt, this.lines);
  final DateTime updatedAt;
  final List<TranscriptLine> lines;
}

List<TranscriptLine> _decodeTimeline(String timelineJson) {
  final decoded =
      (jsonDecode(timelineJson) as List).cast<Map<String, dynamic>>();
  return decoded.map(TranscriptLine.fromJson).toList();
}

TranscriptTrack _trackFromRow(TranscriptRow row) {
  return TranscriptTrack(
    id: row.id,
    targetType: row.targetType,
    targetId: row.targetId,
    language: row.language,
    source: row.source,
    label: row.label,
    trackIndex: row.trackIndex,
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

class TranscriptRepository {
  TranscriptRepository(this._db, [this._transcriptApi]);

  final AppDatabase _db;
  final TranscriptApi? _transcriptApi;

  final Map<String, _LinesCacheEntry> _linesCache = {};

  /// Decodes [row.timelineJson] with memoization on `(id, updatedAt)`.
  List<TranscriptLine> linesForRow(TranscriptRow row) {
    final hit = _linesCache[row.id];
    if (hit != null && hit.updatedAt == row.updatedAt) return hit.lines;
    final decoded = _decodeTimeline(row.timelineJson);
    _linesCache[row.id] = _LinesCacheEntry(row.updatedAt, decoded);
    return decoded;
  }

  Future<TranscriptRow?> primaryTranscriptRowForMedia(String mediaId) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) return null;
    final echo = await _db.echoSessionDao.getLatestForTarget(tt, mediaId);
    final id = echo?.transcriptId;
    if (id == null) return null;
    return _db.transcriptDao.getById(id);
  }

  Stream<List<TranscriptTrack>> watchTracks(String mediaId) =>
      Stream.fromFuture(dexieTargetTypeForId(_db, mediaId)).asyncExpand((tt) {
        if (tt == null) {
          return Stream.value(<TranscriptTrack>[]);
        }
        return _db.transcriptDao.watchAllForTarget(tt, mediaId).map((rows) {
          final sorted = [...rows];
          _sortTranscriptRows(sorted);
          return sorted.map(_trackFromRow).toList();
        });
      });

  /// Fetches transcripts from the Enjoy API and upserts them locally.
  ///
  /// When [force] is false, skips if this target was already fetched once
  /// ([TranscriptFetchStates]). On success, marks fetch state. Errors are
  /// logged and do not mark fetched (so the next open can retry).
  Future<void> fetchCloudTranscripts(
    String mediaId, {
    bool force = false,
  }) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) return;
    final api = _transcriptApi;
    if (api == null) return;

    if (!force) {
      final state = await _db.transcriptFetchStateDao.getForTarget(tt, mediaId);
      if (state != null) return;
    }

    try {
      final list = await api.transcripts(targetId: mediaId, targetType: tt);
      final now = DateTime.now();
      var storedCount = 0;
      for (final item in list) {
        final row = _transcriptRowFromServerMap(item, fallbackNow: now);
        if (row == null) continue;
        await _db.transcriptDao.upsert(row);
        storedCount++;
      }

      // Do not mark "fetched" if the server returned transcript rows we could not
      // persist (e.g. shape mismatch); allows retry on next play.
      if (list.isEmpty || storedCount > 0) {
        await _db.transcriptFetchStateDao.upsertFetched(tt, mediaId, now);
      }

      final session = await _db.echoSessionDao.getLatestForTarget(tt, mediaId);
      if (session?.transcriptId == null && storedCount > 0) {
        final rows = await _db.transcriptDao.listForTarget(tt, mediaId);
        _sortTranscriptRows(rows);
        if (rows.isNotEmpty) {
          await _db.echoSessionDao.updatePrimaryTranscriptForTarget(
            tt,
            mediaId,
            rows.first.id,
          );
        }
      }
    } on Object catch (e, st) {
      _log.warning('fetchCloudTranscripts failed for $mediaId', e, st);
    }
  }

  TranscriptRow? _transcriptRowFromServerMap(
    Map<String, dynamic> json, {
    required DateTime fallbackNow,
  }) {
    final id = json['id'] as String?;
    final targetType = json['targetType'] as String?;
    final targetId = json['targetId'] as String?;
    final language = json['language'] as String?;
    final rawSource = json['source'] as String?;
    final timeline = json['timeline'];

    if (id == null ||
        targetType == null ||
        targetId == null ||
        language == null ||
        rawSource == null) {
      return null;
    }

    final source = _normalizeSource(rawSource);
    final lines = transcriptLinesFromApiTimeline(timeline);
    if (lines.isEmpty) return null;

    final timelineJson = jsonEncode(lines.map((e) => e.toJson()).toList());
    final createdAt = _parseServerDate(json['createdAt'], fallbackNow);
    final updatedAt = _parseServerDate(json['updatedAt'], fallbackNow);
    final label = (json['label'] as String?) ?? '';
    final referenceId = json['referenceId'] as String?;

    return TranscriptRow(
      id: id,
      targetType: targetType,
      targetId: targetId,
      language: language,
      source: source,
      timelineJson: timelineJson,
      referenceId: referenceId,
      label: label,
      trackIndex: null,
      syncStatus: 'synced',
      serverUpdatedAt: updatedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Future<void> importSubtitle({
    required String mediaId,
    required XFile file,
    required String language,
    String? label,
  }) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) return;
    final text = await file.readAsString();
    final lines = const SubtitleParserFacade().parseWithHint(
      text,
      fileName: file.name,
    );
    final json = jsonEncode(lines.map((e) => e.toJson()).toList());
    const source = 'user';
    final id = enjoyTranscriptId(
      targetType: tt,
      targetId: mediaId,
      language: language,
      source: source,
    );
    final now = DateTime.now();
    await _db.transcriptDao.upsert(
      TranscriptRow(
        id: id,
        targetType: tt,
        targetId: mediaId,
        language: language,
        source: source,
        timelineJson: json,
        referenceId: null,
        label: label ?? p.basenameWithoutExtension(file.name),
        trackIndex: null,
        syncStatus: 'local',
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final session = await _db.echoSessionDao.getLatestForTarget(tt, mediaId);
    if (session?.transcriptId == null) {
      await _db.echoSessionDao.updatePrimaryTranscriptForTarget(tt, mediaId, id);
    }
  }

  /// Extracts embedded subtitle streams via ffmpeg; stored as `source: user`.
  ///
  /// Returns the number of new/updated transcript rows written.
  ///
  /// [playerSubtitleTracks] may be empty: subtitle streams are then discovered
  /// via `ffmpeg -i` (see [EmbeddedSubtitleService.extractTracks]).
  Future<int> extractEmbeddedTracks({
    required String mediaId,
    required String sourceUri,
    List<mk.SubtitleTrack> playerSubtitleTracks = const [],
  }) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) return 0;

    final existing = await _db.transcriptDao.listForTarget(tt, mediaId);
    final existingIndices =
        existing
            .where((r) => r.trackIndex != null)
            .map((r) => r.trackIndex!)
            .toSet();

    final extracted = await const EmbeddedSubtitleService().extractTracks(
      targetId: mediaId,
      targetTypeDexie: tt,
      mediaSourceUri: sourceUri,
      tracks: playerSubtitleTracks,
      existingTrackIndices: existingIndices,
    );

    if (extracted.isEmpty) return 0;

    for (final row in extracted) {
      await _db.transcriptDao.upsert(row);
    }

    final session = await _db.echoSessionDao.getLatestForTarget(tt, mediaId);
    if (session?.transcriptId == null) {
      await _db.echoSessionDao.updatePrimaryTranscriptForTarget(
        tt,
        mediaId,
        extracted.first.id,
      );
    }

    return extracted.length;
  }

  Future<void> setActiveTranscript(String mediaId, String transcriptId) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) return;
    await _db.echoSessionDao.updatePrimaryTranscriptForTarget(
      tt,
      mediaId,
      transcriptId,
    );
  }

  Future<void> setSecondaryTranscript(String mediaId, String? transcriptId) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) return;
    await _db.echoSessionDao.updateSecondaryTranscriptForTarget(
      tt,
      mediaId,
      transcriptId,
    );
  }

  Future<void> deleteTranscript(String transcriptId) async {
    final row = await _db.transcriptDao.getById(transcriptId);
    if (row == null) return;

    final targetType = row.targetType;
    final targetId = row.targetId;
    final session = await _db.echoSessionDao.getLatestForTarget(
      targetType,
      targetId,
    );

    _linesCache.remove(transcriptId);
    await _db.transcriptDao.deleteId(transcriptId);

    if (session == null) return;

    var newPrimary = session.transcriptId;
    var newSecondary = session.secondaryTranscriptId;

    if (session.transcriptId == transcriptId) {
      newPrimary = await _nextPrimaryAfterDelete(targetType, targetId);
    }
    if (session.secondaryTranscriptId == transcriptId) {
      newSecondary = null;
    }
    if (newPrimary != null && newSecondary == newPrimary) {
      newSecondary = null;
    }

    if (newPrimary != session.transcriptId) {
      await _db.echoSessionDao.updatePrimaryTranscriptForTarget(
        targetType,
        targetId,
        newPrimary,
      );
    }
    if (newSecondary != session.secondaryTranscriptId) {
      await _db.echoSessionDao.updateSecondaryTranscriptForTarget(
        targetType,
        targetId,
        newSecondary,
      );
    }
  }

  /// Picks the next primary transcript for [targetId] after delete:
  /// [official] > [auto] > [ai] > [user], then earliest [createdAt].
  Future<String?> _nextPrimaryAfterDelete(
    String targetType,
    String targetId,
  ) async {
    final remaining = await _db.transcriptDao.listForTarget(
      targetType,
      targetId,
    );
    if (remaining.isEmpty) return null;
    _sortTranscriptRows(remaining);
    return remaining.first.id;
  }
}
