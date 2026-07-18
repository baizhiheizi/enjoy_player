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
    'uploadVocabularyItem refetches when create returns success-only body',
    () async {
      final paths = <String>[];
      final mock = MockClient((request) async {
        paths.add('${request.method} ${request.url.path}');
        final path = request.url.path;
        if (request.method == 'POST' &&
            path == '/api/v1/mine/vocabulary_items') {
          return http.Response(
            '{"success":true}',
            200,
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
              'updated_at': '2026-07-02T00:00:00.000Z',
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
      final row = VocabularyItemRow(
        id: 'item-1',
        word: 'hello',
        language: 'en',
        targetLanguage: 'zh',
        status: 'new',
        easeFactor: 2.5,
        interval: 0,
        nextReviewAt: now,
        reviewsCount: 0,
        lastReviewedAt: null,
        contextsCount: 1,
        explanation: null,
        syncStatus: 'pending',
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      );
      await db.vocabularyItemDao.insertRow(row);

      final upload = SyncUploadService(
        db: db,
        audioApi: AudioApi(client),
        videoApi: VideoApi(client),
        recordingApi: RecordingApi(client),
        vocabularyApi: VocabularyApi(client),
      );

      await upload.uploadVocabularyItem(row);

      expect(paths, [
        'POST /api/v1/mine/vocabulary_items',
        'GET /api/v1/mine/vocabulary_items/item-1',
      ]);
      final saved = await db.vocabularyItemDao.getById('item-1');
      expect(saved?.syncStatus, 'synced');
      expect(saved?.serverUpdatedAt?.toUtc(), DateTime.utc(2026, 7, 2));
    },
  );

  test(
    'uploadVocabularyContext refetches when create returns success-only body',
    () async {
      final paths = <String>[];
      final mock = MockClient((request) async {
        paths.add('${request.method} ${request.url.path}');
        final path = request.url.path;
        if (request.method == 'POST' &&
            path == '/api/v1/mine/vocabulary_contexts') {
          return http.Response(
            '{"success":true}',
            200,
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
              'updated_at': '2026-07-03T00:00:00.000Z',
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
      final row = VocabularyContextRow(
        id: 'ctx-1',
        vocabularyItemId: 'item-1',
        contextText: 'hello world',
        sourceType: 'Video',
        sourceId: 'vid-1',
        locatorJson: '{"start":0,"duration":1}',
        explanation: null,
        syncStatus: 'pending',
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      );
      await db.vocabularyContextDao.insertRow(row);

      final upload = SyncUploadService(
        db: db,
        audioApi: AudioApi(client),
        videoApi: VideoApi(client),
        recordingApi: RecordingApi(client),
        vocabularyApi: VocabularyApi(client),
      );

      await upload.uploadVocabularyContext(row);

      expect(paths, [
        'POST /api/v1/mine/vocabulary_contexts',
        'GET /api/v1/mine/vocabulary_contexts/ctx-1',
      ]);
      final saved = await db.vocabularyContextDao.getById('ctx-1');
      expect(saved?.syncStatus, 'synced');
      expect(saved?.serverUpdatedAt?.toUtc(), DateTime.utc(2026, 7, 3));
    },
  );
}
