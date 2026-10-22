/// Typed seam for `sync_queue` payloads (issue #718).
///
/// Ownership: [SyncQueueJob.decode] owns the interpretation of persisted
/// queue rows. Producers construct typed variants — never hand-rolled
/// `entityType` / `entityId` / `action` / `payloadJson` strings — and
/// persist them through the shared enqueue seam: the
/// `syncEnqueueProvider` `(type, id, action)` form (snapshot built here via
/// [deleteFor] / [snapshotUpsert]) or, for pre-built jobs, the job-shaped
/// [SyncEnqueueJobFn] entry (`syncEnqueueJobProvider`, issue #749) — both
/// run `SyncQueueRepository.addJob` plus the signed-in drain scheduling.
/// The drain (`SyncEngine._processOne`) switches exhaustively over the
/// decoded variant, so adding a producer without matching consumer handling
/// is a compile error instead of a silent row drop.
///
/// Payload snapshots on the upsert variants are fallback-only: the drain
/// re-reads the live row before uploading, so `payloadJson` is decorative
/// except for deletes (always null) and [SyncYoutubeUploadRetry] (the
/// payload *is* the job — there is no local row to re-read).
library;

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:enjoy_player/core/json/gated_json_decode.dart';
import 'package:enjoy_player/core/json/json_cast.dart';
import 'package:enjoy_player/data/api/services/ai/youtube_transcripts_api.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/media_registry.dart';
import 'package:enjoy_player/features/sync/data/sync_serializers.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';

part 'sync_queue_job/delete_jobs.dart';
part 'sync_queue_job/upsert_jobs.dart';
part 'sync_queue_job/youtube_upload_retry.dart';

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

/// Job-shaped entry of the typed enqueue seam (issue #749): hands a
/// pre-built [SyncQueueJob] to the shared provider path instead of the
/// `(type, id, action)` form. Why the pre-built form exists and what the
/// persist/drain tail does: see the `syncEnqueueJobProvider` docstring
/// (the canonical seam documentation).
typedef SyncEnqueueJobFn = Future<void> Function(SyncQueueJob job);

/// A typed sync_queue job: one variant per producible row kind.
sealed class SyncQueueJob {
  const SyncQueueJob();

  /// The `sync_queue` wire columns for this job.
  ///
  /// **Encode stability (issue #749)**: `encode()` must be pure — the same
  /// job content always yields the same bytes (same field set, same
  /// `jsonEncode` key order), including after a `decode` → `encode` round
  /// trip. The payload-match race guard
  /// (`SyncQueueRepository.removeByIdIfPayload`) derives its expected
  /// string from `job.encode().payloadJson` and string-compares it against
  /// the stored row, so an unstable encode would make every success-path
  /// remove look like a producer race (and leak rows) or, worse, delete a
  /// refreshed payload. Pinned by test.
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

  /// Interprets a persisted [SyncQueueRow] as a typed job.
  ///
  /// Video upsert rows are returned as [SyncVideoUpsert] with the raw
  /// `payloadJson` — the `youtube_upload` retry hiding inside that payload is
  /// resolved lazily by [decodeYoutubeUploadRetry] at dispatch time, because
  /// the retry payload embeds the whole caption timeline (potentially MBs of
  /// JSON) and must not be parsed on every drain scan.
  ///
  /// Returns `null` when the row cannot be interpreted — an unknown
  /// `entityType`/`action` pair. The drain drops such rows instead of
  /// retrying them forever; never crash the drain loop over an
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
      SyncEntityType.video => SyncVideoUpsert(
        id: row.entityId,
        action: action,
        payloadJson: row.payloadJson,
      ),
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

  /// Resolves the durable YouTube worker-upload retry (issue #717) hiding
  /// inside a `video` upsert payload — there is deliberately no
  /// [SyncEntityType] value for the worker upload (web/Dexie wire parity pins
  /// the enum), so the `kind` discriminator is decoded here.
  ///
  /// Called by the drain only when the retry is actually dispatched: the
  /// quoted-key probe [_kYoutubeUploadKindProbe] skips plain video snapshots
  /// without any JSON parse — in valid JSON an unescaped `"kind":` can only
  /// introduce an object member, never string content, so user text that
  /// merely mentions `youtube_upload` cannot trip it — and the full payload
  /// decode (the embedded caption timeline can reach MBs) leaves the UI
  /// isolate via [decodeJsonGated]. Returns `null` for a plain video payload
  /// or a malformed retry.
  static Future<SyncYoutubeUploadRetry?> decodeYoutubeUploadRetry(
    String? payloadJson,
  ) => _decodeYoutubeUploadRetry(payloadJson);
}
