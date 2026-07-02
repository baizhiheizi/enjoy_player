/// Download remote entities into Drift (metadata only).
library;

import 'package:enjoy_player/core/json/json_cast.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/data/api/services/audio_api.dart';
import 'package:enjoy_player/data/api/services/recording_api.dart';
import 'package:enjoy_player/data/api/services/video_api.dart';
import 'package:enjoy_player/features/sync/data/sync_serializers.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';

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

  Future<SyncResult> _downloadAudiosInternal({
    required bool resetCursor,
  }) async {
    final errors = <String>[];
    var synced = 0;
    var failed = 0;
    if (resetCursor) {
      await _db.settingsDao.setValue(SettingsKeys.syncCursorAudio, '');
    }
    var cursor = await _db.settingsDao.getValue(SettingsKeys.syncCursorAudio);
    if (cursor != null && cursor.isEmpty) cursor = null;

    while (true) {
      List<Map<String, dynamic>> batch;
      try {
        final raw = await _audioApi.audios(
          limit: _pageSize,
          updatedAfter: cursor,
        );
        batch = raw.map<Map<String, dynamic>>(castJsonObject).toList();
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
          final local = await _db.audioDao.getById(id);
          final merged = mergeAudioLastWriteWins(local: local, server: m);
          await _db.audioDao.insertRow(merged);
          synced++;
        } catch (e) {
          failed++;
          errors.add('$e');
        }
      }

      final maxIso = _maxUpdatedAtIso(batch);
      if (maxIso != null) {
        cursor = maxIso;
        await _db.settingsDao.setValue(SettingsKeys.syncCursorAudio, maxIso);
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

  Future<SyncResult> _downloadVideosInternal({
    required bool resetCursor,
  }) async {
    final errors = <String>[];
    var synced = 0;
    var failed = 0;
    if (resetCursor) {
      await _db.settingsDao.setValue(SettingsKeys.syncCursorVideo, '');
    }
    var cursor = await _db.settingsDao.getValue(SettingsKeys.syncCursorVideo);
    if (cursor != null && cursor.isEmpty) cursor = null;

    while (true) {
      List<Map<String, dynamic>> batch;
      try {
        final raw = await _videoApi.videos(
          limit: _pageSize,
          updatedAfter: cursor,
        );
        batch = raw.map<Map<String, dynamic>>(castJsonObject).toList();
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
          final local = await _db.videoDao.getById(id);
          final merged = mergeVideoLastWriteWins(local: local, server: m);
          await _db.videoDao.insertRow(merged);
          synced++;
        } catch (e) {
          failed++;
          errors.add('$e');
        }
      }

      final maxIso = _maxUpdatedAtIso(batch);
      if (maxIso != null) {
        cursor = maxIso;
        await _db.settingsDao.setValue(SettingsKeys.syncCursorVideo, maxIso);
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

  Future<SyncResult> _downloadRecordingsInternal({
    required bool resetCursor,
  }) async {
    final errors = <String>[];
    var synced = 0;
    var failed = 0;
    if (resetCursor) {
      await _db.settingsDao.setValue(SettingsKeys.syncCursorRecording, '');
    }
    var cursor = await _db.settingsDao.getValue(
      SettingsKeys.syncCursorRecording,
    );
    if (cursor != null && cursor.isEmpty) cursor = null;

    while (true) {
      List<Map<String, dynamic>> batch;
      try {
        final raw = await _recordingApi.recordings(
          limit: _pageSize,
          updatedAfter: cursor,
        );
        batch = raw.map<Map<String, dynamic>>(castJsonObject).toList();
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
          final local = await _db.recordingDao.getById(id);
          final merged = mergeRecordingLastWriteWins(local: local, server: m);
          await _db.recordingDao.insertRow(merged);
          synced++;
        } catch (e) {
          failed++;
          errors.add('$e');
        }
      }

      final maxIso = _maxUpdatedAtIso(batch);
      if (maxIso != null) {
        cursor = maxIso;
        await _db.settingsDao.setValue(
          SettingsKeys.syncCursorRecording,
          maxIso,
        );
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
