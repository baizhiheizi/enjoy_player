part of '../sync_queue_job.dart';

/// Upsert (create/update) jobs: the drain treats both actions identically —
/// it re-reads the live row and uploads it. The action only distinguishes
/// the wire row (dedup key + delete-first drain ordering).
///
/// Constructors assert the action is `create` or `update`; deletes are the
/// dedicated `Sync*Delete` variants. Sealed so the drain switch stays
/// exhaustive over the leaf variants.
sealed class SyncUpsertJob extends SyncQueueJob {
  const SyncUpsertJob({required this.action})
    : assert(
        action == SyncAction.create || action == SyncAction.update,
        'Upsert jobs are create/update only; use the Delete variant',
      );

  final SyncAction action;
}

/// Audio metadata upsert (`entityType: audio`).
final class SyncAudioUpsert extends SyncUpsertJob {
  const SyncAudioUpsert({
    required this.id,
    required super.action,
    this.payloadJson,
  });

  /// Snapshots a live audio row into the (fallback-only) payload columns.
  factory SyncAudioUpsert.snapshot(
    AudioRow row, {
    required SyncAction action,
  }) => SyncAudioUpsert(
    id: row.id,
    action: action,
    payloadJson: jsonEncode(prepareForSyncAudioMap(row)),
  );

  final String id;
  final String? payloadJson;

  @override
  SyncQueueJobWire encode() => SyncQueueJobWire(
    entityType: SyncEntityType.audio.wireName,
    entityId: id,
    action: action.wireName,
    payloadJson: payloadJson,
  );
}

/// Video metadata upsert (`entityType: video`) — the plain path that
/// re-reads the local video row on drain.
final class SyncVideoUpsert extends SyncUpsertJob {
  const SyncVideoUpsert({
    required this.id,
    required super.action,
    this.payloadJson,
  });

  /// Snapshots a live video row into the (fallback-only) payload columns.
  factory SyncVideoUpsert.snapshot(
    VideoRow row, {
    required SyncAction action,
  }) => SyncVideoUpsert(
    id: row.id,
    action: action,
    payloadJson: jsonEncode(prepareForSyncVideoMap(row)),
  );

  final String id;
  final String? payloadJson;

  @override
  SyncQueueJobWire encode() => SyncQueueJobWire(
    entityType: SyncEntityType.video.wireName,
    entityId: id,
    action: action.wireName,
    payloadJson: payloadJson,
  );
}

/// Recording metadata upsert (`entityType: recording`).
final class SyncRecordingUpsert extends SyncUpsertJob {
  const SyncRecordingUpsert({
    required this.id,
    required super.action,
    this.payloadJson,
  });

  /// Snapshots a live recording row into the (fallback-only) payload
  /// columns.
  factory SyncRecordingUpsert.snapshot(
    RecordingRow row, {
    required SyncAction action,
  }) => SyncRecordingUpsert(
    id: row.id,
    action: action,
    payloadJson: jsonEncode(prepareForSyncRecordingMap(row)),
  );

  final String id;
  final String? payloadJson;

  @override
  SyncQueueJobWire encode() => SyncQueueJobWire(
    entityType: SyncEntityType.recording.wireName,
    entityId: id,
    action: action.wireName,
    payloadJson: payloadJson,
  );
}

/// Vocabulary item upsert (`entityType: vocabulary_item`, ADR-0054).
final class SyncVocabularyItemUpsert extends SyncUpsertJob {
  const SyncVocabularyItemUpsert({
    required this.id,
    required super.action,
    this.payloadJson,
  });

  /// Snapshots a live vocabulary item row into the (fallback-only) payload
  /// columns. Review audits never leave the device.
  factory SyncVocabularyItemUpsert.snapshot(
    VocabularyItemRow row, {
    required SyncAction action,
  }) => SyncVocabularyItemUpsert(
    id: row.id,
    action: action,
    payloadJson: jsonEncode(prepareForSyncVocabularyItemMap(row)),
  );

  final String id;
  final String? payloadJson;

  @override
  SyncQueueJobWire encode() => SyncQueueJobWire(
    entityType: SyncEntityType.vocabularyItem.wireName,
    entityId: id,
    action: action.wireName,
    payloadJson: payloadJson,
  );
}

/// Vocabulary context upsert (`entityType: vocabulary_context`, ADR-0054).
final class SyncVocabularyContextUpsert extends SyncUpsertJob {
  const SyncVocabularyContextUpsert({
    required this.id,
    required super.action,
    this.payloadJson,
  });

  /// Snapshots a live vocabulary context row into the (fallback-only)
  /// payload columns.
  factory SyncVocabularyContextUpsert.snapshot(
    VocabularyContextRow row, {
    required SyncAction action,
  }) => SyncVocabularyContextUpsert(
    id: row.id,
    action: action,
    payloadJson: jsonEncode(prepareForSyncVocabularyContextMap(row)),
  );

  final String id;
  final String? payloadJson;

  @override
  SyncQueueJobWire encode() => SyncQueueJobWire(
    entityType: SyncEntityType.vocabularyContext.wireName,
    entityId: id,
    action: action.wireName,
    payloadJson: payloadJson,
  );
}

/// YouTube channel subscription upsert (`entityType:
/// youtube_subscription`). **Deferred**: consumer handling exists but no
/// producer enqueues it today — kept as a declared variant so the drain
/// stays exhaustive when wire parity requires it.
final class SyncYoutubeSubscriptionUpsert extends SyncUpsertJob {
  const SyncYoutubeSubscriptionUpsert({
    required this.channelId,
    required super.action,
    this.payloadJson,
  });

  /// Snapshots a live subscription row into the (fallback-only) payload
  /// columns.
  factory SyncYoutubeSubscriptionUpsert.snapshot(
    YoutubeChannelSubscriptionRow row, {
    required SyncAction action,
  }) => SyncYoutubeSubscriptionUpsert(
    channelId: row.channelId,
    action: action,
    payloadJson: jsonEncode(prepareForSyncSubscriptionMap(row)),
  );

  final String channelId;
  final String? payloadJson;

  @override
  SyncQueueJobWire encode() => SyncQueueJobWire(
    entityType: SyncEntityType.youtubeSubscription.wireName,
    entityId: channelId,
    action: action.wireName,
    payloadJson: payloadJson,
  );
}
