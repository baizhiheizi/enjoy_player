/// Pull recording metadata for one library media target (lazy sync).
///
/// The per-target cursor and cooldown rows go through the typed
/// [SettingsKeys.syncCursorRecordingTargets] /
/// [SettingsKeys.syncLastPullAtRecordingTargets] families (per-user DB); the
/// cooldown is decoded by the family's ISO date-time codec.
library;

import 'package:enjoy_player/core/json/json_cast.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/api/services/recording_api.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/sync/data/sync_page_upsert.dart';
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
    final cursorKey = SettingsKeys.syncCursorRecordingTargets.keyFor(
      '$targetType.$targetId',
    );
    final cooldownKey = SettingsKeys.syncLastPullAtRecordingTargets.keyFor(
      '$targetType.$targetId',
    );

    final clock = now ?? DateTime.now();
    final lastPull = await _db.settingsDao.readSetting(cooldownKey);
    if (lastPull != null && clock.toUtc().difference(lastPull) < _kCooldown) {
      _log.fine(
        'pullRecordingsForTarget($targetType:$targetId): skipped, '
        'cooldown active (last pull $lastPull, now $clock)',
      );
      return const SyncResult(success: true, synced: 0, failed: 0);
    }

    var fetchFailed = false;
    final result = await downloadPagedEntities<RecordingRow>(
      settingsDao: _db.settingsDao,
      cursorKey: cursorKey,
      pageSize: _pageSize,
      maxPages: _kMaxPagesPerCall,
      fetchPage: ({int? limit, String? updatedAfter}) async {
        try {
          final raw = await _recordingApi.recordings(
            limit: limit,
            updatedAfter: updatedAfter,
            targetId: targetId,
            targetType: targetType,
          );
          return raw.map<Map<String, dynamic>>(castJsonObject).toList();
        } catch (e) {
          fetchFailed = true;
          rethrow;
        }
      },
      getManyByIds: _db.recordingDao.getManyByIds,
      getLocal: _db.recordingDao.getById,
      upsertRows: _db.recordingDao.upsertRows,
      insertRow: _db.recordingDao.insertRow,
      merge: mergeRecordingLastWriteWins,
      onPageCapReached: () {
        _log.info(
          'pullRecordingsForTarget($targetType:$targetId): hit page cap '
          '($_kMaxPagesPerCall × $_pageSize), will resume from cursor on '
          'next call',
        );
      },
      log: _log,
    );

    if (!fetchFailed) {
      await _db.settingsDao.writeSetting(cooldownKey, clock.toUtc());
    }

    return result;
  }
}
