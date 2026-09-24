/// Enqueue local changes for cloud sync (metadata-only uploads).
library;

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/sync/application/sync_engine.dart';
import 'package:enjoy_player/features/sync/data/sync_queue_repository.dart';
import 'package:enjoy_player/features/sync/domain/sync_queue_job.dart';
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

/// Builds the typed job for `(type, id, action)` via the seam
/// ([SyncQueueJob.deleteFor] / [SyncQueueJob.snapshotUpsert]) and persists it.
///
/// The per-type snapshot / pending-flip incantations live in the seam
/// (issue #718); this wrapper only owns the read-modify order, the
/// row-missing early return, and the signed-in drain scheduling.
Future<void> enqueuePendingSync(
  Ref ref,
  SyncQueueRepository queue,
  SyncEngine engine,
  SyncEntityType type,
  String id,
  SyncAction action,
) async {
  final SyncQueueJob job;
  if (action == SyncAction.delete) {
    job = SyncQueueJob.deleteFor(type, id);
  } else {
    final upsert = await SyncQueueJob.snapshotUpsert(
      ref.read(appDatabaseProvider),
      type,
      id,
      action,
    );
    if (upsert == null) return;
    job = upsert;
  }

  await queue.addJob(job);

  final auth = ref.read(authCtrlProvider).valueOrNull;
  if (auth is AuthSignedIn) {
    scheduleSyncQueueDrain(engine);
  }
}

/// Job-shaped sibling of [enqueuePendingSync] (issue #749): persists a
/// pre-built typed [SyncQueueJob] through the same dedup contract
/// ([SyncQueueRepository.addJob]) and the same signed-in
/// [scheduleSyncQueueDrain] tail as the `(type, id, action)` form.
///
/// The pre-built-job form exists for variants whose payload *is* the job
/// (e.g. `SyncYoutubeUploadRetry`): there is no local row for
/// [SyncQueueJob.snapshotUpsert] to re-read, so the producer constructs the
/// variant itself. Exposed to features through `syncEnqueueJobProvider`.
Future<void> enqueueSyncJob(
  Ref ref,
  SyncQueueRepository queue,
  SyncEngine engine,
  SyncQueueJob job,
) async {
  await queue.addJob(job);

  final auth = ref.read(authCtrlProvider).valueOrNull;
  if (auth is AuthSignedIn) {
    scheduleSyncQueueDrain(engine);
  }
}
