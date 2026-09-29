import 'dart:async';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/api/services/ai/youtube_transcripts_api.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/media_registry.dart';
import 'package:enjoy_player/features/sync/data/sync_download_service.dart';
import 'package:enjoy_player/features/sync/data/sync_queue_repository.dart';
import 'package:enjoy_player/features/sync/data/sync_upload_service.dart';
import 'package:enjoy_player/features/sync/domain/sync_queue_job.dart';
import 'package:enjoy_player/features/sync/domain/sync_retry_policy.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';

final _log = logNamed('sync');

/// Prefer deletes before creates/updates for the same entity so a
/// delete-then-reimport cannot race cloud DELETE with POST.
int syncActionProcessOrder(String action) => switch (action) {
  'delete' => 0,
  'update' => 1,
  'create' => 2,
  _ => 3,
};

void sortSyncQueueWork(List<SyncQueueRow> work) {
  work.sort((a, b) {
    final typeCmp = a.entityType.compareTo(b.entityType);
    if (typeCmp != 0) return typeCmp;
    final idCmp = a.entityId.compareTo(b.entityId);
    if (idCmp != 0) return idCmp;
    final actionCmp = syncActionProcessOrder(
      a.action,
    ).compareTo(syncActionProcessOrder(b.action));
    if (actionCmp != 0) return actionCmp;
    return a.createdAt.compareTo(b.createdAt);
  });
}

class SyncEngine {
  SyncEngine({
    required this._db,
    required this._queue,
    required this._upload,
    required this._download,
    required this._youtubeTranscripts,
    SyncRetryPolicy? retryPolicy,
  }) : _retryPolicy = retryPolicy ?? SyncRetryPolicy();

  final AppDatabase _db;
  final SyncQueueRepository _queue;
  final SyncUploadService _upload;
  final SyncDownloadService _download;
  final YoutubeTranscriptsClient _youtubeTranscripts;

  /// Threshold, backoff, and clock for every retry decision in the drain
  /// (issue #752). Injectable so tests can pin wall time.
  final SyncRetryPolicy _retryPolicy;

  Completer<SyncResult>? _drainGate;
  var _drainAgain = false;
  var _resetFailedPending = false;

  Future<SyncResult> fullSync(SyncOptions options) async {
    final results = await Future.wait([
      processQueue(options),
      pullVocabulary(),
    ]);
    return results[0].merge(results[1]);
  }

  /// Pulls vocabulary items + contexts (ADR-0054 auto-pull exception).
  ///
  /// Items + contexts are independent — fetched concurrently (issue #481).
  Future<SyncResult> pullVocabulary() async {
    final results = await Future.wait([
      _download.downloadVocabularyItems(),
      _download.downloadVocabularyContexts(),
    ]);
    return results[0].merge(results[1]);
  }

  /// Drains the outbound sync queue.
  ///
  /// Concurrent callers coalesce onto one in-flight drain (plus one follow-up
  /// pass if enqueue happened while draining).
  Future<SyncResult> processQueue(SyncOptions options) async {
    if (options.resetFailed) {
      _resetFailedPending = true;
    }

    final existing = _drainGate;
    if (existing != null) {
      _drainAgain = true;
      return existing.future;
    }

    final gate = Completer<SyncResult>();
    _drainGate = gate;

    try {
      SyncResult? last;
      do {
        _drainAgain = false;
        final resetFailed = _resetFailedPending;
        _resetFailedPending = false;
        last = await _drainOnce(SyncOptions(resetFailed: resetFailed));
      } while (_drainAgain);
      gate.complete(last);
      return last;
    } catch (e, st) {
      if (!gate.isCompleted) {
        gate.completeError(e, st);
      }
      rethrow;
    } finally {
      _drainGate = null;
    }
  }

  Future<SyncResult> _drainOnce(SyncOptions options) async {
    if (options.resetFailed) {
      final n = await _queue.resetFailed();
      if (n > 0) {
        _log.info('reset $n failed sync queue items');
      }
    }

    final pending = await _queue.pendingItems();
    final work = pending
        .where((row) => SyncEntityTypeWire.tryParse(row.entityType) != null)
        .where(_retryPolicy.backoffElapsed)
        .toList();
    sortSyncQueueWork(work);

    var synced = 0;
    var failed = 0;

    for (final item in work) {
      final ok = await _processOne(item);
      if (ok) {
        synced++;
      } else {
        failed++;
      }
    }

    return SyncResult(success: failed == 0, synced: synced, failed: failed);
  }

  Future<bool> _processYoutubeUploadRetry(
    SyncYoutubeUploadRetry retry,
    SyncQueueRow item,
  ) async {
    await retry.processRetry(
      rowId: item.id,
      upload: retry.toUploadCall(_youtubeTranscripts),
      removeByIdIfPayload: _queue.removeByIdIfPayload,
    );
    _log.info(
      'youtube_upload retry accepted for ${retry.videoId}/${retry.language} '
      '(source=${retry.source}, ${retry.timeline.length} lines)',
    );
    return true;
  }

  Future<void> _dropQueueRow(SyncQueueRow item) async {
    if (item.payloadJson == null) {
      await _queue.removeById(item.id);
    } else {
      await _queue.removeByIdIfPayload(item.id, item.payloadJson!);
    }
  }

  Future<bool> _processOne(SyncQueueRow item) async {
    final job = SyncQueueJob.decode(item);
    if (job == null) {
      _log.warning(
        'sync ${item.entityType}:${item.entityId} ${item.action}: '
        'undecodable queue row, drop',
      );
      await _dropQueueRow(item);
      return true;
    }

    try {
      switch (job) {
        case SyncAudioDelete(:final id):
          await _upload.deleteAudio(id);
        case SyncVideoDelete(:final id):
          await _upload.deleteVideo(id);
        case SyncRecordingDelete(:final id):
          await _upload.deleteRecording(id);
        case SyncYoutubeSubscriptionDelete():
          break;
        case SyncVocabularyItemDelete(:final id):
          await _upload.deleteVocabularyItem(id);
        case SyncVocabularyContextDelete(:final id):
          await _upload.deleteVocabularyContext(id);

        case SyncAudioUpsert(:final id):
          final row = await MediaRegistry(_db).getAudioById(id);
          if (row == null) {
            _log.warning('sync audio $id: missing locally, drop queue row');
            await _queue.removeById(item.id);
            return true;
          }
          await _upload.uploadAudio(row);
        case SyncVideoUpsert(:final id):
          final row = await MediaRegistry(_db).getVideoById(id);
          if (row == null) {
            final retry = await SyncQueueJob.decodeYoutubeUploadRetry(
              item.payloadJson,
            );
            if (retry == null) {
              _log.warning('sync video $id: missing locally, drop queue row');
              await _dropQueueRow(item);
              return true;
            }
            return await _processYoutubeUploadRetry(retry, item);
          }
          await _upload.uploadVideo(row);
        case SyncRecordingUpsert(:final id):
          final row = await _db.recordingDao.getById(id);
          if (row == null) {
            _log.warning('sync recording $id: missing locally, drop queue row');
            await _queue.removeById(item.id);
            return true;
          }
          await _upload.uploadRecording(row);
        case SyncVocabularyItemUpsert(:final id):
          final row = await _db.vocabularyItemDao.getById(id);
          if (row == null) {
            _log.warning(
              'sync vocabulary item $id: missing locally, drop queue row',
            );
            await _queue.removeById(item.id);
            return true;
          }
          await _upload.uploadVocabularyItem(row);
        case SyncVocabularyContextUpsert(:final id):
          final row = await _db.vocabularyContextDao.getById(id);
          if (row == null) {
            _log.warning(
              'sync vocabulary context $id: missing locally, drop queue row',
            );
            await _queue.removeById(item.id);
            return true;
          }
          await _upload.uploadVocabularyContext(row);
        case SyncYoutubeSubscriptionUpsert():
          break;

        case SyncYoutubeUploadRetry():
          return await _processYoutubeUploadRetry(job, item);
      }

      await _queue.removeById(item.id);
      return true;
    } on SyncDuplicateMissingError catch (e, st) {
      _log.warning(
        'sync permanently failed ${item.entityType}:${item.entityId} '
        '${item.action} (duplicate create but GET 404)',
        e,
        st,
      );
      try {
        await _queue.markPermanentlyFailed(item.id, error: '$e');
      } catch (markError, markSt) {
        _log.warning(
          'sync markPermanentlyFailed failed for queue ${item.id}',
          markError,
          markSt,
        );
      }
      return false;
    } catch (e, st) {
      _log.warning(
        'sync failed ${item.entityType}:${item.entityId} ${item.action}',
        e,
        st,
      );
      try {
        await _queue.markAttempted(item.id, error: '$e');
      } catch (markError, markSt) {
        _log.warning(
          'sync markAttempted failed for queue ${item.id}',
          markError,
          markSt,
        );
      }
      return false;
    }
  }
}
