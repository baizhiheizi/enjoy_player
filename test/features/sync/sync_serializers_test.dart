import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/sync/data/sync_serializers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('prepareForSync maps', () {
    test('audio map omits local-only sync fields', () {
      final now = DateTime.utc(2025, 5, 9);
      final row = AudioRow(
        id: 'i',
        aid: 'a',
        provider: 'user',
        title: 'T',
        description: null,
        thumbnailUrl: null,
        durationSeconds: 10,
        language: 'en',
        translationKey: null,
        sourceText: null,
        voice: null,
        source: null,
        localUri: 'file:///local.mp3',
        md5: 'm',
        size: 99,
        mediaUrl: null,
        syncStatus: 'local',
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      );
      final m = prepareForSyncAudioMap(row);
      expect(m.containsKey('localUri'), isFalse);
      expect(m.containsKey('localMtimeMs'), isFalse);
      expect(m.containsKey('syncStatus'), isFalse);
      expect(m['duration'], 10);
    });

    test('audio map omits local filesystem thumbnailUrl', () {
      final now = DateTime.utc(2025, 5, 9);
      final row = AudioRow(
        id: 'i',
        aid: 'a',
        provider: 'user',
        title: 'T',
        description: null,
        thumbnailUrl: r'C:\media_thumbs\abc.jpg',
        durationSeconds: 10,
        language: 'en',
        translationKey: null,
        sourceText: null,
        voice: null,
        source: null,
        localUri: 'file:///local.mp3',
        md5: 'm',
        size: 99,
        mediaUrl: null,
        syncStatus: 'local',
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      );
      final m = prepareForSyncAudioMap(row);
      expect(m.containsKey('thumbnailUrl'), isFalse);
    });

    test('audio map includes https thumbnailUrl', () {
      final now = DateTime.utc(2025, 5, 9);
      final row = AudioRow(
        id: 'i',
        aid: 'a',
        provider: 'user',
        title: 'T',
        description: null,
        thumbnailUrl: 'https://cdn.example/thumb.jpg',
        durationSeconds: 10,
        language: 'en',
        translationKey: null,
        sourceText: null,
        voice: null,
        source: null,
        localUri: null,
        md5: 'm',
        size: 99,
        mediaUrl: null,
        syncStatus: 'synced',
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      );
      final m = prepareForSyncAudioMap(row);
      expect(m['thumbnailUrl'], 'https://cdn.example/thumb.jpg');
    });

    test('video map omits local filesystem thumbnailUrl', () {
      final now = DateTime.utc(2025, 5, 9);
      final row = VideoRow(
        id: 'v1',
        vid: 'vid',
        provider: 'user',
        title: 'T',
        description: null,
        thumbnailUrl: r'C:\media_thumbs\abc.jpg',
        durationSeconds: 5,
        language: 'en',
        source: null,
        localUri: 'file:///v.mp4',
        md5: 'h',
        size: 1,
        mediaUrl: null,
        syncStatus: 'pending',
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      );
      final m = prepareForSyncVideoMap(row);
      expect(m.containsKey('thumbnailUrl'), isFalse);
    });

    test(
      'recording map uses milliseconds for duration and reference times',
      () {
        final now = DateTime.utc(2025, 5, 9);
        final row = RecordingRow(
          id: 'rec-1',
          targetType: 'Audio',
          targetId: 'audio-1',
          referenceStart: 5000,
          referenceDuration: 12_000,
          referenceText: 'hello',
          language: 'en',
          duration: 11_234,
          md5: 'abc',
          audioUrl: null,
          pronunciationScore: null,
          assessmentJson: null,
          localPath: '/tmp/t.wav',
          syncStatus: 'local',
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        );
        final m = prepareForSyncRecordingMap(row);
        expect(m['duration'], 11_234);
        expect(m['referenceStart'], 5000);
        expect(m['referenceDuration'], 12_000);
      },
    );
  });

  group('recordingRowFromServerJson', () {
    test('parses duration and reference fields as milliseconds', () {
      final t = DateTime.utc(2025, 6, 1);
      final row = recordingRowFromServerJson({
        'id': 'r1',
        'targetType': 'Video',
        'targetId': 'vid-9',
        'referenceStart': 1500,
        'referenceDuration': 3200.7,
        'referenceText': 'cue',
        'language': 'zh',
        'duration': 4100.4,
        'createdAt': t.toIso8601String(),
        'updatedAt': t.toIso8601String(),
      });
      expect(row.referenceStart, 1500);
      expect(row.referenceDuration, 3201);
      expect(row.duration, 4100);
    });
  });

  group('videoRowFromServerJson', () {
    test('infers youtube when provider missing and vid is YouTube id', () {
      final t = DateTime.utc(2025, 6, 1);
      final row = videoRowFromServerJson({
        'id': '550e8400-e29b-41d4-a716-446655440001',
        'vid': 'dQw4w9WgXcQ',
        'title': 'Rick',
        'durationSeconds': 212,
        'language': 'en',
        'createdAt': t.toIso8601String(),
        'updatedAt': t.toIso8601String(),
      });
      expect(row.provider, 'youtube');
      expect(row.vid, 'dQw4w9WgXcQ');
    });

    test('infers youtube from source field when provider is user', () {
      final t = DateTime.utc(2025, 6, 1);
      final row = videoRowFromServerJson({
        'id': '550e8400-e29b-41d4-a716-446655440002',
        'vid': 'x',
        'provider': 'user',
        'source': 'youtube',
        'title': 'T',
        'durationSeconds': 1,
        'language': 'en',
        'createdAt': t.toIso8601String(),
        'updatedAt': t.toIso8601String(),
      });
      expect(row.provider, 'youtube');
    });

    test('infers youtube from mediaUrl when provider missing', () {
      final t = DateTime.utc(2025, 6, 1);
      final row = videoRowFromServerJson({
        'id': '550e8400-e29b-41d4-a716-446655440003',
        'vid': 'not-used',
        'title': 'T',
        'mediaUrl': 'https://www.youtube.com/watch?v=jNQXAC9IVRw',
        'durationSeconds': 1,
        'language': 'en',
        'createdAt': t.toIso8601String(),
        'updatedAt': t.toIso8601String(),
      });
      expect(row.provider, 'youtube');
    });

    test('does not override explicit netflix provider', () {
      final t = DateTime.utc(2025, 6, 1);
      final row = videoRowFromServerJson({
        'id': '550e8400-e29b-41d4-a716-446655440004',
        'vid': 'dQw4w9WgXcQ',
        'provider': 'netflix',
        'title': 'T',
        'durationSeconds': 1,
        'language': 'en',
        'createdAt': t.toIso8601String(),
        'updatedAt': t.toIso8601String(),
      });
      expect(row.provider, 'netflix');
    });
  });

  group('mergeAudioLastWriteWins', () {
    test('server newer replaces metadata but keeps localUri', () {
      final localTime = DateTime.utc(2025, 1, 1);
      final serverTime = DateTime.utc(2025, 6, 1);
      final local = AudioRow(
        id: 'same',
        aid: 'a',
        provider: 'user',
        title: 'Local title',
        description: null,
        thumbnailUrl: null,
        durationSeconds: 1,
        language: 'en',
        translationKey: null,
        sourceText: null,
        voice: null,
        source: null,
        localUri: 'file:///keep-me.mp3',
        md5: 'm',
        size: 1,
        localMtimeMs: 12345,
        mediaUrl: null,
        syncStatus: 'local',
        serverUpdatedAt: null,
        createdAt: localTime,
        updatedAt: localTime,
      );
      final merged = mergeAudioLastWriteWins(
        local: local,
        server: {
          'id': 'same',
          'aid': 'a',
          'provider': 'user',
          'title': 'Server title',
          'durationSeconds': 42,
          'language': 'ja',
          'createdAt': serverTime.toIso8601String(),
          'updatedAt': serverTime.toIso8601String(),
        },
      );
      expect(merged.title, 'Server title');
      expect(merged.durationSeconds, 42);
      expect(merged.localUri, 'file:///keep-me.mp3');
      expect(merged.localMtimeMs, 12345);
    });

    test('local newer keeps local row unchanged', () {
      final serverTime = DateTime.utc(2025, 1, 1);
      final localTime = DateTime.utc(2025, 6, 1);
      final local = AudioRow(
        id: 'same',
        aid: 'a',
        provider: 'user',
        title: 'Local title',
        description: null,
        thumbnailUrl: null,
        durationSeconds: 1,
        language: 'en',
        translationKey: null,
        sourceText: null,
        voice: null,
        source: null,
        localUri: 'file:///keep-me.mp3',
        md5: 'm',
        size: 1,
        mediaUrl: null,
        syncStatus: 'local',
        serverUpdatedAt: null,
        createdAt: localTime,
        updatedAt: localTime,
      );
      final merged = mergeAudioLastWriteWins(
        local: local,
        server: {
          'id': 'same',
          'aid': 'a',
          'provider': 'user',
          'title': 'Server title',
          'durationSeconds': 42,
          'language': 'ja',
          'createdAt': serverTime.toIso8601String(),
          'updatedAt': serverTime.toIso8601String(),
        },
      );
      expect(merged.title, 'Local title');
    });
  });
}
