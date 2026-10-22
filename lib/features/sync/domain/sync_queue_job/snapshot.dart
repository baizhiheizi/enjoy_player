part of '../sync_queue_job.dart';

Future<SyncQueueJob?> _snapshotUpsert(
  AppDatabase db,
  SyncEntityType type,
  String id,
  SyncAction action,
) async {
  assert(
    action == SyncAction.create || action == SyncAction.update,
    'Upsert snapshots are create/update only; use deleteFor',
  );
  final registry = MediaRegistry(db);
  switch (type) {
    case SyncEntityType.audio:
      final row = await registry.getAudioById(id);
      if (row == null) return null;
      final job = SyncAudioUpsert.snapshot(row, action: action);
      await registry.upsertAudio(
        row.copyWith(syncStatus: const Value('pending')),
      );
      return job;
    case SyncEntityType.video:
      final row = await registry.getVideoById(id);
      if (row == null) return null;
      final job = SyncVideoUpsert.snapshot(row, action: action);
      await registry.upsertVideo(
        row.copyWith(syncStatus: const Value('pending')),
      );
      return job;
    case SyncEntityType.recording:
      final row = await db.recordingDao.getById(id);
      if (row == null) return null;
      final job = SyncRecordingUpsert.snapshot(row, action: action);
      await db.recordingDao.insertRow(
        row.copyWith(syncStatus: const Value('pending')),
      );
      return job;
    case SyncEntityType.youtubeSubscription:
      final sub = await db.youtubeChannelSubscriptionDao.getByChannelId(id);
      if (sub == null) return null;
      return SyncYoutubeSubscriptionUpsert.snapshot(sub, action: action);
    case SyncEntityType.vocabularyItem:
      final row = await db.vocabularyItemDao.getById(id);
      if (row == null) return null;
      final job = SyncVocabularyItemUpsert.snapshot(row, action: action);
      await db.vocabularyItemDao.updateRow(
        row.copyWith(syncStatus: const Value('pending')),
      );
      return job;
    case SyncEntityType.vocabularyContext:
      final row = await db.vocabularyContextDao.getById(id);
      if (row == null) return null;
      final job = SyncVocabularyContextUpsert.snapshot(row, action: action);
      await db.vocabularyContextDao.updateRow(
        row.copyWith(syncStatus: const Value('pending')),
      );
      return job;
  }
}
