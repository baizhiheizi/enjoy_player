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
      expect(m.containsKey('syncStatus'), isFalse);
      expect(m['duration'], 10);
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
