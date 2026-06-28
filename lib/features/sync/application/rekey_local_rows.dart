/// On sign-in, rewrite media rows imported while signed out so `aid`/`vid` match web
/// (`sha256(contentHash:userId)`), then update dependent tables.
library;

import 'package:drift/drift.dart';

import 'package:enjoy_player/core/ids/enjoy_ids.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';

final _log = logNamed('rekey');

Future<void> rekeyLocalMediaRowsOnSignIn({
  required AppDatabase db,
  required String userId,
  SyncEnqueueFn? enqueue,
}) async {
  if (userId.isEmpty) return;

  final videos = await (db.select(
    db.videos,
  )..where((t) => t.syncStatus.equals('local-pending-rekey'))).get();
  final audios = await (db.select(
    db.audios,
  )..where((t) => t.syncStatus.equals('local-pending-rekey'))).get();
  if (videos.isEmpty && audios.isEmpty) return;

  // Single transaction → one Drift change notification batch vs N per-row txns.
  await db.transaction(() async {
    for (final row in videos) {
      try {
        await _rekeyOneVideo(db, row, userId, enqueue);
      } catch (e, st) {
        _log.warning('rekey video ${row.id} failed', e, st);
      }
    }

    for (final row in audios) {
      try {
        await _rekeyOneAudio(db, row, userId, enqueue);
      } catch (e, st) {
        _log.warning('rekey audio ${row.id} failed', e, st);
      }
    }
  });
}

Future<void> _rekeyOneVideo(
  AppDatabase db,
  VideoRow row,
  String userId,
  SyncEnqueueFn? enqueue,
) async {
  final contentHash = row.md5;
  if (contentHash == null || contentHash.isEmpty) return;

  final newVid = enjoyLocalVideoVid(
    contentHashHex: contentHash,
    userId: userId,
  );
  final newId = enjoyVideoId(vid: newVid);
  const dexieType = 'Video';

  if (newId == row.id) {
    await db.videoDao.insertRow(
      row.copyWith(
        syncStatus: const Value('pending'),
        updatedAt: DateTime.now(),
      ),
    );
    await enqueue?.call(SyncEntityType.video, newId, SyncAction.create);
    return;
  }

  final canonical = await db.videoDao.getById(newId);
  await _retargetMediaForeignKeys(
    db,
    oldTargetId: row.id,
    newTargetId: newId,
    dexieTargetType: dexieType,
    syncQueueEntityType: 'video',
  );

  if (canonical != null) {
    final mergedLocal =
        (canonical.localUri != null && canonical.localUri!.isNotEmpty)
        ? canonical.localUri
        : row.localUri;
    final mergedSize = canonical.size ?? row.size;
    await db.videoDao.insertRow(
      canonical.copyWith(
        localUri: Value(mergedLocal),
        size: Value(mergedSize),
        syncStatus: Value(
          mergedLocal != null && mergedLocal.isNotEmpty
              ? 'pending'
              : canonical.syncStatus,
        ),
        updatedAt: DateTime.now(),
      ),
    );
    await db.videoDao.deleteId(row.id);
  } else {
    await db.videoDao.deleteId(row.id);
    await db.videoDao.insertRow(
      row.copyWith(
        id: newId,
        vid: newVid,
        syncStatus: const Value('pending'),
        updatedAt: DateTime.now(),
      ),
    );
  }

  if (canonical != null) {
    final after = await db.videoDao.getById(newId);
    final addedLocal =
        after?.localUri != null &&
        after!.localUri!.isNotEmpty &&
        (canonical.localUri == null || canonical.localUri!.isEmpty);
    if (addedLocal) {
      await enqueue?.call(SyncEntityType.video, newId, SyncAction.update);
    }
  } else {
    await enqueue?.call(SyncEntityType.video, newId, SyncAction.create);
  }
}

Future<void> _rekeyOneAudio(
  AppDatabase db,
  AudioRow row,
  String userId,
  SyncEnqueueFn? enqueue,
) async {
  final contentHash = row.md5;
  if (contentHash == null || contentHash.isEmpty) return;

  final newAid = enjoyLocalAudioAid(
    contentHashHex: contentHash,
    userId: userId,
  );
  final newId = enjoyAudioId(aid: newAid);
  const dexieType = 'Audio';

  if (newId == row.id) {
    await db.audioDao.insertRow(
      row.copyWith(
        syncStatus: const Value('pending'),
        updatedAt: DateTime.now(),
      ),
    );
    await enqueue?.call(SyncEntityType.audio, newId, SyncAction.create);
    return;
  }

  final canonical = await db.audioDao.getById(newId);
  await _retargetMediaForeignKeys(
    db,
    oldTargetId: row.id,
    newTargetId: newId,
    dexieTargetType: dexieType,
    syncQueueEntityType: 'audio',
  );

  if (canonical != null) {
    final mergedLocal =
        (canonical.localUri != null && canonical.localUri!.isNotEmpty)
        ? canonical.localUri
        : row.localUri;
    final mergedSize = canonical.size ?? row.size;
    await db.audioDao.insertRow(
      canonical.copyWith(
        localUri: Value(mergedLocal),
        size: Value(mergedSize),
        syncStatus: Value(
          mergedLocal != null && mergedLocal.isNotEmpty
              ? 'pending'
              : canonical.syncStatus,
        ),
        updatedAt: DateTime.now(),
      ),
    );
    await db.audioDao.deleteId(row.id);
  } else {
    await db.audioDao.deleteId(row.id);
    await db.audioDao.insertRow(
      row.copyWith(
        id: newId,
        aid: newAid,
        syncStatus: const Value('pending'),
        updatedAt: DateTime.now(),
      ),
    );
  }

  if (canonical != null) {
    final after = await db.audioDao.getById(newId);
    final addedLocal =
        after?.localUri != null &&
        after!.localUri!.isNotEmpty &&
        (canonical.localUri == null || canonical.localUri!.isEmpty);
    if (addedLocal) {
      await enqueue?.call(SyncEntityType.audio, newId, SyncAction.update);
    }
  } else {
    await enqueue?.call(SyncEntityType.audio, newId, SyncAction.create);
  }
}

Future<void> _retargetMediaForeignKeys(
  AppDatabase db, {
  required String oldTargetId,
  required String newTargetId,
  required String dexieTargetType,
  required String syncQueueEntityType,
}) async {
  await (db.update(db.recordings)..where(
        (r) =>
            r.targetId.equals(oldTargetId) &
            r.targetType.equals(dexieTargetType),
      ))
      .write(RecordingsCompanion(targetId: Value(newTargetId)));

  await (db.update(db.echoSessions)..where(
        (e) =>
            e.targetId.equals(oldTargetId) &
            e.targetType.equals(dexieTargetType),
      ))
      .write(EchoSessionsCompanion(targetId: Value(newTargetId)));

  await (db.update(db.dictations)..where(
        (d) =>
            d.targetId.equals(oldTargetId) &
            d.targetType.equals(dexieTargetType),
      ))
      .write(DictationsCompanion(targetId: Value(newTargetId)));

  await (db.update(db.transcripts)..where(
        (t) =>
            t.targetId.equals(oldTargetId) &
            t.targetType.equals(dexieTargetType),
      ))
      .write(TranscriptsCompanion(targetId: Value(newTargetId)));

  final fetch = await db.transcriptFetchStateDao.getForTarget(
    dexieTargetType,
    oldTargetId,
  );
  if (fetch != null) {
    await (db.delete(db.transcriptFetchStates)..where(
          (s) =>
              s.targetType.equals(dexieTargetType) &
              s.targetId.equals(oldTargetId),
        ))
        .go();
    await db.transcriptFetchStateDao.upsertFetched(
      dexieTargetType,
      newTargetId,
      fetch.lastFetchedAt,
    );
  }

  await (db.update(db.syncQueue)..where(
        (q) =>
            q.entityId.equals(oldTargetId) &
            q.entityType.equals(syncQueueEntityType),
      ))
      .write(SyncQueueCompanion(entityId: Value(newTargetId)));
}

Future<int> countPendingRekeyRows(AppDatabase db) async {
  final v = await db
      .customSelect(
        'SELECT COUNT(*) AS c FROM videos WHERE sync_status = ?',
        variables: [Variable.withString('local-pending-rekey')],
        readsFrom: {db.videos},
      )
      .map((row) => row.read<int>('c'))
      .getSingle();
  final a = await db
      .customSelect(
        'SELECT COUNT(*) AS c FROM audios WHERE sync_status = ?',
        variables: [Variable.withString('local-pending-rekey')],
        readsFrom: {db.audios},
      )
      .map((row) => row.read<int>('c'))
      .getSingle();
  return v + a;
}
