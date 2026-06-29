/// Pull recording metadata for one library media target (lazy sync).
library;

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/api/services/recording_api.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/sync/data/sync_serializers.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';

final _log = logNamed('recordingTargetSync');

class RecordingTargetSyncService {
  RecordingTargetSyncService({required this._db, required this._recordingApi});

  final AppDatabase _db;
  final RecordingApi _recordingApi;

  /// Page size for the upstream recordings API. Each request returns at
  /// most this many rows; the consumer paginates with a cursor.
  static const _pageSize = 50;

  /// Hard cap on pages per call. A user with thousands of recordings
  /// will not have all of them pulled in a single media-open; the next
  /// open resumes from the persisted cursor. Combined with the
  /// [_kCooldown], this prevents `pullRecordingsForTarget` from
  /// hammering the server on every media open.
  static const _kMaxPagesPerCall = 5;

  /// Minimum interval between pulls for the same (targetType, targetId)
  /// pair. Subsequent calls inside the cooldown window short-circuit to
  /// an empty success.
  static const _kCooldown = Duration(minutes: 5);

  Future<SyncResult> pullRecordingsForTarget({
    required String targetType,
    required String targetId,
    DateTime? now,
  }) async {
    final errors = <String>[];
    var synced = 0;
    var failed = 0;
    final cursorKey = SettingsKeys.syncCursorRecordingTarget(
      targetType,
      targetId,
    );
    final cooldownKey = SettingsKeys.syncLastPullAtRecordingTarget(
      targetType,
      targetId,
    );

    // Cooldown: short-circuit when we just pulled for this target.
    final clock = now ?? DateTime.now();
    final lastPullRaw = await _db.settingsDao.getValue(cooldownKey);
    final lastPull = lastPullRaw == null
        ? null
        : DateTime.tryParse(lastPullRaw)?.toUtc();
    if (lastPull != null && clock.toUtc().difference(lastPull) < _kCooldown) {
      _log.fine(
        'pullRecordingsForTarget($targetType:$targetId): skipped, '
        'cooldown active (last pull $lastPull, now $clock)',
      );
      return const SyncResult(success: true, synced: 0, failed: 0);
    }

    var cursor = await _db.settingsDao.getValue(cursorKey);
    if (cursor != null && cursor.isEmpty) cursor = null;

    var pages = 0;
    while (pages < _kMaxPagesPerCall) {
      pages++;
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
        await _db.settingsDao.setValue(cursorKey, maxIso);
      }

      if (batch.length < _pageSize) break;
    }

    if (pages >= _kMaxPagesPerCall) {
      _log.info(
        'pullRecordingsForTarget($targetType:$targetId): hit page cap '
        '($_kMaxPagesPerCall × $_pageSize), will resume from cursor on '
        'next call',
      );
    }

    // Persist the cooldown timestamp even on partial success so a
    // future open inside the cooldown window does not re-enter the
    // pagination loop.
    await _db.settingsDao.setValue(
      cooldownKey,
      clock.toUtc().toIso8601String(),
    );

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
