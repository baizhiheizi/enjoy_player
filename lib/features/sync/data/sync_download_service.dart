library;

import 'package:enjoy_player/core/json/json_cast.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/data/api/services/audio_api.dart';
import 'package:enjoy_player/data/api/services/recording_api.dart';
import 'package:enjoy_player/data/api/services/video_api.dart';
import 'package:enjoy_player/data/api/services/vocabulary_api.dart';
import 'package:enjoy_player/features/sync/data/sync_serializers.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';

class SyncDownloadService {
  SyncDownloadService({
    required this._db,
    required this._audioApi,
    required this._videoApi,
    required this._recordingApi,
    required this._vocabularyApi,
  });

  final AppDatabase _db;
  final AudioApi _audioApi;
  final VideoApi _videoApi;
  final RecordingApi _recordingApi;
  final VocabularyApi _vocabularyApi;

  static const _pageSize = 50;

  Future<SyncResult> downloadAudios() =>
      _downloadAudiosInternal(resetCursor: false);

  Future<SyncResult> downloadVideos() =>
      _downloadVideosInternal(resetCursor: false);

  Future<SyncResult> downloadRecordings() =>
      _downloadRecordingsInternal(resetCursor: false);

  /// Word-book continuity (ADR-0054): unlike media, vocabulary pulls on
  /// every signed-in sync rather than only via manual "Add to library".
  Future<SyncResult> downloadVocabularyItems() =>
      _downloadVocabularyItemsInternal(resetCursor: false);

  Future<SyncResult> downloadVocabularyContexts() =>
      _downloadVocabularyContextsInternal(resetCursor: false);

  Future<SyncResult> _downloadAudiosInternal({required bool resetCursor}) {
    return _downloadEntityInternal<AudioRow>(
      resetCursor: resetCursor,
      cursorKey: SettingsKeys.syncCursorAudio,
      fetchPage: ({int? limit, String? updatedAfter}) async {
        final raw = await _audioApi.audios(
          limit: limit,
          updatedAfter: updatedAfter,
        );
        return raw.map<Map<String, dynamic>>(castJsonObject).toList();
      },
      getLocal: _db.audioDao.getById,
      insertRow: _db.audioDao.insertRow,
      merge: mergeAudioLastWriteWins,
    );
  }

  Future<SyncResult> _downloadVideosInternal({required bool resetCursor}) {
    return _downloadEntityInternal<VideoRow>(
      resetCursor: resetCursor,
      cursorKey: SettingsKeys.syncCursorVideo,
      fetchPage: ({int? limit, String? updatedAfter}) async {
        final raw = await _videoApi.videos(
          limit: limit,
          updatedAfter: updatedAfter,
        );
        return raw.map<Map<String, dynamic>>(castJsonObject).toList();
      },
      getLocal: _db.videoDao.getById,
      insertRow: _db.videoDao.insertRow,
      merge: mergeVideoLastWriteWins,
    );
  }

  Future<SyncResult> _downloadRecordingsInternal({required bool resetCursor}) {
    return _downloadEntityInternal<RecordingRow>(
      resetCursor: resetCursor,
      cursorKey: SettingsKeys.syncCursorRecording,
      fetchPage: ({int? limit, String? updatedAfter}) async {
        final raw = await _recordingApi.recordings(
          limit: limit,
          updatedAfter: updatedAfter,
        );
        return raw.map<Map<String, dynamic>>(castJsonObject).toList();
      },
      getLocal: _db.recordingDao.getById,
      insertRow: _db.recordingDao.insertRow,
      merge: mergeRecordingLastWriteWins,
    );
  }

  Future<SyncResult> _downloadVocabularyItemsInternal({
    required bool resetCursor,
  }) {
    return _downloadEntityInternal<VocabularyItemRow>(
      resetCursor: resetCursor,
      cursorKey: SettingsKeys.syncCursorVocabularyItem,
      fetchPage: ({int? limit, String? updatedAfter}) async {
        final raw = await _vocabularyApi.vocabularyItems(
          limit: limit,
          updatedAfter: updatedAfter,
        );
        return raw.map<Map<String, dynamic>>(castJsonObject).toList();
      },
      getLocal: _db.vocabularyItemDao.getById,
      // `updateRow` is `InsertMode.replace` — an upsert, unlike `insertRow`
      // (plain insert) which would throw on an existing row from a prior sync.
      insertRow: _db.vocabularyItemDao.updateRow,
      merge: mergeVocabularyItemConflict,
    );
  }

  Future<SyncResult> _downloadVocabularyContextsInternal({
    required bool resetCursor,
  }) {
    return _downloadEntityInternal<VocabularyContextRow>(
      resetCursor: resetCursor,
      cursorKey: SettingsKeys.syncCursorVocabularyContext,
      fetchPage: ({int? limit, String? updatedAfter}) async {
        final raw = await _vocabularyApi.vocabularyContexts(
          limit: limit,
          updatedAfter: updatedAfter,
        );
        return raw.map<Map<String, dynamic>>(castJsonObject).toList();
      },
      getLocal: _db.vocabularyContextDao.getById,
      insertRow: _db.vocabularyContextDao.updateRow,
      merge: mergeVocabularyContextLastWriteWins,
    );
  }

  Future<SyncResult> _downloadEntityInternal<E>({
    required bool resetCursor,
    required String cursorKey,
    required Future<List<Map<String, dynamic>>> Function({
      int? limit,
      String? updatedAfter,
    })
    fetchPage,
    required Future<E?> Function(String id) getLocal,
    required Future<void> Function(E row) insertRow,
    required E Function({
      required E? local,
      required Map<String, dynamic> server,
    })
    merge,
  }) async {
    final errors = <String>[];
    var synced = 0;
    var failed = 0;
    if (resetCursor) {
      await _db.settingsDao.setValue(cursorKey, '');
    }
    var cursor = await _db.settingsDao.getValue(cursorKey);
    if (cursor != null && cursor.isEmpty) cursor = null;

    while (true) {
      List<Map<String, dynamic>> batch;
      try {
        batch = await fetchPage(limit: _pageSize, updatedAfter: cursor);
      } catch (e) {
        return SyncResult(
          success: false,
          synced: synced,
          failed: failed + 1,
          errors: [...errors, '$e'],
        );
      }

      if (batch.isEmpty) break;

      for (final m in batch) {
        try {
          final id = m['id'] as String?;
          if (id == null || id.isEmpty) continue;
          final local = await getLocal(id);
          final merged = merge(local: local, server: m);
          await insertRow(merged);
          synced++;
        } catch (e) {
          failed++;
          errors.add('$e');
        }
      }

      final maxIso = _maxUpdatedAtIso(batch);
      if (maxIso != null) {
        cursor = maxIso;
        await _db.settingsDao.setValue(cursorKey, maxIso);
      }

      if (batch.length < _pageSize) break;
    }

    return SyncResult(
      success: failed == 0,
      synced: synced,
      failed: failed,
      errors: errors.isEmpty ? null : errors,
    );
  }

  Future<SyncResult> downloadAllEntitiesFresh() async {
    final a = await _downloadAudiosInternal(resetCursor: true);
    final v = await _downloadVideosInternal(resetCursor: true);
    final r = await _downloadRecordingsInternal(resetCursor: true);
    final vi = await _downloadVocabularyItemsInternal(resetCursor: true);
    final vc = await _downloadVocabularyContextsInternal(resetCursor: true);
    return a.merge(v).merge(r).merge(vi).merge(vc);
  }
}

String? _maxUpdatedAtIso(List<Map<String, dynamic>> batch) {
  DateTime? max;
  for (final m in batch) {
    final t = parseIsoDate(m['updatedAt']);
    if (t != null && (max == null || t.isAfter(max))) {
      max = t;
    }
  }
  return max?.toUtc().toIso8601String();
}
