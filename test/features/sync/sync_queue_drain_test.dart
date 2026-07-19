import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/services/audio_api.dart';
import 'package:enjoy_player/data/api/services/recording_api.dart';
import 'package:enjoy_player/data/api/services/video_api.dart';
import 'package:enjoy_player/data/api/services/vocabulary_api.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/sync/application/queue_for_sync.dart';
import 'package:enjoy_player/features/sync/application/sync_engine.dart';
import 'package:enjoy_player/features/sync/data/sync_download_service.dart';
import 'package:enjoy_player/features/sync/data/sync_queue_repository.dart';
import 'package:enjoy_player/features/sync/data/sync_upload_service.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';

void main() {
  group('scheduleSyncQueueDrain', () {
    test(
      'DB work after transactional enqueue does not use a closed transaction',
      () async {
        final db = AppDatabase(executor: NativeDatabase.memory());
        addTearDown(db.close);
        final queue = SyncQueueRepository(db);

        Object? drainError;
        var drainRan = false;
        final drainDone = Completer<void>();

        await db.transaction(() async {
          final id = await queue.addOrUpsert(
            entityType: 'video',
            entityId: 'v-txn',
            action: 'delete',
          );
          // Mirror production: kick drain from inside the ambient txn Zone.
          Zone.root.run(() {
            unawaited(
              Future<void>.delayed(Duration.zero, () async {
                try {
                  await queue.removeById(id);
                  drainRan = true;
                } catch (e) {
                  drainError = e;
                } finally {
                  drainDone.complete();
                }
              }),
            );
          });
        });

        await drainDone.future;
        expect(drainError, isNull);
        expect(drainRan, isTrue);
        expect(await queue.pendingItems(), isEmpty);
      },
    );

    test(
      'immediate unawaited drain inside a transaction hits closed executor',
      () async {
        final db = AppDatabase(executor: NativeDatabase.memory());
        addTearDown(db.close);
        final queue = SyncQueueRepository(db);

        Object? drainError;
        final drainDone = Completer<void>();

        await db.transaction(() async {
          final id = await queue.addOrUpsert(
            entityType: 'video',
            entityId: 'v-bug',
            action: 'delete',
          );
          // Anti-pattern that previously ran from enqueuePendingSync.
          unawaited(() async {
            try {
              await Future<void>.delayed(Duration.zero);
              await queue.removeById(id);
            } catch (e) {
              drainError = e;
            } finally {
              if (!drainDone.isCompleted) drainDone.complete();
            }
          }());
        });

        await drainDone.future;
        // Drift surfaces closed-txn differently for memory vs remote executors.
        expect(
          drainError,
          isNotNull,
          reason: 'Immediate drain inside txn Zone should fail',
        );
        expect('$drainError'.toLowerCase(), contains('transaction'));
        expect(
          '$drainError'.toLowerCase(),
          anyOf(contains('closed'), contains('!_done')),
        );
      },
    );
  });

  group('SyncEngine processQueue', () {
    test(
      'delete then create for same video id runs DELETE before POST',
      () async {
        final paths = <String>[];
        final mock = MockClient((request) async {
          paths.add('${request.method} ${request.url.path}');
          final path = request.url.path;
          if (request.method == 'DELETE' &&
              path == '/api/v1/mine/videos/vid-same') {
            return http.Response(
              '{}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'POST' && path == '/api/v1/mine/videos') {
            return http.Response(
              jsonEncode({
                'video': {
                  'id': 'vid-same',
                  'vid': 'hash-1',
                  'provider': 'user',
                  'title': 'Local',
                  'duration': 1,
                  'language': 'en',
                  'updated_at': '2026-07-01T00:00:00.000Z',
                  'created_at': '2026-07-01T00:00:00.000Z',
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('unexpected ${request.method} $path', 500);
        });

        final client = ApiClient(
          httpClient: mock,
          getBaseUrl: () async => 'https://enjoy.example.com',
          getAccessToken: () async => 'tok',
        );
        final db = AppDatabase(executor: NativeDatabase.memory());
        addTearDown(db.close);
        final queue = SyncQueueRepository(db);
        final upload = SyncUploadService(
          db: db,
          audioApi: AudioApi(client),
          videoApi: VideoApi(client),
          recordingApi: RecordingApi(client),
          vocabularyApi: VocabularyApi(client),
        );
        final download = SyncDownloadService(
          db: db,
          audioApi: AudioApi(client),
          videoApi: VideoApi(client),
          recordingApi: RecordingApi(client),
          vocabularyApi: VocabularyApi(client),
        );
        final engine = SyncEngine(
          db: db,
          queue: queue,
          upload: upload,
          download: download,
        );

        final now = DateTime.utc(2026, 7, 1);
        await db.videoDao.insertRow(
          VideoRow(
            id: 'vid-same',
            vid: 'hash-1',
            provider: 'user',
            title: 'Local',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 1,
            language: 'en',
            source: null,
            localUri: 'file:///x.mp4',
            md5: 'hash-1',
            size: 10,
            mediaUrl: null,
            syncStatus: 'pending',
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );

        // Create enqueued after delete (re-import), but create has earlier
        // createdAt so naive oldest-first would POST first without sort.
        await queue.addOrUpsert(
          entityType: 'video',
          entityId: 'vid-same',
          action: 'create',
          payloadJson: '{}',
        );
        await Future<void>.delayed(const Duration(milliseconds: 2));
        await queue.addOrUpsert(
          entityType: 'video',
          entityId: 'vid-same',
          action: 'delete',
        );

        final result = await engine.processQueue(const SyncOptions());
        expect(result.success, isTrue);
        expect(result.synced, 2);
        expect(paths, [
          'DELETE /api/v1/mine/videos/vid-same',
          'POST /api/v1/mine/videos',
        ]);
        expect(await queue.pendingItems(), isEmpty);
      },
    );

    test('overlapping processQueue calls coalesce', () async {
      var deleteCalls = 0;
      final started = Completer<void>();
      final release = Completer<void>();
      final mock = MockClient((request) async {
        if (request.method == 'DELETE') {
          deleteCalls++;
          if (!started.isCompleted) started.complete();
          await release.future;
          return http.Response(
            '{}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected', 500);
      });

      final client = ApiClient(
        httpClient: mock,
        getBaseUrl: () async => 'https://enjoy.example.com',
        getAccessToken: () async => 'tok',
      );
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final queue = SyncQueueRepository(db);
      final engine = SyncEngine(
        db: db,
        queue: queue,
        upload: SyncUploadService(
          db: db,
          audioApi: AudioApi(client),
          videoApi: VideoApi(client),
          recordingApi: RecordingApi(client),
          vocabularyApi: VocabularyApi(client),
        ),
        download: SyncDownloadService(
          db: db,
          audioApi: AudioApi(client),
          videoApi: VideoApi(client),
          recordingApi: RecordingApi(client),
          vocabularyApi: VocabularyApi(client),
        ),
      );

      await queue.addOrUpsert(
        entityType: 'video',
        entityId: 'v1',
        action: 'delete',
      );

      final first = engine.processQueue(const SyncOptions());
      await started.future;

      await queue.addOrUpsert(
        entityType: 'video',
        entityId: 'v2',
        action: 'delete',
      );
      final second = engine.processQueue(const SyncOptions());

      release.complete();
      final results = await Future.wait([first, second]);
      expect(results.every((r) => r.success), isTrue);
      expect(deleteCalls, 2);
      expect(await queue.pendingItems(), isEmpty);
    });
  });

  group('scheduleSyncQueueDrain + SyncEngine', () {
    test(
      'drain scheduled inside transaction successfully removes queue row',
      () async {
        final mock = MockClient((request) async {
          if (request.method == 'DELETE') {
            return http.Response(
              '{}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('unexpected', 500);
        });
        final client = ApiClient(
          httpClient: mock,
          getBaseUrl: () async => 'https://enjoy.example.com',
          getAccessToken: () async => 'tok',
        );
        final db = AppDatabase(executor: NativeDatabase.memory());
        addTearDown(db.close);
        final queue = SyncQueueRepository(db);
        final engine = SyncEngine(
          db: db,
          queue: queue,
          upload: SyncUploadService(
            db: db,
            audioApi: AudioApi(client),
            videoApi: VideoApi(client),
            recordingApi: RecordingApi(client),
            vocabularyApi: VocabularyApi(client),
          ),
          download: SyncDownloadService(
            db: db,
            audioApi: AudioApi(client),
            videoApi: VideoApi(client),
            recordingApi: RecordingApi(client),
            vocabularyApi: VocabularyApi(client),
          ),
        );

        await db.transaction(() async {
          await queue.addOrUpsert(
            entityType: 'video',
            entityId: 'v-sched',
            action: 'delete',
          );
          scheduleSyncQueueDrain(engine);
        });

        // Allow Duration.zero drain + processQueue to finish.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        for (var i = 0; i < 20; i++) {
          if ((await queue.pendingItems()).isEmpty) break;
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        expect(await queue.pendingItems(), isEmpty);
      },
    );
  });
}
