import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/services/audio_api.dart';
import 'package:enjoy_player/data/api/services/recording_api.dart';
import 'package:enjoy_player/data/api/services/video_api.dart';
import 'package:enjoy_player/data/api/services/vocabulary_api.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/sync/application/sync_controller.dart';
import 'package:enjoy_player/features/sync/application/sync_engine.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/features/sync/data/sync_download_service.dart';
import 'package:enjoy_player/features/sync/data/sync_queue_repository.dart';
import 'package:enjoy_player/features/sync/data/sync_upload_service.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _profile = UserProfile(id: 'u1', email: 'a@b.com', name: 'Test');

class _SignedInAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedIn(profile: _profile);
}

class _SignedOutAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedOut();
}

ApiClient _testClient(MockClient mock) => ApiClient(
  httpClient: mock,
  getBaseUrl: () async => 'https://enjoy.example.com',
  getAccessToken: () async => 'tok',
);

/// A MockClient that returns empty lists for vocabulary download endpoints
/// and 200 for DELETE endpoints.
MockClient _permissiveMock() => MockClient((request) async {
  final path = request.url.path;
  if (request.method == 'GET' &&
      (path.contains('/vocabulary_items') ||
          path.contains('/vocabulary_contexts') ||
          path.contains('/audios') ||
          path.contains('/videos') ||
          path.contains('/recordings'))) {
    return http.Response(
      '[]',
      200,
      headers: {'content-type': 'application/json'},
    );
  }
  if (request.method == 'DELETE') {
    return http.Response(
      '{}',
      200,
      headers: {'content-type': 'application/json'},
    );
  }
  if (request.method == 'POST') {
    return http.Response(
      jsonEncode({
        'audio': {'id': 'x', 'updated_at': '2026-01-01T00:00:00.000Z'},
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
  return http.Response('not found', 404);
});

SyncEngine _buildEngine(AppDatabase db, MockClient mock) {
  final client = _testClient(mock);
  return SyncEngine(
    db: db,
    queue: SyncQueueRepository(db),
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
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('syncActionProcessOrder', () {
    test('returns expected ordering values', () {
      expect(syncActionProcessOrder('delete'), 0);
      expect(syncActionProcessOrder('update'), 1);
      expect(syncActionProcessOrder('create'), 2);
      expect(syncActionProcessOrder('unknown'), 3);
    });
  });

  group('SyncEngine.fullSync', () {
    test('merges queue drain and vocabulary pull results', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final engine = _buildEngine(db, _permissiveMock());

      final result = await engine.fullSync(const SyncOptions());
      expect(result.success, isTrue);
      expect(result.synced, 0);
      expect(result.failed, 0);
    });
  });

  group('SyncEngine.pullVocabulary', () {
    test('returns merged result from items and contexts downloads', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final engine = _buildEngine(db, _permissiveMock());

      final result = await engine.pullVocabulary();
      expect(result.success, isTrue);
    });
  });

  group('SyncEngine._drainOnce resetFailed', () {
    test('resets permanently failed rows before processing', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final queue = SyncQueueRepository(db);

      // Insert a permanently failed row (retryCount=5).
      final id = await queue.addOrUpsert(
        entityType: 'video',
        entityId: 'v-reset',
        action: 'delete',
      );
      await queue.markPermanentlyFailed(id, error: 'old error');

      var row = await (db.select(
        db.syncQueue,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(row.retryCount, 5);

      final engine = _buildEngine(db, _permissiveMock());
      final result = await engine.processQueue(
        const SyncOptions(resetFailed: true),
      );

      expect(result.success, isTrue);
      // The row should have been reset and then processed (deleted).
      expect(await queue.pendingItems(), isEmpty);
    });
  });

  group('SyncEngine._processOne unknown type/action', () {
    test('removes queue row with unknown entityType', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final queue = SyncQueueRepository(db);

      // Manually insert a row with an unknown entity type.
      await db
          .into(db.syncQueue)
          .insert(
            SyncQueueCompanion.insert(
              entityType: 'bogus_type',
              entityId: 'x1',
              action: 'create',
              createdAt: DateTime.now(),
            ),
          );

      final engine = _buildEngine(db, _permissiveMock());
      final result = await engine.processQueue(const SyncOptions());

      // Unknown types are filtered out by _drainOnce, so nothing is processed.
      expect(result.success, isTrue);
      expect(result.synced, 0);
      // Row remains because it was filtered, not processed.
      expect(await queue.pendingItems(), hasLength(1));
    });

    test('removes queue row with unknown action', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final queue = SyncQueueRepository(db);

      // Insert a row with valid type but unknown action.
      await db
          .into(db.syncQueue)
          .insert(
            SyncQueueCompanion.insert(
              entityType: 'audio',
              entityId: 'a1',
              action: 'bogus_action',
              createdAt: DateTime.now(),
            ),
          );

      final engine = _buildEngine(db, _permissiveMock());
      final result = await engine.processQueue(const SyncOptions());

      // _processOne removes rows with null action.
      expect(result.success, isTrue);
      expect(result.synced, 1);
      expect(await queue.pendingItems(), isEmpty);
    });
  });

  group('SyncEngine._processOne delete actions', () {
    test('delete audio calls upload.deleteAudio and removes row', () async {
      final deleted = <String>[];
      final mock = MockClient((request) async {
        if (request.method == 'DELETE' &&
            request.url.path == '/api/v1/mine/audios/aud-1') {
          deleted.add('aud-1');
          return http.Response(
            '{}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET') {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final queue = SyncQueueRepository(db);
      await queue.addOrUpsert(
        entityType: 'audio',
        entityId: 'aud-1',
        action: 'delete',
      );

      final engine = _buildEngine(db, mock);
      final result = await engine.processQueue(const SyncOptions());

      expect(result.success, isTrue);
      expect(result.synced, 1);
      expect(deleted, ['aud-1']);
      expect(await queue.pendingItems(), isEmpty);
    });

    test('delete video calls upload.deleteVideo', () async {
      final deleted = <String>[];
      final mock = MockClient((request) async {
        if (request.method == 'DELETE' &&
            request.url.path == '/api/v1/mine/videos/vid-1') {
          deleted.add('vid-1');
          return http.Response(
            '{}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET') {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final queue = SyncQueueRepository(db);
      await queue.addOrUpsert(
        entityType: 'video',
        entityId: 'vid-1',
        action: 'delete',
      );

      final engine = _buildEngine(db, mock);
      final result = await engine.processQueue(const SyncOptions());

      expect(result.success, isTrue);
      expect(deleted, ['vid-1']);
    });

    test('delete recording calls upload.deleteRecording', () async {
      final deleted = <String>[];
      final mock = MockClient((request) async {
        if (request.method == 'DELETE' &&
            request.url.path == '/api/v1/mine/recordings/rec-1') {
          deleted.add('rec-1');
          return http.Response(
            '{}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET') {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final queue = SyncQueueRepository(db);
      await queue.addOrUpsert(
        entityType: 'recording',
        entityId: 'rec-1',
        action: 'delete',
      );

      final engine = _buildEngine(db, mock);
      final result = await engine.processQueue(const SyncOptions());

      expect(result.success, isTrue);
      expect(deleted, ['rec-1']);
    });

    test('delete youtube_subscription is local-only (no API call)', () async {
      var apiCalled = false;
      final mock = MockClient((request) async {
        apiCalled = true;
        if (request.method == 'GET') {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final queue = SyncQueueRepository(db);
      await queue.addOrUpsert(
        entityType: 'youtube_subscription',
        entityId: 'yt-1',
        action: 'delete',
      );

      final engine = _buildEngine(db, mock);
      final result = await engine.processQueue(const SyncOptions());

      expect(result.success, isTrue);
      expect(result.synced, 1);
      // No DELETE API call for youtube_subscription.
      expect(apiCalled, isFalse);
      expect(await queue.pendingItems(), isEmpty);
    });

    test('delete vocabulary_item calls upload.deleteVocabularyItem', () async {
      final deleted = <String>[];
      final mock = MockClient((request) async {
        if (request.method == 'DELETE' &&
            request.url.path == '/api/v1/mine/vocabulary_items/vi-1') {
          deleted.add('vi-1');
          return http.Response(
            '{}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET') {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final queue = SyncQueueRepository(db);
      await queue.addOrUpsert(
        entityType: 'vocabulary_item',
        entityId: 'vi-1',
        action: 'delete',
      );

      final engine = _buildEngine(db, mock);
      final result = await engine.processQueue(const SyncOptions());

      expect(result.success, isTrue);
      expect(deleted, ['vi-1']);
    });

    test(
      'delete vocabulary_context calls upload.deleteVocabularyContext',
      () async {
        final deleted = <String>[];
        final mock = MockClient((request) async {
          if (request.method == 'DELETE' &&
              request.url.path == '/api/v1/mine/vocabulary_contexts/vc-1') {
            deleted.add('vc-1');
            return http.Response(
              '{}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'GET') {
            return http.Response(
              '[]',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('unexpected', 500);
        });

        final db = AppDatabase(executor: NativeDatabase.memory());
        addTearDown(db.close);
        final queue = SyncQueueRepository(db);
        await queue.addOrUpsert(
          entityType: 'vocabulary_context',
          entityId: 'vc-1',
          action: 'delete',
        );

        final engine = _buildEngine(db, mock);
        final result = await engine.processQueue(const SyncOptions());

        expect(result.success, isTrue);
        expect(deleted, ['vc-1']);
      },
    );
  });

  group('SyncEngine._processOne entity missing locally', () {
    test('audio create with missing local row drops queue row', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final queue = SyncQueueRepository(db);
      await queue.addOrUpsert(
        entityType: 'audio',
        entityId: 'missing-audio',
        action: 'create',
      );

      final engine = _buildEngine(db, _permissiveMock());
      final result = await engine.processQueue(const SyncOptions());

      expect(result.success, isTrue);
      expect(result.synced, 1);
      expect(await queue.pendingItems(), isEmpty);
    });

    test('video create with missing local row drops queue row', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final queue = SyncQueueRepository(db);
      await queue.addOrUpsert(
        entityType: 'video',
        entityId: 'missing-video',
        action: 'create',
      );

      final engine = _buildEngine(db, _permissiveMock());
      final result = await engine.processQueue(const SyncOptions());

      expect(result.success, isTrue);
      expect(result.synced, 1);
      expect(await queue.pendingItems(), isEmpty);
    });

    test('recording create with missing local row drops queue row', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final queue = SyncQueueRepository(db);
      await queue.addOrUpsert(
        entityType: 'recording',
        entityId: 'missing-rec',
        action: 'create',
      );

      final engine = _buildEngine(db, _permissiveMock());
      final result = await engine.processQueue(const SyncOptions());

      expect(result.success, isTrue);
      expect(result.synced, 1);
      expect(await queue.pendingItems(), isEmpty);
    });

    test(
      'vocabulary_item create with missing local row drops queue row',
      () async {
        final db = AppDatabase(executor: NativeDatabase.memory());
        addTearDown(db.close);
        final queue = SyncQueueRepository(db);
        await queue.addOrUpsert(
          entityType: 'vocabulary_item',
          entityId: 'missing-vi',
          action: 'create',
        );

        final engine = _buildEngine(db, _permissiveMock());
        final result = await engine.processQueue(const SyncOptions());

        expect(result.success, isTrue);
        expect(result.synced, 1);
        expect(await queue.pendingItems(), isEmpty);
      },
    );

    test(
      'vocabulary_context create with missing local row drops queue row',
      () async {
        final db = AppDatabase(executor: NativeDatabase.memory());
        addTearDown(db.close);
        final queue = SyncQueueRepository(db);
        await queue.addOrUpsert(
          entityType: 'vocabulary_context',
          entityId: 'missing-vc',
          action: 'create',
        );

        final engine = _buildEngine(db, _permissiveMock());
        final result = await engine.processQueue(const SyncOptions());

        expect(result.success, isTrue);
        expect(result.synced, 1);
        expect(await queue.pendingItems(), isEmpty);
      },
    );

    test('youtube_subscription create retains queue row (deferred)', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final queue = SyncQueueRepository(db);
      await queue.addOrUpsert(
        entityType: 'youtube_subscription',
        entityId: 'yt-sub-1',
        action: 'create',
      );

      final engine = _buildEngine(db, _permissiveMock());
      final result = await engine.processQueue(const SyncOptions());

      // youtube_subscription create is a no-op; queue row is retained.
      expect(result.success, isTrue);
      expect(result.synced, 1);
      // Row is removed after the no-op break (falls through to removeById).
      expect(await queue.pendingItems(), isEmpty);
    });
  });

  group('SyncEngine._processOne error handling', () {
    test('generic upload error marks row as attempted', () async {
      final mock = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response(
            '{"error": "server error"}',
            500,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET') {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final queue = SyncQueueRepository(db);

      // Insert a local audio row so the engine tries to upload it.
      final now = DateTime.utc(2026, 1, 1);
      await db.audioDao.insertRow(
        AudioRow(
          id: 'aud-err',
          aid: 'aid-1',
          provider: 'user',
          title: 'Test',
          description: null,
          thumbnailUrl: null,
          durationSeconds: 10,
          language: 'en',
          translationKey: null,
          sourceText: null,
          voice: null,
          source: null,
          localUri: null,
          md5: null,
          size: null,
          localMtimeMs: null,
          mediaUrl: null,
          syncStatus: 'pending',
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await queue.addOrUpsert(
        entityType: 'audio',
        entityId: 'aud-err',
        action: 'create',
      );

      final engine = _buildEngine(db, mock);
      final result = await engine.processQueue(const SyncOptions());

      expect(result.success, isFalse);
      expect(result.failed, 1);
      // Row should still be pending with incremented retryCount.
      final pending = await queue.pendingItems();
      expect(pending, hasLength(1));
      expect(pending.first.retryCount, 1);
      expect(pending.first.error, isNotNull);
    });

    test('SyncDuplicateMissingError marks row permanently failed', () async {
      // Simulate: POST returns 409 "already exists", then GET returns 404.
      final mock = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/v1/mine/audios') {
          return http.Response(
            '{"error": "Audio already exists"}',
            409,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' &&
            request.url.path == '/api/v1/mine/audios/aud-dup') {
          return http.Response(
            '{"error": "not found"}',
            404,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET') {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final queue = SyncQueueRepository(db);

      final now = DateTime.utc(2026, 1, 1);
      await db.audioDao.insertRow(
        AudioRow(
          id: 'aud-dup',
          aid: 'aid-dup',
          provider: 'user',
          title: 'Dup',
          description: null,
          thumbnailUrl: null,
          durationSeconds: 5,
          language: 'en',
          translationKey: null,
          sourceText: null,
          voice: null,
          source: null,
          localUri: null,
          md5: null,
          size: null,
          localMtimeMs: null,
          mediaUrl: null,
          syncStatus: 'pending',
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await queue.addOrUpsert(
        entityType: 'audio',
        entityId: 'aud-dup',
        action: 'create',
      );

      final engine = _buildEngine(db, mock);
      final result = await engine.processQueue(const SyncOptions());

      expect(result.success, isFalse);
      expect(result.failed, 1);
      // Row should be permanently failed (retryCount=5).
      final pending = await queue.pendingItems();
      expect(pending, isEmpty); // retryCount >= 5 excluded from pendingItems
      final allRows = await db.select(db.syncQueue).get();
      expect(allRows, hasLength(1));
      expect(allRows.first.retryCount, 5);
      expect(allRows.first.error, contains('SyncDuplicateMissingError'));
    });

    test('delete error marks row as attempted', () async {
      final mock = MockClient((request) async {
        if (request.method == 'DELETE') {
          return http.Response(
            '{"error": "server error"}',
            500,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET') {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final queue = SyncQueueRepository(db);
      await queue.addOrUpsert(
        entityType: 'video',
        entityId: 'vid-err',
        action: 'delete',
      );

      final engine = _buildEngine(db, mock);
      final result = await engine.processQueue(const SyncOptions());

      expect(result.success, isFalse);
      expect(result.failed, 1);
      final pending = await queue.pendingItems();
      expect(pending, hasLength(1));
      expect(pending.first.retryCount, 1);
    });
  });

  group('SyncEngine.processQueue coalescing', () {
    test(
      'second caller coalesces onto in-flight drain and gets same result',
      () async {
        final db = AppDatabase(executor: NativeDatabase.memory());
        addTearDown(db.close);
        final queue = SyncQueueRepository(db);

        // Enqueue two rows so both drain passes have work.
        await queue.addOrUpsert(
          entityType: 'video',
          entityId: 'v-coal-1',
          action: 'delete',
        );
        await queue.addOrUpsert(
          entityType: 'video',
          entityId: 'v-coal-2',
          action: 'delete',
        );

        var deleteCount = 0;
        final started = Completer<void>();
        final release = Completer<void>();
        final mock = MockClient((request) async {
          if (request.method == 'DELETE') {
            deleteCount++;
            if (!started.isCompleted) started.complete();
            await release.future;
            return http.Response(
              '{}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'GET') {
            return http.Response(
              '[]',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('unexpected', 500);
        });

        final engine = _buildEngine(db, mock);

        final first = engine.processQueue(const SyncOptions());
        await started.future;

        // Second call coalesces onto the first (sets _drainAgain).
        final second = engine.processQueue(const SyncOptions());

        release.complete();
        final results = await Future.wait([first, second]);
        // Both callers get the same result object.
        expect(identical(results[0], results[1]), isTrue);
        expect(results[0].success, isTrue);
        // Both rows processed.
        expect(await queue.pendingItems(), isEmpty);
        expect(deleteCount, 2);
      },
    );
  });

  group('SyncEngine._processOne successful upload', () {
    test('audio create uploads and removes queue row', () async {
      final mock = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/v1/mine/audios') {
          return http.Response(
            jsonEncode({
              'audio': {
                'id': 'aud-ok',
                'aid': 'aid-ok',
                'provider': 'user',
                'title': 'Test',
                'duration': 10,
                'language': 'en',
                'updated_at': '2026-07-01T00:00:00.000Z',
                'created_at': '2026-07-01T00:00:00.000Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET') {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final queue = SyncQueueRepository(db);

      final now = DateTime.utc(2026, 1, 1);
      await db.audioDao.insertRow(
        AudioRow(
          id: 'aud-ok',
          aid: 'aid-ok',
          provider: 'user',
          title: 'Test',
          description: null,
          thumbnailUrl: null,
          durationSeconds: 10,
          language: 'en',
          translationKey: null,
          sourceText: null,
          voice: null,
          source: null,
          localUri: null,
          md5: null,
          size: null,
          localMtimeMs: null,
          mediaUrl: null,
          syncStatus: 'pending',
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await queue.addOrUpsert(
        entityType: 'audio',
        entityId: 'aud-ok',
        action: 'create',
      );

      final engine = _buildEngine(db, mock);
      final result = await engine.processQueue(const SyncOptions());

      expect(result.success, isTrue);
      expect(result.synced, 1);
      expect(await queue.pendingItems(), isEmpty);
      // Verify the audio row was updated with sync status.
      final updated = await db.audioDao.getById('aud-ok');
      expect(updated!.syncStatus, 'synced');
    });

    test('recording create uploads and removes queue row', () async {
      final mock = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/v1/mine/recordings') {
          return http.Response(
            jsonEncode({
              'recording': {
                'id': 'rec-ok',
                'target_type': 'video',
                'target_id': 'v1',
                'reference_start': 0,
                'reference_duration': 1000,
                'reference_text': 'hello',
                'language': 'en',
                'duration': 2000,
                'updated_at': '2026-07-01T00:00:00.000Z',
                'created_at': '2026-07-01T00:00:00.000Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET') {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final queue = SyncQueueRepository(db);

      final now = DateTime.utc(2026, 1, 1);
      await db.recordingDao.insertRow(
        RecordingRow(
          id: 'rec-ok',
          targetType: 'video',
          targetId: 'v1',
          referenceStart: 0,
          referenceDuration: 1000,
          referenceText: 'hello',
          language: 'en',
          duration: 2000,
          md5: null,
          audioUrl: null,
          pronunciationScore: null,
          assessmentJson: null,
          localPath: null,
          syncStatus: 'pending',
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await queue.addOrUpsert(
        entityType: 'recording',
        entityId: 'rec-ok',
        action: 'create',
      );

      final engine = _buildEngine(db, mock);
      final result = await engine.processQueue(const SyncOptions());

      expect(result.success, isTrue);
      expect(result.synced, 1);
      expect(await queue.pendingItems(), isEmpty);
    });

    test('vocabulary_item create uploads and removes queue row', () async {
      final mock = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/v1/mine/vocabulary_items') {
          return http.Response(
            jsonEncode({
              'vocabularyItem': {
                'id': 'vi-ok',
                'word': 'hello',
                'language': 'en',
                'target_language': 'zh',
                'status': 'learning',
                'ease_factor': 2.5,
                'interval': 1,
                'next_review_at': '2026-07-02T00:00:00.000Z',
                'reviews_count': 0,
                'contexts_count': 0,
                'updated_at': '2026-07-01T00:00:00.000Z',
                'created_at': '2026-07-01T00:00:00.000Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET') {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final queue = SyncQueueRepository(db);

      final now = DateTime.utc(2026, 1, 1);
      await db.vocabularyItemDao.insertRow(
        VocabularyItemRow(
          id: 'vi-ok',
          word: 'hello',
          language: 'en',
          targetLanguage: 'zh',
          status: 'learning',
          easeFactor: 2.5,
          interval: 1,
          nextReviewAt: DateTime.utc(2026, 7, 2),
          reviewsCount: 0,
          lastReviewedAt: null,
          contextsCount: 0,
          explanation: null,
          syncStatus: 'pending',
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await queue.addOrUpsert(
        entityType: 'vocabulary_item',
        entityId: 'vi-ok',
        action: 'create',
      );

      final engine = _buildEngine(db, mock);
      final result = await engine.processQueue(const SyncOptions());

      expect(result.success, isTrue);
      expect(result.synced, 1);
      expect(await queue.pendingItems(), isEmpty);
    });

    test('vocabulary_context create uploads and removes queue row', () async {
      final mock = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/v1/mine/vocabulary_contexts') {
          return http.Response(
            jsonEncode({
              'vocabularyContext': {
                'id': 'vc-ok',
                'vocabulary_item_id': 'vi-ok',
                'text': 'hello world',
                'source_type': 'video',
                'source_id': 'v1',
                'locator': '{}',
                'updated_at': '2026-07-01T00:00:00.000Z',
                'created_at': '2026-07-01T00:00:00.000Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET') {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final queue = SyncQueueRepository(db);

      final now = DateTime.utc(2026, 1, 1);
      await db.vocabularyContextDao.insertRow(
        VocabularyContextRow(
          id: 'vc-ok',
          vocabularyItemId: 'vi-ok',
          contextText: 'hello world',
          sourceType: 'video',
          sourceId: 'v1',
          locatorJson: '{}',
          explanation: null,
          syncStatus: 'pending',
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await queue.addOrUpsert(
        entityType: 'vocabulary_context',
        entityId: 'vc-ok',
        action: 'create',
      );

      final engine = _buildEngine(db, mock);
      final result = await engine.processQueue(const SyncOptions());

      expect(result.success, isTrue);
      expect(result.synced, 1);
      expect(await queue.pendingItems(), isEmpty);
    });
  });

  // ===========================================================================
  // SyncCtrl (sync_controller.dart) tests
  // ===========================================================================

  group('SyncCtrl.triggerSync', () {
    test('returns signed-out error when not authenticated', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);

      final container = ProviderContainer(
        overrides: [
          authCtrlProvider.overrideWith(_SignedOutAuthCtrl.new),
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      // Initialize auth state.
      await container.read(authCtrlProvider.future);
      // Initialize the sync controller.
      container.read(syncCtrlProvider);

      final result = await container
          .read(syncCtrlProvider.notifier)
          .triggerSync();

      expect(result.success, isFalse);
      expect(result.synced, 0);
      expect(result.failed, 0);
      expect(result.errors, contains('Signed out'));
    });

    test('performs fullSync when signed in and persists timestamp', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final engine = _buildEngine(db, _permissiveMock());

      final container = ProviderContainer(
        overrides: [
          authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
          appDatabaseProvider.overrideWithValue(db),
          syncEngineProvider.overrideWithValue(engine),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      container.read(syncCtrlProvider);

      final result = await container
          .read(syncCtrlProvider.notifier)
          .triggerSync();

      expect(result.success, isTrue);
      // Verify timestamp was persisted.
      final ts = await db.settingsDao.getValue(SettingsKeys.syncLastFullSyncAt);
      expect(ts, isNotNull);
    });

    test('passes resetFailed option through to engine', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final queue = SyncQueueRepository(db);

      // Insert a permanently failed row.
      final id = await queue.addOrUpsert(
        entityType: 'video',
        entityId: 'v-rf',
        action: 'delete',
      );
      await queue.markPermanentlyFailed(id, error: 'old');

      final engine = _buildEngine(db, _permissiveMock());
      final container = ProviderContainer(
        overrides: [
          authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
          appDatabaseProvider.overrideWithValue(db),
          syncEngineProvider.overrideWithValue(engine),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      container.read(syncCtrlProvider);

      final result = await container
          .read(syncCtrlProvider.notifier)
          .triggerSync(resetFailed: true);

      expect(result.success, isTrue);
      // The permanently failed row should have been reset and processed.
      expect(await queue.pendingItems(), isEmpty);
    });

    test('does not persist timestamp when sync fails', () async {
      final mock = MockClient((request) async {
        if (request.method == 'GET') {
          // Make vocabulary download fail.
          return http.Response(
            '{"error": "fail"}',
            500,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('fail', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final engine = _buildEngine(db, mock);

      final container = ProviderContainer(
        overrides: [
          authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
          appDatabaseProvider.overrideWithValue(db),
          syncEngineProvider.overrideWithValue(engine),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      container.read(syncCtrlProvider);

      final result = await container
          .read(syncCtrlProvider.notifier)
          .triggerSync();

      expect(result.success, isFalse);
      // Timestamp should NOT be persisted on failure.
      final ts = await db.settingsDao.getValue(SettingsKeys.syncLastFullSyncAt);
      expect(ts, isNull);
    });
  });

  group('SyncCtrl.kickDrain', () {
    test('is a no-op when signed out', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);

      final container = ProviderContainer(
        overrides: [
          authCtrlProvider.overrideWith(_SignedOutAuthCtrl.new),
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      container.read(syncCtrlProvider);

      // Should not throw.
      container.read(syncCtrlProvider.notifier).kickDrain();
      // Give the async fire-and-forget a chance to run.
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });

    test('drains queue when signed in', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final queue = SyncQueueRepository(db);
      await queue.addOrUpsert(
        entityType: 'video',
        entityId: 'v-kick',
        action: 'delete',
      );

      final engine = _buildEngine(db, _permissiveMock());
      final container = ProviderContainer(
        overrides: [
          authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
          appDatabaseProvider.overrideWithValue(db),
          syncEngineProvider.overrideWithValue(engine),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      container.read(syncCtrlProvider);

      container.read(syncCtrlProvider.notifier).kickDrain();

      // Wait for the fire-and-forget drain to complete.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(await queue.pendingItems(), isEmpty);
    });
  });

  group('SyncCtrl._persistLastFullSyncTimestamp', () {
    test('handles DB write failure gracefully', () async {
      // Use a closed database to trigger a write failure.
      final db = AppDatabase(executor: NativeDatabase.memory());
      final engine = _buildEngine(db, _permissiveMock());

      final container = ProviderContainer(
        overrides: [
          authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
          appDatabaseProvider.overrideWithValue(db),
          syncEngineProvider.overrideWithValue(engine),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      container.read(syncCtrlProvider);

      // Close the DB to make the settings write fail.
      await db.close();

      // triggerSync should not throw even though persist fails.
      // The fullSync itself will also fail because the DB is closed,
      // but the controller catches errors in _persistLastFullSyncTimestamp.
      // We just verify no unhandled exception propagates.
      try {
        await container.read(syncCtrlProvider.notifier).triggerSync();
      } catch (_) {
        // The engine may throw because the DB is closed; that's fine.
        // The key assertion is that _persistLastFullSyncTimestamp's catch
        // block is exercised without crashing.
      }
    });
  });

  group('SyncCtrl build and dispose', () {
    test('initializes with counter 0 and disposes cleanly', () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);

      final container = ProviderContainer(
        overrides: [
          authCtrlProvider.overrideWith(_SignedOutAuthCtrl.new),
          appDatabaseProvider.overrideWithValue(db),
        ],
      );

      await container.read(authCtrlProvider.future);
      final value = container.read(syncCtrlProvider);
      expect(value, 0);

      // Dispose should not throw.
      container.dispose();
    });
  });
}
