/// Incremental downloads for the cloud metadata sync ([SyncEngine]).
///
/// Per-entity cursors go through the typed per-user [SettingsKeys] cursor
/// keys (`settings_schema.dart`), so reset/read/advance below share one
/// declaration per entity instead of raw string rows.
library;

import 'package:enjoy_player/core/json/json_cast.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/data/api/services/audio_api.dart';
import 'package:enjoy_player/data/api/services/recording_api.dart';
import 'package:enjoy_player/data/api/services/video_api.dart';
import 'package:enjoy_player/data/api/services/vocabulary_api.dart';
import 'package:enjoy_player/features/sync/data/sync_serializers.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';

final _log = logNamed('sync.download');

/// Downloads server rows into local Drift tables (paged, cursor-based).
///
/// Accepted bypass of the MediaRegistry seam (issue #723): the generic
/// `_downloadEntityInternal` loop is driven by per-table typed row
/// constructors, DAO callbacks (`getManyByIds` bulk pre-read / `upsertRows`
/// batch write / `getLocal` + `insertRow` per-row fallback / merge), and
/// tombstone handlers, so routing its writes through the registry would
/// just re-branch inside a generic that already knows its entity type.
///
/// Each page costs one `WHERE id IN (…)` read plus one transactional batch
/// upsert (issue #810 D3) instead of two round trips and one commit per row.
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
      getManyByIds: _db.audioDao.getManyByIds,
      getLocal: _db.audioDao.getById,
      upsertRows: _db.audioDao.upsertRows,
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
      getManyByIds: _db.videoDao.getManyByIds,
      getLocal: _db.videoDao.getById,
      upsertRows: _db.videoDao.upsertRows,
      insertRow: _db.videoDao.insertRow,
      merge: mergeVideoLastWriteWins,
      onTombstone: (id) => _db.videoDao.deleteId(id),
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
      getManyByIds: _db.recordingDao.getManyByIds,
      getLocal: _db.recordingDao.getById,
      upsertRows: _db.recordingDao.upsertRows,
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
      getManyByIds: _db.vocabularyItemDao.getManyByIds,
      getLocal: _db.vocabularyItemDao.getById,
      upsertRows: _db.vocabularyItemDao.upsertRows,
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
      getManyByIds: _db.vocabularyContextDao.getManyByIds,
      getLocal: _db.vocabularyContextDao.getById,
      upsertRows: _db.vocabularyContextDao.upsertRows,
      insertRow: _db.vocabularyContextDao.updateRow,
      merge: mergeVocabularyContextLastWriteWins,
    );
  }

  Future<SyncResult> _downloadEntityInternal<E>({
    required bool resetCursor,
    required SettingKey<String?> cursorKey,
    required Future<List<Map<String, dynamic>>> Function({
      int? limit,
      String? updatedAfter,
    })
    fetchPage,
    required Future<Map<String, E>> Function(List<String> ids) getManyByIds,
    required Future<E?> Function(String id) getLocal,
    required Future<void> Function(List<E> rows) upsertRows,
    required Future<void> Function(E row) insertRow,
    required E Function({
      required E? local,
      required Map<String, dynamic> server,
    })
    merge,
    Future<void> Function(String id)? onTombstone,
  }) async {
    final errors = <String>[];
    var synced = 0;
    var failed = 0;
    if (resetCursor) {
      await _db.settingsDao.writeSetting(cursorKey, '');
    }
    var cursor = await _db.settingsDao.readSetting(cursorKey);
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

      final pendingUpserts = <String, Map<String, dynamic>>{};
      for (final m in batch) {
        final id = m['id'] as String?;
        if (id == null || id.isEmpty) continue;
        final deletedAt = m['deletedAt'];
        if (deletedAt != null &&
            deletedAt.toString().isNotEmpty &&
            onTombstone != null) {
          try {
            await onTombstone(id);
            synced++;
          } catch (e) {
            failed++;
            errors.add('$e');
          }
          continue;
        }
        if (pendingUpserts.containsKey(id)) {
          _log.warning(
            'duplicate id "$id" in one server page; keeping the last payload '
            '(last-write-wins, matching the historical per-row path)',
          );
        }
        pendingUpserts[id] = m;
      }

      if (pendingUpserts.isNotEmpty) {
        final counts = await _mergeAndUpsertPage(
          pendingUpserts,
          getManyByIds: getManyByIds,
          getLocal: getLocal,
          upsertRows: upsertRows,
          insertRow: insertRow,
          merge: merge,
        );
        synced += counts.synced;
        failed += counts.failed;
        errors.addAll(counts.errors);
      }

      final maxIso = _maxUpdatedAtIso(batch);
      if (maxIso != null) {
        cursor = maxIso;
        await _db.settingsDao.writeSetting(cursorKey, maxIso);
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

  /// Merges one page of server rows against a single bulk pre-read and
  /// persists the result in one transactional batch. If the bulk read or the
  /// batch fails, falls back to the historical per-row `getLocal` / merge /
  /// `insertRow` path so per-row failures stay isolated (one bad row must
  /// not fail its page neighbors). Merge semantics are unchanged — the
  /// per-entity `merge` callbacks are the same functions the per-row path
  /// uses.
  Future<({int synced, int failed, List<String> errors})>
  _mergeAndUpsertPage<E>(
    Map<String, Map<String, dynamic>> pendingUpserts, {
    required Future<Map<String, E>> Function(List<String> ids) getManyByIds,
    required Future<E?> Function(String id) getLocal,
    required Future<void> Function(List<E> rows) upsertRows,
    required Future<void> Function(E row) insertRow,
    required E Function({
      required E? local,
      required Map<String, dynamic> server,
    })
    merge,
  }) async {
    Map<String, E>? locals;
    try {
      locals = await getManyByIds(pendingUpserts.keys.toList());
    } on Object {
      return _runPerRow<MapEntry<String, Map<String, dynamic>>, E>(
        pendingUpserts.entries,
        lookupLocal: (entry) => getLocal(entry.key),
        insertOne: (entry, local) =>
            insertRow(merge(local: local, server: entry.value)),
      );
    }

    final mergedRows = <E>[];
    final errors = <String>[];
    for (final entry in pendingUpserts.entries) {
      try {
        mergedRows.add(merge(local: locals[entry.key], server: entry.value));
      } catch (e) {
        errors.add('$e');
      }
    }

    try {
      await upsertRows(mergedRows);
      return (synced: mergedRows.length, failed: errors.length, errors: errors);
    } on Object {
      final fallback = await _runPerRow<E, E>(
        mergedRows,
        lookupLocal: (_) async => null,
        insertOne: (row, _) => insertRow(row),
      );
      return (
        synced: fallback.synced,
        failed: errors.length + fallback.failed,
        errors: [...errors, ...fallback.errors],
      );
    }
  }

  /// Runs [insertOne] over [items] one at a time, isolating per-item
  /// failures so one bad row cannot fail its page neighbors. [lookupLocal]
  /// resolves the local row an item merges against (or returns `null` when
  /// the item is already merged).
  Future<({int synced, int failed, List<String> errors})> _runPerRow<T, E>(
    Iterable<T> items, {
    required Future<E?> Function(T item) lookupLocal,
    required Future<void> Function(T item, E? local) insertOne,
  }) async {
    var synced = 0;
    final errors = <String>[];
    for (final item in items) {
      try {
        final local = await lookupLocal(item);
        await insertOne(item, local);
        synced++;
      } catch (e) {
        errors.add('$e');
      }
    }
    return (synced: synced, failed: errors.length, errors: errors);
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
