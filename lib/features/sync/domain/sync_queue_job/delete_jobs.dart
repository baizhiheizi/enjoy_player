part of '../sync_queue_job.dart';

/// Delete jobs: cloud DELETE for the entity id. The wire payload is always
/// null (nothing to snapshot). Sealed so the drain switch stays exhaustive
/// over the leaf variants.
sealed class SyncDeleteJob extends SyncQueueJob {
  const SyncDeleteJob();
}

final class SyncAudioDelete extends SyncDeleteJob {
  const SyncAudioDelete({required this.id});

  final String id;

  @override
  SyncQueueJobWire encode() => SyncQueueJobWire(
    entityType: SyncEntityType.audio.wireName,
    entityId: id,
    action: SyncAction.delete.wireName,
  );
}

final class SyncVideoDelete extends SyncDeleteJob {
  const SyncVideoDelete({required this.id});

  final String id;

  @override
  SyncQueueJobWire encode() => SyncQueueJobWire(
    entityType: SyncEntityType.video.wireName,
    entityId: id,
    action: SyncAction.delete.wireName,
  );
}

final class SyncRecordingDelete extends SyncDeleteJob {
  const SyncRecordingDelete({required this.id});

  final String id;

  @override
  SyncQueueJobWire encode() => SyncQueueJobWire(
    entityType: SyncEntityType.recording.wireName,
    entityId: id,
    action: SyncAction.delete.wireName,
  );
}

/// Subscription deletion is local-only: the drain removes the queue row
/// without a cloud API call.
final class SyncYoutubeSubscriptionDelete extends SyncDeleteJob {
  const SyncYoutubeSubscriptionDelete({required this.channelId});

  final String channelId;

  @override
  SyncQueueJobWire encode() => SyncQueueJobWire(
    entityType: SyncEntityType.youtubeSubscription.wireName,
    entityId: channelId,
    action: SyncAction.delete.wireName,
  );
}

final class SyncVocabularyItemDelete extends SyncDeleteJob {
  const SyncVocabularyItemDelete({required this.id});

  final String id;

  @override
  SyncQueueJobWire encode() => SyncQueueJobWire(
    entityType: SyncEntityType.vocabularyItem.wireName,
    entityId: id,
    action: SyncAction.delete.wireName,
  );
}

final class SyncVocabularyContextDelete extends SyncDeleteJob {
  const SyncVocabularyContextDelete({required this.id});

  final String id;

  @override
  SyncQueueJobWire encode() => SyncQueueJobWire(
    entityType: SyncEntityType.vocabularyContext.wireName,
    entityId: id,
    action: SyncAction.delete.wireName,
  );
}
