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
import 'package:enjoy_player/features/sync/data/sync_upload_service.dart';

void main() {
  test(
    'uploadVideo recovers via mine GET when create hits a unique race',
    () async {
      final paths = <String>[];
      final mock = MockClient((request) async {
        paths.add('${request.method} ${request.url.path}');
        final path = request.url.path;
        if (request.method == 'POST' && path == '/api/v1/mine/videos') {
          return http.Response(
            jsonEncode(
              'PG::UniqueViolation: ERROR: duplicate key value violates '
              'unique constraint "videos_pkey"\nDETAIL: Key (id)=(vid-1) '
              'already exists.\n',
            ),
            400,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' && path == '/api/v1/mine/videos/vid-1') {
          return http.Response(
            jsonEncode({
              'id': 'vid-1',
              'vid': 'dQw4w9WgXcQ',
              'provider': 'youtube',
              'title': 'Catalog',
              'duration': 12,
              'language': 'en',
              'updated_at': '2026-07-01T00:00:00.000Z',
              'created_at': '2026-07-01T00:00:00.000Z',
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

      final now = DateTime.utc(2026, 6, 1);
      final row = VideoRow(
        id: 'vid-1',
        vid: 'dQw4w9WgXcQ',
        provider: 'youtube',
        title: 'Local',
        description: null,
        thumbnailUrl: null,
        durationSeconds: 12,
        language: 'en',
        source: 'youtube',
        localUri: null,
        md5: null,
        size: null,
        mediaUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        syncStatus: 'pending',
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      );
      await db.videoDao.insertRow(row);

      final upload = SyncUploadService(
        db: db,
        audioApi: AudioApi(client),
        videoApi: VideoApi(client),
        recordingApi: RecordingApi(client),
        vocabularyApi: VocabularyApi(client),
      );

      await upload.uploadVideo(row);

      expect(paths, [
        'POST /api/v1/mine/videos',
        'GET /api/v1/mine/videos/vid-1',
      ]);

      final saved = await db.videoDao.getById('vid-1');
      expect(saved, isNotNull);
      expect(saved!.syncStatus, 'synced');
      expect(saved.serverUpdatedAt?.toUtc(), DateTime.utc(2026, 7, 1));
    },
  );

  test(
    'uploadVideo throws SyncDuplicateMissingError when mine GET 404s after race',
    () async {
      final mock = MockClient((request) async {
        final path = request.url.path;
        if (request.method == 'POST' && path == '/api/v1/mine/videos') {
          return http.Response(
            jsonEncode('Key (id)=(missing) already exists.'),
            400,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('null', 404);
      });

      final client = ApiClient(
        httpClient: mock,
        getBaseUrl: () async => 'https://enjoy.example.com',
        getAccessToken: () async => 'tok',
      );
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);

      final now = DateTime.utc(2026, 6, 1);
      final row = VideoRow(
        id: 'missing',
        vid: 'abcdefghijk',
        provider: 'youtube',
        title: 'Gone',
        description: null,
        thumbnailUrl: null,
        durationSeconds: 1,
        language: 'en',
        source: 'youtube',
        localUri: null,
        md5: null,
        size: null,
        mediaUrl: null,
        syncStatus: 'pending',
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      );

      final upload = SyncUploadService(
        db: db,
        audioApi: AudioApi(client),
        videoApi: VideoApi(client),
        recordingApi: RecordingApi(client),
        vocabularyApi: VocabularyApi(client),
      );

      await expectLater(
        upload.uploadVideo(row),
        throwsA(isA<SyncDuplicateMissingError>()),
      );
    },
  );
}
