/// Pull recording metadata for one library media target (lazy sync).
library;

import 'package:enjoy_player/data/api/services/recording_api.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/sync/data/sync_serializers.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';

class RecordingTargetSyncService {
  RecordingTargetSyncService({
    required AppDatabase db,
    required RecordingApi recordingApi,
  })  : _db = db,
        _recordingApi = recordingApi;

  final AppDatabase _db;
  final RecordingApi _recordingApi;

  static const _pageSize = 50;

  Future<SyncResult> pullRecordingsForTarget({
    required String targetType,
    required String targetId,
  }) async {
    final errors = <String>[];
    var synced = 0;
    var failed = 0;
    final key = SettingsKeys.syncCursorRecordingTarget(targetType, targetId);
    var cursor = await _db.settingsDao.getValue(key);
    if (cursor != null && cursor.isEmpty) cursor = null;

    while (true) {
      List<Map<String, dynamic>> batch;
      try {
        final raw = await _recordingApi.recordings(
          limit: _pageSize,
          updatedAfter: cursor,
          targetId: targetId,
          targetType: targetType,
        );
        batch = raw.map<Map<String, dynamic>>(_asJsonMap).toList();
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
        await _db.settingsDao.setValue(key, maxIso);
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
}

Map<String, dynamic> _asJsonMap(Object? e) {
  if (e is Map<String, dynamic>) return e;
  if (e is Map) return Map<String, dynamic>.from(e);
  throw FormatException('Expected JSON object, got ${e.runtimeType}');
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
