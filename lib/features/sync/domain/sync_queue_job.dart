/// Typed seam for `sync_queue` payloads (issue #718).
///
/// Ownership: [SyncQueueJob.decode] owns the interpretation of persisted
/// queue rows. Producers construct typed variants — never hand-rolled
/// `entityType` / `entityId` / `action` / `payloadJson` strings — and
/// persist them via `SyncQueueRepository.addJob`; the drain
/// (`SyncEngine._processOne`) switches exhaustively over the decoded
/// variant, so adding a producer without matching consumer handling is a
/// compile error instead of a silent row drop.
///
/// Payload snapshots on the upsert variants are fallback-only: the drain
/// re-reads the live row before uploading, so `payloadJson` is decorative
/// except for deletes (always null) and [SyncYoutubeUploadRetry] (the
/// payload *is* the job — there is no local row to re-read).
library;

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:enjoy_player/core/json/json_cast.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/sync/data/sync_serializers.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';

/// The `sync_queue` wire columns a [SyncQueueJob] persists to — the exact
/// pre-seam row shape (`entityType` / `entityId` / `action` / `payloadJson`),
/// unchanged for web/Dexie parity.
final class SyncQueueJobWire {
  const SyncQueueJobWire({
    required this.entityType,
    required this.entityId,
    required this.action,
    this.payloadJson,
  });

  final String entityType;
  final String entityId;
  final String action;
  final String? payloadJson;

  @override
  bool operator ==(Object other) =>
      other is SyncQueueJobWire &&
      other.entityType == entityType &&
      other.entityId == entityId &&
      other.action == action &&
      other.payloadJson == payloadJson;

  @override
  int get hashCode => Object.hash(entityType, entityId, action, payloadJson);
}

/// A typed sync_queue job: one variant per producible row kind.
sealed class SyncQueueJob {
  const SyncQueueJob();

  /// The `sync_queue` wire columns for this job.
  SyncQueueJobWire encode();

  /// Builds the delete job for [type] — deletes carry no payload snapshot.
  ///
  /// Absorbed from `enqueuePendingSync` (issue #718) so the per-type
  /// incantations have exactly one owner, next to the variants they build.
  static SyncQueueJob deleteFor(SyncEntityType type, String id) =>
      switch (type) {
        SyncEntityType.audio => SyncAudioDelete(id: id),
        SyncEntityType.video => SyncVideoDelete(id: id),
        SyncEntityType.recording => SyncRecordingDelete(id: id),
        SyncEntityType.youtubeSubscription => SyncYoutubeSubscriptionDelete(
          channelId: id,
        ),
        SyncEntityType.vocabularyItem => SyncVocabularyItemDelete(id: id),
        SyncEntityType.vocabularyContext => SyncVocabularyContextDelete(id: id),
      };

  /// Reads the live row for [type] and builds the upsert job with a payload
  /// snapshot, flipping the row's `syncStatus` to `pending`.
  ///
  /// Absorbed from `enqueuePendingSync` (issue #718). Returns `null` when
  /// the row is missing locally — the caller must not enqueue anything
  /// (pre-seam behavior: no row, no sync work). Snapshots are taken from the
  /// row as read, before the `pending` flip; the serializers never include
  /// `syncStatus`, so the payload is identical either way.
  static Future<SyncQueueJob?> snapshotUpsert(
    AppDatabase db,
    SyncEntityType type,
    String id,
    SyncAction action,
  ) async {
    assert(
      action == SyncAction.create || action == SyncAction.update,
      'Upsert snapshots are create/update only; use deleteFor',
    );
    switch (type) {
      case SyncEntityType.audio:
        final row = await db.audioDao.getById(id);
        if (row == null) return null;
        final job = SyncAudioUpsert.snapshot(row, action: action);
        await db.audioDao.insertRow(
          row.copyWith(syncStatus: const Value('pending')),
        );
        return job;
      case SyncEntityType.video:
        final row = await db.videoDao.getById(id);
        if (row == null) return null;
        final job = SyncVideoUpsert.snapshot(row, action: action);
        await db.videoDao.insertRow(
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
        // Subscription sync deferred — snapshot only, no status flip (the
        // table has no syncStatus column to flip).
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

  /// Interprets a persisted [SyncQueueRow] as a typed job.
  ///
  /// Returns `null` when the row cannot be interpreted — an unknown
  /// `entityType`/`action` pair, or a payload the seam cannot decode (a
  /// malformed `youtube_upload` retry). The drain drops such rows instead
  /// of retrying them forever; never crash the drain loop over an
  /// unrecoverable row.
  static SyncQueueJob? decode(SyncQueueRow row) {
    final type = SyncEntityTypeWire.tryParse(row.entityType);
    final action = SyncActionWire.tryParse(row.action);
    if (type == null || action == null) return null;

    if (action == SyncAction.delete) {
      return switch (type) {
        SyncEntityType.audio => SyncAudioDelete(id: row.entityId),
        SyncEntityType.video => SyncVideoDelete(id: row.entityId),
        SyncEntityType.recording => SyncRecordingDelete(id: row.entityId),
        SyncEntityType.youtubeSubscription => SyncYoutubeSubscriptionDelete(
          channelId: row.entityId,
        ),
        SyncEntityType.vocabularyItem => SyncVocabularyItemDelete(
          id: row.entityId,
        ),
        SyncEntityType.vocabularyContext => SyncVocabularyContextDelete(
          id: row.entityId,
        ),
      };
    }

    return switch (type) {
      SyncEntityType.audio => SyncAudioUpsert(
        id: row.entityId,
        action: action,
        payloadJson: row.payloadJson,
      ),
      SyncEntityType.video => _decodeVideo(row, action),
      SyncEntityType.recording => SyncRecordingUpsert(
        id: row.entityId,
        action: action,
        payloadJson: row.payloadJson,
      ),
      SyncEntityType.youtubeSubscription => SyncYoutubeSubscriptionUpsert(
        channelId: row.entityId,
        action: action,
        payloadJson: row.payloadJson,
      ),
      SyncEntityType.vocabularyItem => SyncVocabularyItemUpsert(
        id: row.entityId,
        action: action,
        payloadJson: row.payloadJson,
      ),
      SyncEntityType.vocabularyContext => SyncVocabularyContextUpsert(
        id: row.entityId,
        action: action,
        payloadJson: row.payloadJson,
      ),
    };
  }

  /// Video rows carry two upsert kinds: plain video metadata updates, and
  /// durable YouTube worker-upload retries (issue #717) hiding inside the
  /// `video` entity as `action: update` + `payload.kind: youtube_upload`.
  ///
  /// There is deliberately no [SyncEntityType] value for the worker upload
  /// (web/Dexie wire parity pins the enum), so the `kind` discriminator is
  /// decoded here — inside the video variant.
  static SyncQueueJob? _decodeVideo(SyncQueueRow row, SyncAction action) {
    Map<String, dynamic>? payload;
    try {
      payload = castJsonObjectOrNull(jsonDecode(row.payloadJson ?? ''));
    } on Object {
      payload = null;
    }
    if (payload == null || payload['kind'] != 'youtube_upload') {
      return SyncVideoUpsert(
        id: row.entityId,
        action: action,
        payloadJson: row.payloadJson,
      );
    }

    final videoId = payload['videoId'];
    final language = payload['language'];
    final source = payload['source'];
    final rawTimeline = payload['timeline'];
    final timeline = rawTimeline is List
        ? rawTimeline
              .map(castJsonObjectOrNull)
              .whereType<Map<String, dynamic>>()
              .toList(growable: false)
        : null;
    if (videoId is! String ||
        videoId.isEmpty ||
        language is! String ||
        language.isEmpty ||
        source is! String ||
        source.isEmpty ||
        timeline == null ||
        timeline.isEmpty) {
      // Malformed retry payload — unrecoverable, decode refuses it so the
      // drain drops the row (same handling as the "missing locally" rows).
      return null;
    }
    return SyncYoutubeUploadRetry(
      videoId: videoId,
      language: language,
      source: source,
      timeline: timeline,
    );
  }
}

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

/// Durable YouTube worker transcript-upload retry (issue #717), absorbed
/// from the pre-seam producer in
/// `transcript_repository_youtube_worker_cache.dart`.
///
/// Rides the `video` entity as `action: update` with
/// `entityId = '$videoId/$language'` — which never matches a local video
/// row id (UUIDv5) — and `payload.kind: youtube_upload`. The payload is the
/// whole job: the drain re-uploads it via the worker transcripts API and
/// never touches a local row. The worker treats a repeated upload as
/// idempotent (409 == success), so re-running a partially-applied upload is
/// safe.
final class SyncYoutubeUploadRetry extends SyncQueueJob {
  const SyncYoutubeUploadRetry({
    required this.videoId,
    required this.language,
    required this.source,
    required this.timeline,
  });

  final String videoId;
  final String language;
  final String source;
  final List<Map<String, dynamic>> timeline;

  @override
  SyncQueueJobWire encode() => SyncQueueJobWire(
    entityType: SyncEntityType.video.wireName,
    entityId: '$videoId/$language',
    action: SyncAction.update.wireName,
    payloadJson: jsonEncode(<String, dynamic>{
      'kind': 'youtube_upload',
      'videoId': videoId,
      'language': language,
      'source': source,
      'timeline': timeline,
    }),
  );
}

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
