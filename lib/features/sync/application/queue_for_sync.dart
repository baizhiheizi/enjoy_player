/// Enqueue local changes for cloud sync (metadata-only uploads).
library;

import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/sync/application/sync_engine.dart';
import 'package:enjoy_player/features/sync/data/sync_queue_repository.dart';
import 'package:enjoy_player/features/sync/data/sync_serializers.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';

/// Schedules [SyncEngine.processQueue] outside any ambient Drift transaction.
///
/// Library/vocabulary deletes enqueue sync rows inside `_db.transaction(...)`.
/// Starting a drain in that Zone makes follow-up queue DB ops use the closed
/// transaction executor (`Transaction used after it was closed`).
void scheduleSyncQueueDrain(SyncEngine engine) {
  Zone.root.run(() {
    unawaited(() async {
      await Future<void>.delayed(Duration.zero);
      await engine.processQueue(const SyncOptions());
    }());
  });
}

Future<void> enqueuePendingSync(
  Ref ref,
  SyncQueueRepository queue,
  SyncEngine engine,
  SyncEntityType type,
  String id,
  SyncAction action,
) async {
  final db = ref.read(appDatabaseProvider);

  String? payloadJson;
  switch (action) {
    case SyncAction.delete:
      break;
    case SyncAction.create:
    case SyncAction.update:
      switch (type) {
        case SyncEntityType.audio:
          final row = await db.audioDao.getById(id);
          if (row == null) return;
          payloadJson = jsonEncode(prepareForSyncAudioMap(row));
          await db.audioDao.insertRow(
            row.copyWith(syncStatus: const Value('pending')),
          );
        case SyncEntityType.video:
          final row = await db.videoDao.getById(id);
          if (row == null) return;
          payloadJson = jsonEncode(prepareForSyncVideoMap(row));
          await db.videoDao.insertRow(
            row.copyWith(syncStatus: const Value('pending')),
          );
        case SyncEntityType.recording:
          final row = await db.recordingDao.getById(id);
          if (row == null) return;
          payloadJson = jsonEncode(prepareForSyncRecordingMap(row));
          await db.recordingDao.insertRow(
            row.copyWith(syncStatus: const Value('pending')),
          );
        case SyncEntityType.youtubeSubscription:
          final sub = await db.youtubeChannelSubscriptionDao.getByChannelId(id);
          if (sub == null) return;
          payloadJson = jsonEncode(prepareForSyncSubscriptionMap(sub));
        case SyncEntityType.vocabularyItem:
          final row = await db.vocabularyItemDao.getById(id);
          if (row == null) return;
          payloadJson = jsonEncode(prepareForSyncVocabularyItemMap(row));
          await db.vocabularyItemDao.updateRow(
            row.copyWith(syncStatus: const Value('pending')),
          );
        case SyncEntityType.vocabularyContext:
          final row = await db.vocabularyContextDao.getById(id);
          if (row == null) return;
          payloadJson = jsonEncode(prepareForSyncVocabularyContextMap(row));
          await db.vocabularyContextDao.updateRow(
            row.copyWith(syncStatus: const Value('pending')),
          );
      }
  }

  await queue.addOrUpsert(
    entityType: type.wireName,
    entityId: id,
    action: action.wireName,
    payloadJson: payloadJson,
  );

  final auth = ref.read(authCtrlProvider).valueOrNull;
  if (auth is AuthSignedIn) {
    scheduleSyncQueueDrain(engine);
  }
}
