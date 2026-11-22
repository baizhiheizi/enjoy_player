part of '../sync_queue_job.dart';

/// Upsert (create/update) jobs: the drain treats both actions identically —
/// it re-reads the live row and uploads it. The action only distinguishes
/// the wire row (dedup key + delete-first drain ordering).
///
/// Constructors assert the action is `create` or `update`; deletes are the
/// dedicated `Sync*Delete` variants. Sealed so the drain switch stays
/// exhaustive over the leaf variants.
sealed class SyncUpsertJob extends SyncQueueJob {
  const SyncUpsertJob({
    required this.id,
    required this.action,
    this.payloadJson,
  }) : assert(
         action == SyncAction.create || action == SyncAction.update,
         'Upsert jobs are create/update only; use the Delete variant',
       );

  /// The local entity id this job upserts.
  final String id;

  final SyncAction action;

  /// The fallback-only payload snapshot — the drain re-reads the live row.
  final String? payloadJson;

  /// The synced entity kind this job upserts.
  SyncEntityType get entityType;

  @override
  SyncQueueJobWire encode() => SyncQueueJobWire(
    entityType: entityType.wireName,
    entityId: id,
    action: action.wireName,
    payloadJson: payloadJson,
  );
}

/// Audio metadata upsert (`entityType: audio`).
final class SyncAudioUpsert extends SyncUpsertJob {
  const SyncAudioUpsert({
    required super.id,
    required super.action,
    super.payloadJson,
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

  @override
  SyncEntityType get entityType => SyncEntityType.audio;
}

/// Video metadata upsert (`entityType: video`) — the plain path that
/// re-reads the local video row on drain.
final class SyncVideoUpsert extends SyncUpsertJob {
  const SyncVideoUpsert({
    required super.id,
    required super.action,
    super.payloadJson,
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

  @override
  SyncEntityType get entityType => SyncEntityType.video;
}

/// Recording metadata upsert (`entityType: recording`).
final class SyncRecordingUpsert extends SyncUpsertJob {
  const SyncRecordingUpsert({
    required super.id,
    required super.action,
    super.payloadJson,
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

  @override
  SyncEntityType get entityType => SyncEntityType.recording;
}

/// Vocabulary item upsert (`entityType: vocabulary_item`, ADR-0054).
final class SyncVocabularyItemUpsert extends SyncUpsertJob {
  const SyncVocabularyItemUpsert({
    required super.id,
    required super.action,
    super.payloadJson,
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

  @override
  SyncEntityType get entityType => SyncEntityType.vocabularyItem;
}

/// Vocabulary context upsert (`entityType: vocabulary_context`, ADR-0054).
final class SyncVocabularyContextUpsert extends SyncUpsertJob {
  const SyncVocabularyContextUpsert({
    required super.id,
    required super.action,
    super.payloadJson,
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

  @override
  SyncEntityType get entityType => SyncEntityType.vocabularyContext;
}

/// YouTube channel subscription upsert (`entityType:
/// youtube_subscription`). **Deferred**: consumer handling exists but no
/// producer enqueues it today — kept as a declared variant so the drain
/// stays exhaustive when wire parity requires it.
final class SyncYoutubeSubscriptionUpsert extends SyncUpsertJob {
  const SyncYoutubeSubscriptionUpsert({
    required super.id,
    required super.action,
    super.payloadJson,
  });

  /// Snapshots a live subscription row into the (fallback-only) payload
  /// columns.
  factory SyncYoutubeSubscriptionUpsert.snapshot(
    YoutubeChannelSubscriptionRow row, {
    required SyncAction action,
  }) => SyncYoutubeSubscriptionUpsert(
    id: row.channelId,
    action: action,
    payloadJson: jsonEncode(prepareForSyncSubscriptionMap(row)),
  );

  @override
  SyncEntityType get entityType => SyncEntityType.youtubeSubscription;
}
