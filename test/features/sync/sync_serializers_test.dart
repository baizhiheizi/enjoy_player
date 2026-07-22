import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/youtube_subscription_source.dart';
import 'package:enjoy_player/features/sync/data/sync_serializers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseIsoDate', () {
    test('returns null for null input', () {
      expect(parseIsoDate(null), isNull);
    });

    test('returns DateTime as-is', () {
      final dt = DateTime.utc(2025, 3, 15, 10, 30);
      expect(parseIsoDate(dt), same(dt));
    });

    test('parses valid ISO 8601 string', () {
      final result = parseIsoDate('2025-03-15T10:30:00.000Z');
      expect(result, DateTime.utc(2025, 3, 15, 10, 30));
    });

    test('returns null for invalid string', () {
      expect(parseIsoDate('not-a-date'), isNull);
    });

    test('returns null for empty string', () {
      expect(parseIsoDate(''), isNull);
    });

    test('handles non-String dynamic via toString()', () {
      expect(parseIsoDate(12345), isNull);
    });
  });

  group('requireIsoDate', () {
    test('returns parsed date when valid', () {
      final fallback = DateTime.utc(2020, 1, 1);
      final result = requireIsoDate('2025-06-01T00:00:00.000Z', fallback);
      expect(result, DateTime.utc(2025, 6, 1));
    });

    test('returns fallback when value is null', () {
      final fallback = DateTime.utc(2020, 1, 1);
      expect(requireIsoDate(null, fallback), fallback);
    });

    test('returns fallback when value is unparseable', () {
      final fallback = DateTime.utc(2020, 1, 1);
      expect(requireIsoDate('garbage', fallback), fallback);
    });
  });

  group('durationSecondsFromJson', () {
    test('reads durationSeconds key as int', () {
      expect(durationSecondsFromJson({'durationSeconds': 120}), 120);
    });

    test('falls back to duration key', () {
      expect(durationSecondsFromJson({'duration': 90}), 90);
    });

    test('prefers durationSeconds over duration', () {
      expect(
        durationSecondsFromJson({'durationSeconds': 60, 'duration': 90}),
        60,
      );
    });

    test('rounds double value', () {
      expect(durationSecondsFromJson({'durationSeconds': 33.7}), 34);
    });

    test('rounds double duration key', () {
      expect(durationSecondsFromJson({'duration': 10.2}), 10);
    });

    test('returns 0 when both keys missing', () {
      expect(durationSecondsFromJson({}), 0);
    });

    test('returns 0 when value is a string', () {
      expect(durationSecondsFromJson({'durationSeconds': '120'}), 0);
    });

    test('returns 0 when value is null', () {
      expect(durationSecondsFromJson({'durationSeconds': null}), 0);
    });
  });

  group('unwrapEntity', () {
    test('returns inner map when key holds Map<String, dynamic>', () {
      final inner = <String, dynamic>{'id': 'x'};
      final result = unwrapEntity({'audio': inner}, 'audio');
      expect(result, same(inner));
    });

    test('converts non-generic Map to Map<String, dynamic>', () {
      final Map inner = {'id': 'x', 'count': 1};
      final result = unwrapEntity({'video': inner}, 'video');
      expect(result, isA<Map<String, dynamic>>());
      expect(result['id'], 'x');
    });

    test('returns outer response when key is missing', () {
      final response = <String, dynamic>{'id': 'y'};
      final result = unwrapEntity(response, 'audio');
      expect(result, same(response));
    });

    test('returns outer response when key holds non-map value', () {
      final response = <String, dynamic>{'audio': 'not-a-map'};
      final result = unwrapEntity(response, 'audio');
      expect(result, same(response));
    });
  });

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

    test('null local returns server row as new insert', () {
      final serverTime = DateTime.utc(2025, 6, 1);
      final merged = mergeAudioLastWriteWins(
        local: null,
        server: {
          'id': 'new-1',
          'aid': 'a-new',
          'provider': 'tts',
          'title': 'Brand new',
          'durationSeconds': 55,
          'language': 'zh',
          'createdAt': serverTime.toIso8601String(),
          'updatedAt': serverTime.toIso8601String(),
        },
      );
      expect(merged.id, 'new-1');
      expect(merged.title, 'Brand new');
      expect(merged.localUri, isNull);
      expect(merged.localMtimeMs, isNull);
    });

    test('equal timestamps: server wins (>= semantics)', () {
      final t = DateTime.utc(2025, 3, 1);
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
        localUri: 'file:///local.mp3',
        md5: null,
        size: null,
        mediaUrl: null,
        syncStatus: 'local',
        serverUpdatedAt: null,
        createdAt: t,
        updatedAt: t,
      );
      final merged = mergeAudioLastWriteWins(
        local: local,
        server: {
          'id': 'same',
          'aid': 'a',
          'provider': 'user',
          'title': 'Server title',
          'durationSeconds': 99,
          'language': 'ja',
          'createdAt': t.toIso8601String(),
          'updatedAt': t.toIso8601String(),
        },
      );
      expect(merged.title, 'Server title');
      expect(merged.localUri, 'file:///local.mp3');
    });
  });

  group('mergeVideoLastWriteWins', () {
    test('null local returns server row as new insert', () {
      final serverTime = DateTime.utc(2025, 6, 1);
      final merged = mergeVideoLastWriteWins(
        local: null,
        server: {
          'id': 'v-new',
          'vid': 'abc123',
          'provider': 'user',
          'title': 'New video',
          'durationSeconds': 300,
          'language': 'en',
          'createdAt': serverTime.toIso8601String(),
          'updatedAt': serverTime.toIso8601String(),
        },
      );
      expect(merged.id, 'v-new');
      expect(merged.title, 'New video');
      expect(merged.localUri, isNull);
      expect(merged.localMtimeMs, isNull);
    });

    test('local newer keeps local row unchanged', () {
      final localTime = DateTime.utc(2025, 6, 1);
      final serverTime = DateTime.utc(2025, 1, 1);
      final local = VideoRow(
        id: 'v1',
        vid: 'vid',
        provider: 'user',
        title: 'Local video',
        description: null,
        thumbnailUrl: null,
        durationSeconds: 10,
        language: 'en',
        source: null,
        localUri: 'file:///v.mp4',
        md5: null,
        size: null,
        mediaUrl: null,
        syncStatus: 'local',
        serverUpdatedAt: null,
        createdAt: localTime,
        updatedAt: localTime,
      );
      final merged = mergeVideoLastWriteWins(
        local: local,
        server: {
          'id': 'v1',
          'vid': 'vid',
          'provider': 'user',
          'title': 'Server video',
          'durationSeconds': 20,
          'language': 'ja',
          'createdAt': serverTime.toIso8601String(),
          'updatedAt': serverTime.toIso8601String(),
        },
      );
      expect(merged.title, 'Local video');
      expect(merged.localUri, 'file:///v.mp4');
    });

    test(
      'server newer replaces metadata but preserves localUri/localMtimeMs',
      () {
        final localTime = DateTime.utc(2025, 1, 1);
        final serverTime = DateTime.utc(2025, 6, 1);
        final local = VideoRow(
          id: 'v1',
          vid: 'vid',
          provider: 'user',
          title: 'Local video',
          description: null,
          thumbnailUrl: null,
          durationSeconds: 10,
          language: 'en',
          source: null,
          localUri: 'file:///keep.mp4',
          md5: null,
          size: null,
          localMtimeMs: 99999,
          mediaUrl: null,
          syncStatus: 'local',
          serverUpdatedAt: null,
          createdAt: localTime,
          updatedAt: localTime,
        );
        final merged = mergeVideoLastWriteWins(
          local: local,
          server: {
            'id': 'v1',
            'vid': 'vid',
            'provider': 'user',
            'title': 'Server video',
            'durationSeconds': 42,
            'language': 'ja',
            'createdAt': serverTime.toIso8601String(),
            'updatedAt': serverTime.toIso8601String(),
          },
        );
        expect(merged.title, 'Server video');
        expect(merged.durationSeconds, 42);
        expect(merged.localUri, 'file:///keep.mp4');
        expect(merged.localMtimeMs, 99999);
      },
    );

    test('equal timestamps: server wins', () {
      final t = DateTime.utc(2025, 3, 1);
      final local = VideoRow(
        id: 'v1',
        vid: 'vid',
        provider: 'user',
        title: 'Local video',
        description: null,
        thumbnailUrl: null,
        durationSeconds: 10,
        language: 'en',
        source: null,
        localUri: null,
        md5: null,
        size: null,
        mediaUrl: null,
        syncStatus: 'local',
        serverUpdatedAt: null,
        createdAt: t,
        updatedAt: t,
      );
      final merged = mergeVideoLastWriteWins(
        local: local,
        server: {
          'id': 'v1',
          'vid': 'vid',
          'provider': 'user',
          'title': 'Server video',
          'durationSeconds': 10,
          'language': 'en',
          'createdAt': t.toIso8601String(),
          'updatedAt': t.toIso8601String(),
        },
      );
      expect(merged.title, 'Server video');
    });
  });

  group('mergeRecordingLastWriteWins', () {
    test('null local returns server row as new insert', () {
      final serverTime = DateTime.utc(2025, 6, 1);
      final merged = mergeRecordingLastWriteWins(
        local: null,
        server: {
          'id': 'rec-new',
          'targetType': 'Audio',
          'targetId': 'a1',
          'referenceStart': 0,
          'referenceDuration': 5000,
          'referenceText': 'hello',
          'language': 'en',
          'duration': 4500,
          'createdAt': serverTime.toIso8601String(),
          'updatedAt': serverTime.toIso8601String(),
        },
      );
      expect(merged.id, 'rec-new');
      expect(merged.referenceText, 'hello');
      expect(merged.localPath, isNull);
    });

    test('local newer keeps local row unchanged', () {
      final localTime = DateTime.utc(2025, 6, 1);
      final serverTime = DateTime.utc(2025, 1, 1);
      final local = RecordingRow(
        id: 'rec-1',
        targetType: 'Audio',
        targetId: 'a1',
        referenceStart: 0,
        referenceDuration: 5000,
        referenceText: 'local text',
        language: 'en',
        duration: 4500,
        md5: null,
        audioUrl: null,
        pronunciationScore: null,
        assessmentJson: null,
        localPath: '/tmp/rec.wav',
        syncStatus: 'local',
        serverUpdatedAt: null,
        createdAt: localTime,
        updatedAt: localTime,
      );
      final merged = mergeRecordingLastWriteWins(
        local: local,
        server: {
          'id': 'rec-1',
          'targetType': 'Audio',
          'targetId': 'a1',
          'referenceStart': 0,
          'referenceDuration': 5000,
          'referenceText': 'server text',
          'language': 'en',
          'duration': 4500,
          'createdAt': serverTime.toIso8601String(),
          'updatedAt': serverTime.toIso8601String(),
        },
      );
      expect(merged.referenceText, 'local text');
      expect(merged.localPath, '/tmp/rec.wav');
    });

    test('server newer replaces metadata but preserves localPath', () {
      final localTime = DateTime.utc(2025, 1, 1);
      final serverTime = DateTime.utc(2025, 6, 1);
      final local = RecordingRow(
        id: 'rec-1',
        targetType: 'Audio',
        targetId: 'a1',
        referenceStart: 0,
        referenceDuration: 5000,
        referenceText: 'local text',
        language: 'en',
        duration: 4500,
        md5: null,
        audioUrl: null,
        pronunciationScore: null,
        assessmentJson: null,
        localPath: '/tmp/keep.wav',
        syncStatus: 'local',
        serverUpdatedAt: null,
        createdAt: localTime,
        updatedAt: localTime,
      );
      final merged = mergeRecordingLastWriteWins(
        local: local,
        server: {
          'id': 'rec-1',
          'targetType': 'Audio',
          'targetId': 'a1',
          'referenceStart': 100,
          'referenceDuration': 6000,
          'referenceText': 'server text',
          'language': 'zh',
          'duration': 5500,
          'createdAt': serverTime.toIso8601String(),
          'updatedAt': serverTime.toIso8601String(),
        },
      );
      expect(merged.referenceText, 'server text');
      expect(merged.duration, 5500);
      expect(merged.localPath, '/tmp/keep.wav');
    });

    test('equal timestamps: server wins', () {
      final t = DateTime.utc(2025, 3, 1);
      final local = RecordingRow(
        id: 'rec-1',
        targetType: 'Audio',
        targetId: 'a1',
        referenceStart: 0,
        referenceDuration: 5000,
        referenceText: 'local text',
        language: 'en',
        duration: 4500,
        md5: null,
        audioUrl: null,
        pronunciationScore: null,
        assessmentJson: null,
        localPath: '/tmp/rec.wav',
        syncStatus: 'local',
        serverUpdatedAt: null,
        createdAt: t,
        updatedAt: t,
      );
      final merged = mergeRecordingLastWriteWins(
        local: local,
        server: {
          'id': 'rec-1',
          'targetType': 'Audio',
          'targetId': 'a1',
          'referenceStart': 0,
          'referenceDuration': 5000,
          'referenceText': 'server text',
          'language': 'en',
          'duration': 4500,
          'createdAt': t.toIso8601String(),
          'updatedAt': t.toIso8601String(),
        },
      );
      expect(merged.referenceText, 'server text');
      expect(merged.localPath, '/tmp/rec.wav');
    });
  });

  group('prepareForSyncAudioMap optional fields', () {
    test('includes all optional fields when present', () {
      final now = DateTime.utc(2025, 5, 9);
      final row = AudioRow(
        id: 'i',
        aid: 'a',
        provider: 'tts',
        title: 'T',
        description: 'A description',
        thumbnailUrl: 'https://cdn.example/thumb.jpg',
        durationSeconds: 10,
        language: 'en',
        translationKey: 'key-1',
        sourceText: 'Hello world',
        voice: 'alloy',
        source: 'tts',
        localUri: null,
        md5: 'abc123',
        size: 1024,
        mediaUrl: 'https://cdn.example/audio.mp3',
        syncStatus: 'synced',
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      );
      final m = prepareForSyncAudioMap(row);
      expect(m['description'], 'A description');
      expect(m['thumbnailUrl'], 'https://cdn.example/thumb.jpg');
      expect(m['translationKey'], 'key-1');
      expect(m['sourceText'], 'Hello world');
      expect(m['voice'], 'alloy');
      expect(m['source'], 'tts');
      expect(m['md5'], 'abc123');
      expect(m['size'], 1024);
      expect(m['mediaUrl'], 'https://cdn.example/audio.mp3');
    });
  });

  group('prepareForSyncVideoMap optional fields', () {
    test('includes all optional fields when present', () {
      final now = DateTime.utc(2025, 5, 9);
      final row = VideoRow(
        id: 'v1',
        vid: 'vid',
        provider: 'user',
        title: 'T',
        description: 'Video desc',
        thumbnailUrl: 'https://cdn.example/v.jpg',
        durationSeconds: 120,
        language: 'en',
        source: 'youtube',
        localUri: null,
        md5: 'def456',
        size: 2048,
        mediaUrl: 'https://cdn.example/v.mp4',
        syncStatus: 'synced',
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      );
      final m = prepareForSyncVideoMap(row);
      expect(m['description'], 'Video desc');
      expect(m['thumbnailUrl'], 'https://cdn.example/v.jpg');
      expect(m['source'], 'youtube');
      expect(m['md5'], 'def456');
      expect(m['size'], 2048);
      expect(m['mediaUrl'], 'https://cdn.example/v.mp4');
    });

    test('omits null optional fields', () {
      final now = DateTime.utc(2025, 5, 9);
      final row = VideoRow(
        id: 'v1',
        vid: 'vid',
        provider: 'user',
        title: 'T',
        description: null,
        thumbnailUrl: null,
        durationSeconds: 5,
        language: 'en',
        source: null,
        localUri: null,
        md5: null,
        size: null,
        mediaUrl: null,
        syncStatus: 'synced',
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      );
      final m = prepareForSyncVideoMap(row);
      expect(m.containsKey('description'), isFalse);
      expect(m.containsKey('thumbnailUrl'), isFalse);
      expect(m.containsKey('source'), isFalse);
      expect(m.containsKey('md5'), isFalse);
      expect(m.containsKey('size'), isFalse);
      expect(m.containsKey('mediaUrl'), isFalse);
    });
  });

  group('prepareForSyncRecordingMap optional fields', () {
    test('includes optional fields when present', () {
      final now = DateTime.utc(2025, 5, 9);
      final row = RecordingRow(
        id: 'rec-1',
        targetType: 'Audio',
        targetId: 'audio-1',
        referenceStart: 0,
        referenceDuration: 5000,
        referenceText: 'hello',
        language: 'en',
        duration: 4500,
        md5: 'hash123',
        audioUrl: 'https://cdn.example/rec.wav',
        pronunciationScore: 85,
        assessmentJson: '{"score":85}',
        localPath: '/tmp/rec.wav',
        syncStatus: 'synced',
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      );
      final m = prepareForSyncRecordingMap(row);
      expect(m['md5'], 'hash123');
      expect(m['audioUrl'], 'https://cdn.example/rec.wav');
      expect(m['pronunciationScore'], 85);
      expect(m['assessmentJson'], '{"score":85}');
      expect(m.containsKey('localPath'), isFalse);
    });

    test('omits null optional fields', () {
      final now = DateTime.utc(2025, 5, 9);
      final row = RecordingRow(
        id: 'rec-1',
        targetType: 'Audio',
        targetId: 'audio-1',
        referenceStart: 0,
        referenceDuration: 5000,
        referenceText: 'hello',
        language: 'en',
        duration: 4500,
        md5: null,
        audioUrl: null,
        pronunciationScore: null,
        assessmentJson: null,
        localPath: null,
        syncStatus: 'synced',
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      );
      final m = prepareForSyncRecordingMap(row);
      expect(m.containsKey('md5'), isFalse);
      expect(m.containsKey('audioUrl'), isFalse);
      expect(m.containsKey('pronunciationScore'), isFalse);
      expect(m.containsKey('assessmentJson'), isFalse);
    });
  });

  group('prepareForSyncSubscriptionMap', () {
    test('serializes all fields including optional ones', () {
      final subscribed = DateTime.utc(2025, 4, 1);
      final fetched = DateTime.utc(2025, 5, 1);
      final row = YoutubeChannelSubscriptionRow(
        channelId: 'UC123',
        displayName: 'Test Channel',
        thumbnailUrl: 'https://cdn.example/ch.jpg',
        source: YoutubeSubscriptionSource.recommended,
        sourceType: YoutubeSourceType.channel,
        feedUrl: 'https://worker.enjoy.bot/youtube/channel/UC123?format=json',
        language: 'en',
        subscribedAt: subscribed,
        lastFetchedAt: fetched,
      );
      final m = prepareForSyncSubscriptionMap(row);
      expect(m['channelId'], 'UC123');
      expect(m['displayName'], 'Test Channel');
      expect(m['thumbnailUrl'], 'https://cdn.example/ch.jpg');
      expect(m['source'], 'recommended');
      expect(m['sourceType'], 'channel');
      expect(
        m['feedUrl'],
        'https://worker.enjoy.bot/youtube/channel/UC123?format=json',
      );
      expect(m['language'], 'en');
      expect(m['subscribedAt'], subscribed.toIso8601String());
      expect(m['lastFetchedAt'], fetched.toIso8601String());
    });

    test('omits null optional fields', () {
      final subscribed = DateTime.utc(2025, 4, 1);
      final row = YoutubeChannelSubscriptionRow(
        channelId: 'UC456',
        displayName: 'Minimal',
        thumbnailUrl: null,
        source: YoutubeSubscriptionSource.user,
        sourceType: YoutubeSourceType.playlist,
        feedUrl: null,
        language: 'und',
        subscribedAt: subscribed,
        lastFetchedAt: null,
      );
      final m = prepareForSyncSubscriptionMap(row);
      expect(m.containsKey('thumbnailUrl'), isFalse);
      expect(m.containsKey('feedUrl'), isFalse);
      expect(m.containsKey('lastFetchedAt'), isFalse);
      expect(m['source'], 'user');
      expect(m['sourceType'], 'playlist');
    });
  });

  group('subscriptionRowFromServerJson', () {
    test('parses full subscription JSON', () {
      final t = DateTime.utc(2025, 4, 1);
      final fetched = DateTime.utc(2025, 5, 1);
      final row = subscriptionRowFromServerJson({
        'channelId': 'UC789',
        'displayName': 'Full Channel',
        'thumbnailUrl': 'https://cdn.example/ch.jpg',
        'source': 'recommended',
        'sourceType': 'playlist',
        'feedUrl': 'https://feed.example.com',
        'language': 'ja',
        'subscribedAt': t.toIso8601String(),
        'lastFetchedAt': fetched.toIso8601String(),
      });
      expect(row.channelId, 'UC789');
      expect(row.displayName, 'Full Channel');
      expect(row.thumbnailUrl, 'https://cdn.example/ch.jpg');
      expect(row.source, YoutubeSubscriptionSource.recommended);
      expect(row.sourceType, YoutubeSourceType.playlist);
      expect(row.feedUrl, 'https://feed.example.com');
      expect(row.language, 'ja');
      expect(row.subscribedAt, t);
      expect(row.lastFetchedAt, fetched);
    });

    test('applies defaults for missing optional fields', () {
      final row = subscriptionRowFromServerJson({'channelId': 'UCabc'});
      expect(row.displayName, '');
      expect(row.thumbnailUrl, isNull);
      expect(row.source, YoutubeSubscriptionSource.user);
      expect(row.sourceType, YoutubeSourceType.channel);
      expect(row.feedUrl, isNull);
      expect(row.language, 'und');
      expect(row.lastFetchedAt, isNull);
    });

    test('falls back to user/channel for unknown enum values', () {
      final row = subscriptionRowFromServerJson({
        'channelId': 'UCxyz',
        'source': 'unknown_source',
        'sourceType': 'unknown_type',
      });
      expect(row.source, YoutubeSubscriptionSource.user);
      expect(row.sourceType, YoutubeSourceType.channel);
    });
  });

  group('audioRowFromServerJson', () {
    test('applies defaults for missing optional fields', () {
      final t = DateTime.utc(2025, 6, 1);
      final row = audioRowFromServerJson({
        'id': 'a1',
        'createdAt': t.toIso8601String(),
        'updatedAt': t.toIso8601String(),
      });
      expect(row.aid, 'a1');
      expect(row.provider, 'user');
      expect(row.title, '');
      expect(row.description, isNull);
      expect(row.thumbnailUrl, isNull);
      expect(row.durationSeconds, 0);
      expect(row.language, 'und');
      expect(row.translationKey, isNull);
      expect(row.sourceText, isNull);
      expect(row.voice, isNull);
      expect(row.source, isNull);
      expect(row.localUri, isNull);
      expect(row.md5, isNull);
      expect(row.size, isNull);
      expect(row.mediaUrl, isNull);
      expect(row.syncStatus, 'synced');
      expect(row.serverUpdatedAt, isNull);
    });

    test('uses updatedAt as createdAt fallback', () {
      final t = DateTime.utc(2025, 6, 1);
      final row = audioRowFromServerJson({
        'id': 'a2',
        'updatedAt': t.toIso8601String(),
      });
      expect(row.createdAt, t);
      expect(row.updatedAt, t);
    });

    test('parses serverUpdatedAt when present', () {
      final t = DateTime.utc(2025, 6, 1);
      final serverT = DateTime.utc(2025, 7, 1);
      final row = audioRowFromServerJson({
        'id': 'a3',
        'createdAt': t.toIso8601String(),
        'updatedAt': t.toIso8601String(),
        'serverUpdatedAt': serverT.toIso8601String(),
      });
      expect(row.serverUpdatedAt, serverT);
    });
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

    test('applies defaults for missing fields', () {
      final row = recordingRowFromServerJson({'id': 'r2'});
      expect(row.targetType, 'Audio');
      expect(row.targetId, '');
      expect(row.referenceStart, 0);
      expect(row.referenceDuration, 0);
      expect(row.referenceText, '');
      expect(row.language, 'und');
      expect(row.duration, 0);
      expect(row.md5, isNull);
      expect(row.audioUrl, isNull);
      expect(row.pronunciationScore, isNull);
      expect(row.assessmentJson, isNull);
      expect(row.localPath, isNull);
      expect(row.syncStatus, 'synced');
    });
  });
}
