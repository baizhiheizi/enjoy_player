/// Download remote entities into Drift (metadata only).
library;

import 'package:enjoy_player/core/json/json_cast.dart';
import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/data/api/services/audio_api.dart';
import 'package:enjoy_player/data/api/services/recording_api.dart';
import 'package:enjoy_player/data/api/services/video_api.dart';
import 'package:enjoy_player/features/sync/data/sync_serializers.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';

typedef _FetchPage =
    Future<List<JsonMap>> Function({int? limit, String? updatedAfter});

typedef _UpsertRow =
    Future<void> Function({required String id, required JsonMap server});

class SyncDownloadService {
  SyncDownloadService({
    required this._db,
    required this._audioApi,
    required this._videoApi,
    required this._recordingApi,
  });

  final AppDatabase _db;
  final AudioApi _audioApi;
  final VideoApi _videoApi;
  final RecordingApi _recordingApi;

  static const _pageSize = 50;

  Future<SyncResult> downloadAudios() =>
      _downloadAudiosInternal(resetCursor: false);

  Future<SyncResult> downloadVideos() =>
      _downloadVideosInternal(resetCursor: false);

  Future<SyncResult> downloadRecordings() =>
      _downloadRecordingsInternal(resetCursor: false);

  Future<SyncResult> _downloadAudiosInternal({required bool resetCursor}) {
    return _downloadEntityInternal(
      resetCursor: resetCursor,
      cursorKey: SettingsKeys.syncCursorAudio,
      fetch: _audioApi.audios,
      upsert: ({required String id, required JsonMap server}) async {
        final local = await _db.audioDao.getById(id);
        final merged = mergeAudioLastWriteWins(local: local, server: server);
        await _db.audioDao.insertRow(merged);
      },
    );
  }

  Future<SyncResult> _downloadVideosInternal({required bool resetCursor}) {
    return _downloadEntityInternal(
      resetCursor: resetCursor,
      cursorKey: SettingsKeys.syncCursorVideo,
      fetch: _videoApi.videos,
      upsert: ({required String id, required JsonMap server}) async {
        final local = await _db.videoDao.getById(id);
        final merged = mergeVideoLastWriteWins(local: local, server: server);
        await _db.videoDao.insertRow(merged);
      },
    );
  }

  Future<SyncResult> _downloadRecordingsInternal({required bool resetCursor}) {
    return _downloadEntityInternal(
      resetCursor: resetCursor,
      cursorKey: SettingsKeys.syncCursorRecording,
      fetch: _recordingApi.recordings,
      upsert: ({required String id, required JsonMap server}) async {
        final local = await _db.recordingDao.getById(id);
        final merged = mergeRecordingLastWriteWins(
          local: local,
          server: server,
        );
        await _db.recordingDao.insertRow(merged);
      },
    );
  }

  Future<SyncResult> _downloadEntityInternal({
    required bool resetCursor,
    required String cursorKey,
    required _FetchPage fetch,
    required _UpsertRow upsert,
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
      List<JsonMap> batch;
      try {
        final raw = await fetch(limit: _pageSize, updatedAfter: cursor);
        batch = raw.map<JsonMap>(castJsonObject).toList();
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
          await upsert(id: id, server: m);
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

  /// Full download pass resets cursors then pulls everything page by page.
  Future<SyncResult> downloadAllEntitiesFresh() async {
    final a = await _downloadAudiosInternal(resetCursor: true);
    final v = await _downloadVideosInternal(resetCursor: true);
    final r = await _downloadRecordingsInternal(resetCursor: true);
    return a.merge(v).merge(r);
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
