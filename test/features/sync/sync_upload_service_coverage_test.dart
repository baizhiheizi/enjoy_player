import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/services/audio_api.dart';
import 'package:enjoy_player/data/api/services/recording_api.dart';
import 'package:enjoy_player/data/api/services/video_api.dart';
import 'package:enjoy_player/data/api/services/vocabulary_api.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/sync/data/sync_upload_service.dart';

ApiClient _client(MockClient mock) => ApiClient(
  httpClient: mock,
  getBaseUrl: () async => 'https://enjoy.example.com',
  getAccessToken: () async => 'tok',
);

SyncUploadService _service(AppDatabase db, ApiClient client) =>
    SyncUploadService(
      db: db,
      audioApi: AudioApi(client),
      videoApi: VideoApi(client),
      recordingApi: RecordingApi(client),
      vocabularyApi: VocabularyApi(client),
    );

final _now = DateTime.utc(2026, 6, 1);

AudioRow _audioRow({String id = 'aud-1', String? mediaUrl}) => AudioRow(
  id: id,
  aid: id,
  provider: 'user',
  title: 'Test Audio',
  description: null,
  thumbnailUrl: null,
  durationSeconds: 30,
  language: 'en',
  translationKey: null,
  sourceText: null,
  voice: null,
  source: null,
  localUri: null,
  localMtimeMs: null,
  md5: null,
  size: null,
  mediaUrl: mediaUrl,
  syncStatus: 'pending',
  serverUpdatedAt: null,
  createdAt: _now,
  updatedAt: _now,
);

VideoRow _videoRow({String id = 'vid-1', String? mediaUrl}) => VideoRow(
  id: id,
  vid: 'dQw4w9WgXcQ',
  provider: 'youtube',
  title: 'Test Video',
  description: null,
  thumbnailUrl: null,
  durationSeconds: 120,
  language: 'en',
  source: 'youtube',
  localUri: null,
  md5: null,
  size: null,
  mediaUrl: mediaUrl,
  syncStatus: 'pending',
  serverUpdatedAt: null,
  createdAt: _now,
  updatedAt: _now,
);

RecordingRow _recordingRow({String id = 'rec-1', String? audioUrl}) =>
    RecordingRow(
      id: id,
      targetType: 'Audio',
      targetId: 'aud-1',
      referenceStart: 0,
      referenceDuration: 5000,
      referenceText: 'hello world',
      language: 'en',
      duration: 3000,
      md5: null,
      audioUrl: audioUrl,
      pronunciationScore: null,
      assessmentJson: null,
      localPath: null,
      syncStatus: 'pending',
      serverUpdatedAt: null,
      createdAt: _now,
      updatedAt: _now,
    );

VocabularyItemRow _vocabItemRow({String id = 'item-1'}) => VocabularyItemRow(
  id: id,
  word: 'hello',
  language: 'en',
  targetLanguage: 'zh',
  status: 'new',
  easeFactor: 2.5,
  interval: 0,
  nextReviewAt: _now,
  reviewsCount: 0,
  lastReviewedAt: null,
  contextsCount: 1,
  explanation: null,
  syncStatus: 'pending',
  serverUpdatedAt: null,
  createdAt: _now,
  updatedAt: _now,
);

VocabularyContextRow _vocabContextRow({String id = 'ctx-1'}) =>
    VocabularyContextRow(
      id: id,
      vocabularyItemId: 'item-1',
      contextText: 'hello world',
      sourceType: 'Video',
      sourceId: 'vid-1',
      locatorJson: '{"start":0,"duration":1}',
      explanation: null,
      syncStatus: 'pending',
      serverUpdatedAt: null,
      createdAt: _now,
      updatedAt: _now,
    );

void main() {
  group('SyncMissingUpdatedAtError', () {
    test('toString includes entity and id', () {
      final err = SyncMissingUpdatedAtError('audio', 'aud-1');
      expect(err.toString(), contains('audio'));
      expect(err.toString(), contains('aud-1'));
      expect(err.toString(), contains('updatedAt'));
    });
  });

  group('uploadAudio', () {
    test('happy path persists synced row with server updatedAt', () async {
      final mock = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/v1/mine/audios') {
          return http.Response(
            jsonEncode({
              'audio': {
                'id': 'aud-1',
                'aid': 'aud-1',
                'provider': 'user',
                'title': 'Test Audio',
                'duration': 30,
                'language': 'en',
                'media_url': 'https://cdn.example.com/aud.mp3',
                'updated_at': '2026-07-01T00:00:00.000Z',
                'created_at': '2026-06-01T00:00:00.000Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final row = _audioRow();
      await db.audioDao.insertRow(row);

      final upload = _service(db, _client(mock));
      await upload.uploadAudio(row);

      final saved = await db.audioDao.getById('aud-1');
      expect(saved, isNotNull);
      expect(saved!.syncStatus, 'synced');
      expect(saved.serverUpdatedAt?.toUtc(), DateTime.utc(2026, 7, 1));
      expect(saved.mediaUrl, 'https://cdn.example.com/aud.mp3');
      expect(saved.updatedAt.toUtc(), DateTime.utc(2026, 7, 1));
    });

    test('preserves local mediaUrl when server omits it', () async {
      final mock = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/v1/mine/audios') {
          return http.Response(
            jsonEncode({
              'audio': {
                'id': 'aud-1',
                'updated_at': '2026-07-01T00:00:00.000Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final row = _audioRow(mediaUrl: 'https://local.example.com/a.mp3');
      await db.audioDao.insertRow(row);

      final upload = _service(db, _client(mock));
      await upload.uploadAudio(row);

      final saved = await db.audioDao.getById('aud-1');
      expect(saved!.mediaUrl, 'https://local.example.com/a.mp3');
    });

    test('recovers via GET when create hits duplicate', () async {
      final paths = <String>[];
      final mock = MockClient((request) async {
        paths.add('${request.method} ${request.url.path}');
        final path = request.url.path;
        if (request.method == 'POST' && path == '/api/v1/mine/audios') {
          return http.Response(
            jsonEncode('Key (id)=(aud-1) already exists.'),
            400,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' && path == '/api/v1/mine/audios/aud-1') {
          return http.Response(
            jsonEncode({
              'id': 'aud-1',
              'aid': 'aud-1',
              'provider': 'user',
              'title': 'Existing',
              'duration': 30,
              'language': 'en',
              'updated_at': '2026-07-02T00:00:00.000Z',
              'created_at': '2026-06-01T00:00:00.000Z',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected ${request.method} $path', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final row = _audioRow();
      await db.audioDao.insertRow(row);

      final upload = _service(db, _client(mock));
      await upload.uploadAudio(row);

      expect(paths, [
        'POST /api/v1/mine/audios',
        'GET /api/v1/mine/audios/aud-1',
      ]);
      final saved = await db.audioDao.getById('aud-1');
      expect(saved!.syncStatus, 'synced');
      expect(saved.serverUpdatedAt?.toUtc(), DateTime.utc(2026, 7, 2));
    });

    test(
      'throws SyncDuplicateMissingError when GET 404s after duplicate',
      () async {
        final mock = MockClient((request) async {
          final path = request.url.path;
          if (request.method == 'POST' && path == '/api/v1/mine/audios') {
            return http.Response(
              jsonEncode('Key (id)=(aud-1) already exists.'),
              400,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('null', 404);
        });

        final db = AppDatabase(executor: NativeDatabase.memory());
        addTearDown(db.close);
        final row = _audioRow();

        final upload = _service(db, _client(mock));
        await expectLater(
          upload.uploadAudio(row),
          throwsA(isA<SyncDuplicateMissingError>()),
        );
      },
    );

    test('rethrows non-duplicate ApiException from create', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Internal Server Error'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final row = _audioRow();

      final upload = _service(db, _client(mock));
      await expectLater(
        upload.uploadAudio(row),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('rethrows non-404 ApiException from fallback GET', () async {
      final mock = MockClient((request) async {
        final path = request.url.path;
        if (request.method == 'POST' && path == '/api/v1/mine/audios') {
          return http.Response(
            jsonEncode('Key (id)=(aud-1) already exists.'),
            400,
            headers: {'content-type': 'application/json'},
          );
        }
        // GET returns 500, not 404
        return http.Response(
          jsonEncode({'error': 'server error'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final row = _audioRow();

      final upload = _service(db, _client(mock));
      await expectLater(
        upload.uploadAudio(row),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test(
      'throws SyncMissingUpdatedAtError when response lacks updatedAt',
      () async {
        final mock = MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.path == '/api/v1/mine/audios') {
            return http.Response(
              jsonEncode({
                'audio': {'id': 'aud-1', 'title': 'No date'},
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('unexpected', 500);
        });

        final db = AppDatabase(executor: NativeDatabase.memory());
        addTearDown(db.close);
        final row = _audioRow();

        final upload = _service(db, _client(mock));
        await expectLater(
          upload.uploadAudio(row),
          throwsA(isA<SyncMissingUpdatedAtError>()),
        );
      },
    );
  });

  group('uploadVideo', () {
    test('happy path persists synced row', () async {
      final mock = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/v1/mine/videos') {
          return http.Response(
            jsonEncode({
              'video': {
                'id': 'vid-1',
                'vid': 'dQw4w9WgXcQ',
                'provider': 'youtube',
                'title': 'Test Video',
                'duration': 120,
                'language': 'en',
                'media_url': 'https://cdn.example.com/v.mp4',
                'updated_at': '2026-07-01T00:00:00.000Z',
                'created_at': '2026-06-01T00:00:00.000Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final row = _videoRow();
      await db.videoDao.insertRow(row);

      final upload = _service(db, _client(mock));
      await upload.uploadVideo(row);

      final saved = await db.videoDao.getById('vid-1');
      expect(saved, isNotNull);
      expect(saved!.syncStatus, 'synced');
      expect(saved.serverUpdatedAt?.toUtc(), DateTime.utc(2026, 7, 1));
      expect(saved.mediaUrl, 'https://cdn.example.com/v.mp4');
    });

    test('preserves local mediaUrl when server omits it', () async {
      final mock = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/v1/mine/videos') {
          return http.Response(
            jsonEncode({
              'video': {
                'id': 'vid-1',
                'updated_at': '2026-07-01T00:00:00.000Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final row = _videoRow(mediaUrl: 'https://local.example.com/v.mp4');
      await db.videoDao.insertRow(row);

      final upload = _service(db, _client(mock));
      await upload.uploadVideo(row);

      final saved = await db.videoDao.getById('vid-1');
      expect(saved!.mediaUrl, 'https://local.example.com/v.mp4');
    });

    test('rethrows non-duplicate ApiException from create', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'forbidden'}),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final row = _videoRow();

      final upload = _service(db, _client(mock));
      await expectLater(
        upload.uploadVideo(row),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });

    test('rethrows non-404 ApiException from fallback GET', () async {
      final mock = MockClient((request) async {
        final path = request.url.path;
        if (request.method == 'POST' && path == '/api/v1/mine/videos') {
          return http.Response(
            jsonEncode('Key (id)=(vid-1) already exists.'),
            400,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'error': 'server error'}),
          503,
          headers: {'content-type': 'application/json'},
        );
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final row = _videoRow();

      final upload = _service(db, _client(mock));
      await expectLater(
        upload.uploadVideo(row),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 503),
        ),
      );
    });

    test(
      'throws SyncMissingUpdatedAtError when response lacks updatedAt',
      () async {
        final mock = MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.path == '/api/v1/mine/videos') {
            return http.Response(
              jsonEncode({
                'video': {'id': 'vid-1', 'title': 'No date'},
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('unexpected', 500);
        });

        final db = AppDatabase(executor: NativeDatabase.memory());
        addTearDown(db.close);
        final row = _videoRow();

        final upload = _service(db, _client(mock));
        await expectLater(
          upload.uploadVideo(row),
          throwsA(isA<SyncMissingUpdatedAtError>()),
        );
      },
    );
  });

  group('uploadRecording', () {
    test('happy path persists synced row with audioUrl from server', () async {
      final mock = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/v1/mine/recordings') {
          return http.Response(
            jsonEncode({
              'recording': {
                'id': 'rec-1',
                'target_id': 'aud-1',
                'target_type': 'Audio',
                'duration': 3000,
                'reference_text': 'hello world',
                'reference_start': 0,
                'reference_duration': 5000,
                'language': 'en',
                'audio_url': 'https://cdn.example.com/rec.ogg',
                'updated_at': '2026-07-01T00:00:00.000Z',
                'created_at': '2026-06-01T00:00:00.000Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final row = _recordingRow();
      await db.recordingDao.insertRow(row);

      final upload = _service(db, _client(mock));
      await upload.uploadRecording(row);

      final saved = await db.recordingDao.getById('rec-1');
      expect(saved, isNotNull);
      expect(saved!.syncStatus, 'synced');
      expect(saved.serverUpdatedAt?.toUtc(), DateTime.utc(2026, 7, 1));
      expect(saved.audioUrl, 'https://cdn.example.com/rec.ogg');
      expect(saved.updatedAt.toUtc(), DateTime.utc(2026, 7, 1));
    });

    test('preserves local audioUrl when server omits it', () async {
      final mock = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/v1/mine/recordings') {
          return http.Response(
            jsonEncode({
              'recording': {
                'id': 'rec-1',
                'updated_at': '2026-07-01T00:00:00.000Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final row = _recordingRow(audioUrl: 'https://local.example.com/r.ogg');
      await db.recordingDao.insertRow(row);

      final upload = _service(db, _client(mock));
      await upload.uploadRecording(row);

      final saved = await db.recordingDao.getById('rec-1');
      expect(saved!.audioUrl, 'https://local.example.com/r.ogg');
    });

    test(
      'throws SyncMissingUpdatedAtError when response lacks updatedAt',
      () async {
        final mock = MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.path == '/api/v1/mine/recordings') {
            return http.Response(
              jsonEncode({
                'recording': {'id': 'rec-1'},
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('unexpected', 500);
        });

        final db = AppDatabase(executor: NativeDatabase.memory());
        addTearDown(db.close);
        final row = _recordingRow();

        final upload = _service(db, _client(mock));
        await expectLater(
          upload.uploadRecording(row),
          throwsA(isA<SyncMissingUpdatedAtError>()),
        );
      },
    );

    test('propagates ApiException from upload', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'unauthorized'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final row = _recordingRow();

      final upload = _service(db, _client(mock));
      await expectLater(
        upload.uploadRecording(row),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });
  });

  group('uploadVocabularyItem', () {
    test(
      'happy path with updatedAt in create response skips refetch',
      () async {
        final paths = <String>[];
        final mock = MockClient((request) async {
          paths.add('${request.method} ${request.url.path}');
          if (request.method == 'POST' &&
              request.url.path == '/api/v1/mine/vocabulary_items') {
            return http.Response(
              jsonEncode({
                'vocabulary_item': {
                  'id': 'item-1',
                  'word': 'hello',
                  'language': 'en',
                  'target_language': 'zh',
                  'status': 'new',
                  'ease_factor': 2.5,
                  'interval': 0,
                  'reviews_count': 0,
                  'contexts_count': 1,
                  'next_review_at': '2026-07-01T00:00:00.000Z',
                  'updated_at': '2026-07-02T00:00:00.000Z',
                  'created_at': '2026-06-01T00:00:00.000Z',
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('unexpected ${request.method}', 500);
        });

        final db = AppDatabase(executor: NativeDatabase.memory());
        addTearDown(db.close);
        final row = _vocabItemRow();
        await db.vocabularyItemDao.insertRow(row);

        final upload = _service(db, _client(mock));
        await upload.uploadVocabularyItem(row);

        // Only the POST, no GET refetch needed
        expect(paths, ['POST /api/v1/mine/vocabulary_items']);
        final saved = await db.vocabularyItemDao.getById('item-1');
        expect(saved?.syncStatus, 'synced');
        expect(saved?.serverUpdatedAt?.toUtc(), DateTime.utc(2026, 7, 2));
      },
    );

    test('recovers via GET when create hits duplicate', () async {
      final paths = <String>[];
      final mock = MockClient((request) async {
        paths.add('${request.method} ${request.url.path}');
        final path = request.url.path;
        if (request.method == 'POST' &&
            path == '/api/v1/mine/vocabulary_items') {
          return http.Response(
            jsonEncode('Key (id)=(item-1) already exists.'),
            400,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' &&
            path == '/api/v1/mine/vocabulary_items/item-1') {
          return http.Response(
            jsonEncode({
              'id': 'item-1',
              'word': 'hello',
              'language': 'en',
              'target_language': 'zh',
              'status': 'new',
              'ease_factor': 2.5,
              'interval': 0,
              'reviews_count': 0,
              'contexts_count': 1,
              'next_review_at': '2026-07-01T00:00:00.000Z',
              'updated_at': '2026-07-03T00:00:00.000Z',
              'created_at': '2026-06-01T00:00:00.000Z',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected ${request.method} $path', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final row = _vocabItemRow();
      await db.vocabularyItemDao.insertRow(row);

      final upload = _service(db, _client(mock));
      await upload.uploadVocabularyItem(row);

      expect(paths, [
        'POST /api/v1/mine/vocabulary_items',
        'GET /api/v1/mine/vocabulary_items/item-1',
      ]);
      final saved = await db.vocabularyItemDao.getById('item-1');
      expect(saved?.syncStatus, 'synced');
      expect(saved?.serverUpdatedAt?.toUtc(), DateTime.utc(2026, 7, 3));
    });

    test(
      'throws SyncDuplicateMissingError when GET 404s after duplicate',
      () async {
        final mock = MockClient((request) async {
          final path = request.url.path;
          if (request.method == 'POST' &&
              path == '/api/v1/mine/vocabulary_items') {
            return http.Response(
              jsonEncode('Key (id)=(item-1) already exists.'),
              400,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('null', 404);
        });

        final db = AppDatabase(executor: NativeDatabase.memory());
        addTearDown(db.close);
        final row = _vocabItemRow();

        final upload = _service(db, _client(mock));
        await expectLater(
          upload.uploadVocabularyItem(row),
          throwsA(isA<SyncDuplicateMissingError>()),
        );
      },
    );

    test('rethrows non-duplicate ApiException from create', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'bad request'}),
          422,
          headers: {'content-type': 'application/json'},
        );
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final row = _vocabItemRow();

      final upload = _service(db, _client(mock));
      await expectLater(
        upload.uploadVocabularyItem(row),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422),
        ),
      );
    });

    test('rethrows non-404 ApiException from fallback GET', () async {
      final mock = MockClient((request) async {
        final path = request.url.path;
        if (request.method == 'POST' &&
            path == '/api/v1/mine/vocabulary_items') {
          return http.Response(
            jsonEncode('Key (id)=(item-1) already exists.'),
            400,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'error': 'server error'}),
          502,
          headers: {'content-type': 'application/json'},
        );
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final row = _vocabItemRow();

      final upload = _service(db, _client(mock));
      await expectLater(
        upload.uploadVocabularyItem(row),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 502),
        ),
      );
    });
  });

  group('uploadVocabularyContext', () {
    test(
      'happy path with updatedAt in create response skips refetch',
      () async {
        final paths = <String>[];
        final mock = MockClient((request) async {
          paths.add('${request.method} ${request.url.path}');
          if (request.method == 'POST' &&
              request.url.path == '/api/v1/mine/vocabulary_contexts') {
            return http.Response(
              jsonEncode({
                'vocabulary_context': {
                  'id': 'ctx-1',
                  'vocabulary_item_id': 'item-1',
                  'text': 'hello world',
                  'source_type': 'Video',
                  'source_id': 'vid-1',
                  'locator': {'start': 0, 'duration': 1},
                  'updated_at': '2026-07-03T00:00:00.000Z',
                  'created_at': '2026-06-01T00:00:00.000Z',
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('unexpected ${request.method}', 500);
        });

        final db = AppDatabase(executor: NativeDatabase.memory());
        addTearDown(db.close);
        final row = _vocabContextRow();
        await db.vocabularyContextDao.insertRow(row);

        final upload = _service(db, _client(mock));
        await upload.uploadVocabularyContext(row);

        expect(paths, ['POST /api/v1/mine/vocabulary_contexts']);
        final saved = await db.vocabularyContextDao.getById('ctx-1');
        expect(saved?.syncStatus, 'synced');
        expect(saved?.serverUpdatedAt?.toUtc(), DateTime.utc(2026, 7, 3));
      },
    );

    test('recovers via GET when create hits duplicate', () async {
      final paths = <String>[];
      final mock = MockClient((request) async {
        paths.add('${request.method} ${request.url.path}');
        final path = request.url.path;
        if (request.method == 'POST' &&
            path == '/api/v1/mine/vocabulary_contexts') {
          return http.Response(
            jsonEncode('Key (id)=(ctx-1) already exists.'),
            400,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' &&
            path == '/api/v1/mine/vocabulary_contexts/ctx-1') {
          return http.Response(
            jsonEncode({
              'id': 'ctx-1',
              'vocabulary_item_id': 'item-1',
              'text': 'hello world',
              'source_type': 'Video',
              'source_id': 'vid-1',
              'locator': {'start': 0, 'duration': 1},
              'updated_at': '2026-07-04T00:00:00.000Z',
              'created_at': '2026-06-01T00:00:00.000Z',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('unexpected ${request.method} $path', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final row = _vocabContextRow();
      await db.vocabularyContextDao.insertRow(row);

      final upload = _service(db, _client(mock));
      await upload.uploadVocabularyContext(row);

      expect(paths, [
        'POST /api/v1/mine/vocabulary_contexts',
        'GET /api/v1/mine/vocabulary_contexts/ctx-1',
      ]);
      final saved = await db.vocabularyContextDao.getById('ctx-1');
      expect(saved?.syncStatus, 'synced');
      expect(saved?.serverUpdatedAt?.toUtc(), DateTime.utc(2026, 7, 4));
    });

    test(
      'throws SyncDuplicateMissingError when GET 404s after duplicate',
      () async {
        final mock = MockClient((request) async {
          final path = request.url.path;
          if (request.method == 'POST' &&
              path == '/api/v1/mine/vocabulary_contexts') {
            return http.Response(
              jsonEncode('Key (id)=(ctx-1) already exists.'),
              400,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('null', 404);
        });

        final db = AppDatabase(executor: NativeDatabase.memory());
        addTearDown(db.close);
        final row = _vocabContextRow();

        final upload = _service(db, _client(mock));
        await expectLater(
          upload.uploadVocabularyContext(row),
          throwsA(isA<SyncDuplicateMissingError>()),
        );
      },
    );

    test('rethrows non-duplicate ApiException from create', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'forbidden'}),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final row = _vocabContextRow();

      final upload = _service(db, _client(mock));
      await expectLater(
        upload.uploadVocabularyContext(row),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });

    test('rethrows non-404 ApiException from fallback GET', () async {
      final mock = MockClient((request) async {
        final path = request.url.path;
        if (request.method == 'POST' &&
            path == '/api/v1/mine/vocabulary_contexts') {
          return http.Response(
            jsonEncode('Key (id)=(ctx-1) already exists.'),
            400,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'error': 'bad gateway'}),
          502,
          headers: {'content-type': 'application/json'},
        );
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final row = _vocabContextRow();

      final upload = _service(db, _client(mock));
      await expectLater(
        upload.uploadVocabularyContext(row),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 502),
        ),
      );
    });
  });

  group('deleteAudio', () {
    test('succeeds on 200', () async {
      final mock = MockClient((request) async {
        if (request.method == 'DELETE' &&
            request.url.path == '/api/v1/mine/audios/aud-1') {
          return http.Response('', 204);
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final upload = _service(db, _client(mock));
      await upload.deleteAudio('aud-1');
    });

    test('swallows 404 (already deleted on server)', () async {
      final mock = MockClient((request) async {
        return http.Response('null', 404);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final upload = _service(db, _client(mock));
      await upload.deleteAudio('aud-gone');
    });

    test('rethrows non-404 ApiException', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'server error'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final upload = _service(db, _client(mock));
      await expectLater(
        upload.deleteAudio('aud-1'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });
  });

  group('deleteVideo', () {
    test('succeeds on 200', () async {
      final mock = MockClient((request) async {
        if (request.method == 'DELETE' &&
            request.url.path == '/api/v1/mine/videos/vid-1') {
          return http.Response('', 204);
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final upload = _service(db, _client(mock));
      await upload.deleteVideo('vid-1');
    });

    test('swallows 404', () async {
      final mock = MockClient((request) async {
        return http.Response('null', 404);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final upload = _service(db, _client(mock));
      await upload.deleteVideo('vid-gone');
    });

    test('rethrows non-404 ApiException', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'forbidden'}),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final upload = _service(db, _client(mock));
      await expectLater(
        upload.deleteVideo('vid-1'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });
  });

  group('deleteRecording', () {
    test('succeeds on 200', () async {
      final mock = MockClient((request) async {
        if (request.method == 'DELETE' &&
            request.url.path == '/api/v1/mine/recordings/rec-1') {
          return http.Response('', 204);
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final upload = _service(db, _client(mock));
      await upload.deleteRecording('rec-1');
    });

    test('swallows 404', () async {
      final mock = MockClient((request) async {
        return http.Response('null', 404);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final upload = _service(db, _client(mock));
      await upload.deleteRecording('rec-gone');
    });

    test('rethrows non-404 ApiException', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'server error'}),
          503,
          headers: {'content-type': 'application/json'},
        );
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final upload = _service(db, _client(mock));
      await expectLater(
        upload.deleteRecording('rec-1'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 503),
        ),
      );
    });
  });

  group('deleteVocabularyItem', () {
    test('succeeds on 200', () async {
      final mock = MockClient((request) async {
        if (request.method == 'DELETE' &&
            request.url.path == '/api/v1/mine/vocabulary_items/item-1') {
          return http.Response('', 204);
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final upload = _service(db, _client(mock));
      await upload.deleteVocabularyItem('item-1');
    });

    test('swallows 404', () async {
      final mock = MockClient((request) async {
        return http.Response('null', 404);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final upload = _service(db, _client(mock));
      await upload.deleteVocabularyItem('item-gone');
    });

    test('rethrows non-404 ApiException', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'server error'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final upload = _service(db, _client(mock));
      await expectLater(
        upload.deleteVocabularyItem('item-1'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });
  });

  group('deleteVocabularyContext', () {
    test('succeeds on 200', () async {
      final mock = MockClient((request) async {
        if (request.method == 'DELETE' &&
            request.url.path == '/api/v1/mine/vocabulary_contexts/ctx-1') {
          return http.Response('', 204);
        }
        return http.Response('unexpected', 500);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final upload = _service(db, _client(mock));
      await upload.deleteVocabularyContext('ctx-1');
    });

    test('swallows 404', () async {
      final mock = MockClient((request) async {
        return http.Response('null', 404);
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final upload = _service(db, _client(mock));
      await upload.deleteVocabularyContext('ctx-gone');
    });

    test('rethrows non-404 ApiException', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'forbidden'}),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final upload = _service(db, _client(mock));
      await expectLater(
        upload.deleteVocabularyContext('ctx-1'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });
  });
}
