/// Riverpod wiring for [SyncEngine] dependencies.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/api/api_client_provider.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/api/services/audio_api.dart';
import 'package:enjoy_player/data/api/services/recording_api.dart';
import 'package:enjoy_player/data/api/services/video_api.dart';
import 'package:enjoy_player/features/sync/application/queue_for_sync.dart';
import 'package:enjoy_player/features/sync/application/sync_engine.dart';
import 'package:enjoy_player/features/sync/data/sync_download_service.dart';
import 'package:enjoy_player/features/sync/data/sync_queue_repository.dart';
import 'package:enjoy_player/features/sync/data/sync_upload_service.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';

part 'sync_providers.g.dart';

@Riverpod(keepAlive: true)
SyncQueueRepository syncQueueRepository(Ref ref) =>
    SyncQueueRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
SyncUploadService syncUploadService(Ref ref) => SyncUploadService(
      db: ref.watch(appDatabaseProvider),
      audioApi: AudioApi(ref.watch(apiClientProvider)),
      videoApi: VideoApi(ref.watch(apiClientProvider)),
      recordingApi: RecordingApi(ref.watch(apiClientProvider)),
    );

@Riverpod(keepAlive: true)
SyncDownloadService syncDownloadService(Ref ref) => SyncDownloadService(
      db: ref.watch(appDatabaseProvider),
      audioApi: AudioApi(ref.watch(apiClientProvider)),
      videoApi: VideoApi(ref.watch(apiClientProvider)),
      recordingApi: RecordingApi(ref.watch(apiClientProvider)),
    );

@Riverpod(keepAlive: true)
SyncEngine syncEngine(Ref ref) => SyncEngine(
      db: ref.watch(appDatabaseProvider),
      queue: ref.watch(syncQueueRepositoryProvider),
      upload: ref.watch(syncUploadServiceProvider),
      download: ref.watch(syncDownloadServiceProvider),
    );

@Riverpod(keepAlive: true)
SyncEnqueueFn syncEnqueue(Ref ref) {
  final queue = ref.watch(syncQueueRepositoryProvider);
  final engine = ref.watch(syncEngineProvider);
  return (type, id, action) =>
      enqueuePendingSync(ref, queue, engine, type, id, action);
}
