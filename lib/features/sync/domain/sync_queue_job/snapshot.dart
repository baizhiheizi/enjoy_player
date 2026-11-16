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
      if (!await registry.markAudioSyncPending(id)) return null;
      return SyncAudioUpsert(id: id, action: action);
    case SyncEntityType.video:
      if (!await registry.markVideoSyncPending(id)) return null;
      return SyncVideoUpsert(id: id, action: action);
    case SyncEntityType.recording:
      if (!await db.recordingDao.markSyncPending(id)) return null;
      return SyncRecordingUpsert(id: id, action: action);
    case SyncEntityType.youtubeSubscription:
      final sub = await db.youtubeChannelSubscriptionDao.getByChannelId(id);
      if (sub == null) return null;
      return SyncYoutubeSubscriptionUpsert.snapshot(sub, action: action);
    case SyncEntityType.vocabularyItem:
      if (!await db.vocabularyItemDao.markSyncPending(id)) return null;
      return SyncVocabularyItemUpsert(id: id, action: action);
    case SyncEntityType.vocabularyContext:
      if (!await db.vocabularyContextDao.markSyncPending(id)) return null;
      return SyncVocabularyContextUpsert(id: id, action: action);
  }
}
