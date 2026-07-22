import 'package:drift/native.dart';
import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/services/audio_api.dart';
import 'package:enjoy_player/data/api/services/recording_api.dart';
import 'package:enjoy_player/data/api/services/video_api.dart';
import 'package:enjoy_player/data/api/services/vocabulary_api.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/sync/data/sync_download_service.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

final _dummyClient = ApiClient(
  httpClient: http.Client(),
  getBaseUrl: () async => 'http://localhost',
  getAccessToken: () async => null,
);

class _FakeAudioApi extends AudioApi {
  _FakeAudioApi(this._pages) : super(_dummyClient);

  final List<List<Map<String, dynamic>>> _pages;
  int _callCount = 0;

  @override
  Future<List<Map<String, dynamic>>> audios({
    String? provider,
    int? limit,
    String? updatedAfter,
  }) async {
    if (_callCount >= _pages.length) return [];
    return _pages[_callCount++];
  }
}

class _FakeVideoApi extends VideoApi {
  _FakeVideoApi(this._pages) : super(_dummyClient);

  final List<List<Map<String, dynamic>>> _pages;
  int _callCount = 0;

  @override
  Future<List<Map<String, dynamic>>> videos({
    String? provider,
    int? limit,
    String? updatedAfter,
  }) async {
    if (_callCount >= _pages.length) return [];
    return _pages[_callCount++];
  }
}

class _FakeRecordingApi extends RecordingApi {
  _FakeRecordingApi(this._pages) : super(_dummyClient, clientPlatform: 'test');

  final List<List<Map<String, dynamic>>> _pages;
  int _callCount = 0;

  @override
  Future<List<Map<String, dynamic>>> recordings({
    String? targetId,
    String? targetType,
    String? language,
    int? limit,
    String? updatedAfter,
  }) async {
    if (_callCount >= _pages.length) return [];
    return _pages[_callCount++];
  }
}

class _FakeVocabularyApi extends VocabularyApi {
  _FakeVocabularyApi({
    List<List<Map<String, dynamic>>>? itemPages,
    List<List<Map<String, dynamic>>>? contextPages,
  }) : _itemPages = itemPages ?? [],
       _contextPages = contextPages ?? [],
       super(_dummyClient);

  final List<List<Map<String, dynamic>>> _itemPages;
  final List<List<Map<String, dynamic>>> _contextPages;
  int _itemCallCount = 0;
  int _contextCallCount = 0;

  @override
  Future<List<Map<String, dynamic>>> vocabularyItems({
    int? limit,
    String? updatedAfter,
  }) async {
    if (_itemCallCount >= _itemPages.length) return [];
    return _itemPages[_itemCallCount++];
  }

  @override
  Future<List<Map<String, dynamic>>> vocabularyContexts({
    String? vocabularyItemId,
    int? limit,
    String? updatedAfter,
  }) async {
    if (_contextCallCount >= _contextPages.length) return [];
    return _contextPages[_contextCallCount++];
  }
}

class _ThrowingAudioApi extends AudioApi {
  _ThrowingAudioApi() : super(_dummyClient);

  @override
  Future<List<Map<String, dynamic>>> audios({
    String? provider,
    int? limit,
    String? updatedAfter,
  }) async {
    throw Exception('network error');
  }
}

Map<String, dynamic> _audioJson(String id, {String? updatedAt}) => {
  'id': id,
  'aid': 'aid_$id',
  'provider': 'local',
  'title': 'Audio $id',
  'duration': 120,
  'updatedAt': updatedAt ?? '2026-01-01T00:00:00.000Z',
  'createdAt': '2026-01-01T00:00:00.000Z',
};

Map<String, dynamic> _videoJson(
  String id, {
  String? updatedAt,
  String? deletedAt,
}) => {
  'id': id,
  'vid': 'vid_$id',
  'provider': 'youtube',
  'title': 'Video $id',
  'duration': 300,
  'language': 'en',
  'updatedAt': updatedAt ?? '2026-01-01T00:00:00.000Z',
  'createdAt': '2026-01-01T00:00:00.000Z',
  if (deletedAt != null) 'deletedAt': deletedAt,
};

Map<String, dynamic> _recordingJson(String id) => {
  'id': id,
  'targetId': 'a1',
  'targetType': 'audio',
  'language': 'en',
  'duration': 5000,
  'referenceStart': 0,
  'referenceDuration': 5000,
  'updatedAt': '2026-01-01T00:00:00.000Z',
  'createdAt': '2026-01-01T00:00:00.000Z',
};

Map<String, dynamic> _vocabItemJson(String id) => {
  'id': id,
  'word': 'hello',
  'language': 'en',
  'targetLanguage': 'zh',
  'status': 'learning',
  'easeFactor': 2.5,
  'interval': 0,
  'nextReviewAt': '2026-01-02T00:00:00.000Z',
  'reviewsCount': 0,
  'contextsCount': 0,
  'updatedAt': '2026-01-01T00:00:00.000Z',
  'createdAt': '2026-01-01T00:00:00.000Z',
};

Map<String, dynamic> _vocabContextJson(String id) => {
  'id': id,
  'vocabularyItemId': 'vi1',
  'contextText': 'a greeting',
  'sourceType': 'transcript',
  'sourceId': 'src1',
  'locatorJson': '{}',
  'updatedAt': '2026-01-01T00:00:00.000Z',
  'createdAt': '2026-01-01T00:00:00.000Z',
};

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  SyncDownloadService buildService({
    AudioApi? audioApi,
    VideoApi? videoApi,
    RecordingApi? recordingApi,
    VocabularyApi? vocabularyApi,
  }) {
    return SyncDownloadService(
      db: db,
      audioApi: audioApi ?? _FakeAudioApi([]),
      videoApi: videoApi ?? _FakeVideoApi([]),
      recordingApi: recordingApi ?? _FakeRecordingApi([]),
      vocabularyApi: vocabularyApi ?? _FakeVocabularyApi(),
    );
  }

  group('SyncDownloadService.downloadAudios', () {
    test('inserts new audio rows from server', () async {
      final service = buildService(
        audioApi: _FakeAudioApi([
          [
            _audioJson('a1', updatedAt: '2026-01-01T00:00:00.000Z'),
            _audioJson('a2', updatedAt: '2026-01-02T00:00:00.000Z'),
          ],
        ]),
      );

      final result = await service.downloadAudios();

      expect(result.success, isTrue);
      expect(result.synced, 2);
      expect(result.failed, 0);

      final row = await db.audioDao.getById('a1');
      expect(row, isNotNull);
      expect(row!.title, 'Audio a1');
    });

    test('persists cursor after download', () async {
      final service = buildService(
        audioApi: _FakeAudioApi([
          [_audioJson('a1', updatedAt: '2026-03-15T10:00:00.000Z')],
        ]),
      );

      await service.downloadAudios();

      final cursor = await db.settingsDao.getValue(
        SettingsKeys.syncCursorAudio,
      );
      expect(cursor, '2026-03-15T10:00:00.000Z');
    });

    test('paginates when batch is full (50 items)', () async {
      final page1 = List.generate(
        50,
        (i) => _audioJson(
          'a$i',
          updatedAt: '2026-01-01T00:00:${i.toString().padLeft(2, '0')}.000Z',
        ),
      );
      final page2 = [_audioJson('a50', updatedAt: '2026-01-02T00:00:00.000Z')];

      final service = buildService(audioApi: _FakeAudioApi([page1, page2]));

      final result = await service.downloadAudios();

      expect(result.success, isTrue);
      expect(result.synced, 51);
    });

    test('returns failure on network error', () async {
      final service = buildService(audioApi: _ThrowingAudioApi());

      final result = await service.downloadAudios();

      expect(result.success, isFalse);
      expect(result.failed, 1);
      expect(result.errors, isNotNull);
      expect(result.errors!.first, contains('network error'));
    });

    test('skips rows with null or empty id', () async {
      final service = buildService(
        audioApi: _FakeAudioApi([
          [
            {
              'id': null,
              'title': 'no id',
              'updatedAt': '2026-01-01T00:00:00.000Z',
              'createdAt': '2026-01-01T00:00:00.000Z',
              'provider': 'local',
              'duration': 0,
              'aid': '',
            },
            {
              'id': '',
              'title': 'empty id',
              'updatedAt': '2026-01-01T00:00:00.000Z',
              'createdAt': '2026-01-01T00:00:00.000Z',
              'provider': 'local',
              'duration': 0,
              'aid': '',
            },
            _audioJson('valid'),
          ],
        ]),
      );

      final result = await service.downloadAudios();

      expect(result.synced, 1);
      final row = await db.audioDao.getById('valid');
      expect(row, isNotNull);
    });

    test('returns empty success when no data', () async {
      final service = buildService(audioApi: _FakeAudioApi([]));

      final result = await service.downloadAudios();

      expect(result.success, isTrue);
      expect(result.synced, 0);
    });
  });

  group('SyncDownloadService.downloadVideos', () {
    test('handles tombstone (deletedAt) by deleting local row', () async {
      await db.videoDao.insertRow(
        VideoRow(
          id: 'v1',
          vid: 'vid_v1',
          provider: 'youtube',
          title: 'Existing',
          durationSeconds: 100,
          language: 'en',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

      final service = buildService(
        videoApi: _FakeVideoApi([
          [_videoJson('v1', deletedAt: '2026-02-01T00:00:00.000Z')],
        ]),
      );

      final result = await service.downloadVideos();

      expect(result.success, isTrue);
      expect(result.synced, 1);
      final row = await db.videoDao.getById('v1');
      expect(row, isNull);
    });

    test('inserts new video rows', () async {
      final service = buildService(
        videoApi: _FakeVideoApi([
          [_videoJson('v1'), _videoJson('v2')],
        ]),
      );

      final result = await service.downloadVideos();

      expect(result.success, isTrue);
      expect(result.synced, 2);
      expect(await db.videoDao.getById('v1'), isNotNull);
      expect(await db.videoDao.getById('v2'), isNotNull);
    });
  });

  group('SyncDownloadService.downloadRecordings', () {
    test('inserts recording rows', () async {
      final service = buildService(
        recordingApi: _FakeRecordingApi([
          [_recordingJson('r1')],
        ]),
      );

      final result = await service.downloadRecordings();

      expect(result.success, isTrue);
      expect(result.synced, 1);
      expect(await db.recordingDao.getById('r1'), isNotNull);
    });
  });

  group('SyncDownloadService.downloadVocabularyItems', () {
    test('upserts vocabulary items', () async {
      final service = buildService(
        vocabularyApi: _FakeVocabularyApi(
          itemPages: [
            [_vocabItemJson('vi1')],
          ],
        ),
      );

      final result = await service.downloadVocabularyItems();

      expect(result.success, isTrue);
      expect(result.synced, 1);
      expect(await db.vocabularyItemDao.getById('vi1'), isNotNull);
    });
  });

  group('SyncDownloadService.downloadVocabularyContexts', () {
    test('upserts vocabulary contexts', () async {
      await db.vocabularyItemDao.updateRow(
        VocabularyItemRow(
          id: 'vi1',
          word: 'hello',
          language: 'en',
          targetLanguage: 'zh',
          status: 'learning',
          easeFactor: 2.5,
          interval: 0,
          nextReviewAt: DateTime(2026, 1, 2),
          reviewsCount: 0,
          contextsCount: 0,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

      final service = buildService(
        vocabularyApi: _FakeVocabularyApi(
          contextPages: [
            [_vocabContextJson('vc1')],
          ],
        ),
      );

      final result = await service.downloadVocabularyContexts();

      expect(result.success, isTrue);
      expect(result.synced, 1);
      expect(await db.vocabularyContextDao.getById('vc1'), isNotNull);
    });
  });

  group('SyncDownloadService.downloadAllEntitiesFresh', () {
    test('resets cursors and downloads all entity types', () async {
      await db.settingsDao.setValue(SettingsKeys.syncCursorAudio, 'old');

      final service = buildService(
        audioApi: _FakeAudioApi([
          [_audioJson('a1')],
        ]),
        videoApi: _FakeVideoApi([
          [_videoJson('v1')],
        ]),
        recordingApi: _FakeRecordingApi([
          [_recordingJson('r1')],
        ]),
        vocabularyApi: _FakeVocabularyApi(
          itemPages: [
            [_vocabItemJson('vi1')],
          ],
          contextPages: [
            [_vocabContextJson('vc1')],
          ],
        ),
      );

      final result = await service.downloadAllEntitiesFresh();

      expect(result.success, isTrue);
      expect(result.synced, 5);
    });
  });

  group('SyncResult.merge', () {
    test('combines counts and errors', () {
      const a = SyncResult(success: true, synced: 3, failed: 0);
      const b = SyncResult(
        success: false,
        synced: 1,
        failed: 2,
        errors: ['err1'],
      );

      final merged = a.merge(b);

      expect(merged.success, isFalse);
      expect(merged.synced, 4);
      expect(merged.failed, 2);
      expect(merged.errors, ['err1']);
    });

    test('both successful stays successful', () {
      const a = SyncResult(success: true, synced: 1, failed: 0);
      const b = SyncResult(success: true, synced: 2, failed: 0);

      final merged = a.merge(b);

      expect(merged.success, isTrue);
      expect(merged.synced, 3);
    });
  });
}
