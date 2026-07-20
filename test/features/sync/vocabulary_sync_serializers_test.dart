import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/sync/data/sync_serializers.dart';
import 'package:flutter_test/flutter_test.dart';

VocabularyItemRow _itemRow({
  String id = 'item-1',
  String word = 'hello',
  String status = 'learning',
  double easeFactor = 2.5,
  int interval = 1,
  DateTime? nextReviewAt,
  int reviewsCount = 1,
  DateTime? lastReviewedAt,
  int contextsCount = 1,
  String? explanation,
  String syncStatus = 'local',
  DateTime? serverUpdatedAt,
  required DateTime createdAt,
  required DateTime updatedAt,
}) {
  return VocabularyItemRow(
    id: id,
    word: word,
    language: 'en',
    targetLanguage: 'zh-CN',
    status: status,
    easeFactor: easeFactor,
    interval: interval,
    nextReviewAt: nextReviewAt ?? updatedAt,
    reviewsCount: reviewsCount,
    lastReviewedAt: lastReviewedAt,
    contextsCount: contextsCount,
    explanation: explanation,
    syncStatus: syncStatus,
    serverUpdatedAt: serverUpdatedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

VocabularyContextRow _contextRow({
  String id = 'ctx-1',
  String vocabularyItemId = 'item-1',
  String contextText = 'Hello world.',
  String sourceType = 'Video',
  String sourceId = 'v1',
  String locatorJson = '{"duration":1000,"start":0,"type":"media"}',
  String? explanation,
  String syncStatus = 'local',
  DateTime? serverUpdatedAt,
  required DateTime createdAt,
  required DateTime updatedAt,
}) {
  return VocabularyContextRow(
    id: id,
    vocabularyItemId: vocabularyItemId,
    contextText: contextText,
    sourceType: sourceType,
    sourceId: sourceId,
    locatorJson: locatorJson,
    explanation: explanation,
    syncStatus: syncStatus,
    serverUpdatedAt: serverUpdatedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

void main() {
  group('prepareForSyncVocabularyItemMap', () {
    test('omits local-only sync bookkeeping fields', () {
      final now = DateTime.utc(2026, 1, 1);
      final row = _itemRow(createdAt: now, updatedAt: now);
      final m = prepareForSyncVocabularyItemMap(row);

      expect(m.containsKey('syncStatus'), isFalse);
      expect(m.containsKey('serverUpdatedAt'), isFalse);
      expect(m['id'], 'item-1');
      expect(m['word'], 'hello');
      expect(m['language'], 'en');
      expect(m['targetLanguage'], 'zh-CN');
      expect(m['reviewsCount'], 1);
    });

    test('omits lastReviewedAt / explanation when null', () {
      final now = DateTime.utc(2026, 1, 1);
      final row = _itemRow(
        createdAt: now,
        updatedAt: now,
        lastReviewedAt: null,
        explanation: null,
      );
      final m = prepareForSyncVocabularyItemMap(row);
      expect(m.containsKey('lastReviewedAt'), isFalse);
      expect(m.containsKey('explanation'), isFalse);
    });
  });

  group('prepareForSyncVocabularyContextMap', () {
    test('serializes the locator JSON as a nested object, not a string', () {
      final now = DateTime.utc(2026, 1, 1);
      final row = _contextRow(createdAt: now, updatedAt: now);
      final m = prepareForSyncVocabularyContextMap(row);

      expect(m['text'], 'Hello world.');
      expect(m['locator'], isA<Map<String, dynamic>>());
      expect((m['locator'] as Map)['type'], 'media');
      expect(m.containsKey('contextText'), isFalse);
    });
  });

  group('mergeVocabularyItemConflict', () {
    test('missing local row: takes server row as-is', () {
      final serverTime = DateTime.utc(2026, 1, 5);
      final merged = mergeVocabularyItemConflict(
        local: null,
        server: {
          'id': 'item-1',
          'word': 'hello',
          'language': 'en',
          'targetLanguage': 'zh-CN',
          'status': 'learning',
          'easeFactor': 2.5,
          'interval': 1,
          'nextReviewAt': serverTime.toIso8601String(),
          'reviewsCount': 1,
          'contextsCount': 1,
          'createdAt': serverTime.toIso8601String(),
          'updatedAt': serverTime.toIso8601String(),
        },
      );
      expect(merged.id, 'item-1');
      expect(merged.word, 'hello');
    });

    test('local SRS newer keeps local SRS fields on merge', () {
      final localTime = DateTime.utc(2026, 2, 1);
      final serverTime = DateTime.utc(2026, 1, 15);
      final local = _itemRow(
        word: 'Local Word',
        easeFactor: 3.2,
        interval: 20,
        reviewsCount: 8,
        lastReviewedAt: localTime,
        syncStatus: 'local',
        createdAt: localTime,
        updatedAt: localTime,
      );

      final merged = mergeVocabularyItemConflict(
        local: local,
        server: {
          'id': 'item-1',
          'word': 'Server Word',
          'language': 'en',
          'targetLanguage': 'zh-CN',
          'status': 'reviewing',
          'easeFactor': 2.5,
          'interval': 1,
          'nextReviewAt': serverTime.toIso8601String(),
          'reviewsCount': 1,
          'contextsCount': 1,
          'createdAt': serverTime.toIso8601String(),
          'updatedAt': serverTime.toIso8601String(),
        },
      );

      expect(merged.easeFactor, 3.2);
      expect(merged.interval, 20);
      expect(merged.reviewsCount, 8);
      // server.updatedAt (Jan 15) predates local's SRS reference
      // (lastReviewedAt Feb 1), so local word/metadata is kept too.
      expect(merged.word, 'Local Word');
      expect(merged.syncStatus, 'synced');
      expect(merged.serverUpdatedAt, localTime);
    });

    test('server SRS newer takes the server row', () {
      final localTime = DateTime.utc(2026, 1, 1);
      final serverTime = DateTime.utc(2026, 2, 1);
      final local = _itemRow(
        word: 'Local Word',
        reviewsCount: 1,
        lastReviewedAt: localTime,
        createdAt: localTime,
        updatedAt: localTime,
      );

      final merged = mergeVocabularyItemConflict(
        local: local,
        server: {
          'id': 'item-1',
          'word': 'Server Word',
          'language': 'en',
          'targetLanguage': 'zh-CN',
          'status': 'reviewing',
          'easeFactor': 2.8,
          'interval': 5,
          'lastReviewedAt': serverTime.toIso8601String(),
          'nextReviewAt': serverTime.toIso8601String(),
          'reviewsCount': 3,
          'contextsCount': 1,
          'createdAt': serverTime.toIso8601String(),
          'updatedAt': serverTime.toIso8601String(),
        },
      );

      expect(merged.word, 'Server Word');
      expect(merged.reviewsCount, 3);
      expect(merged.easeFactor, 2.8);
    });
  });

  group('mergeVocabularyContextLastWriteWins', () {
    test('server wins on ties (matches web resolveConflict)', () {
      final t = DateTime.utc(2026, 1, 1);
      final local = _contextRow(
        contextText: 'Local text',
        createdAt: t,
        updatedAt: t,
      );
      final merged = mergeVocabularyContextLastWriteWins(
        local: local,
        server: {
          'id': 'ctx-1',
          'vocabularyItemId': 'item-1',
          'text': 'Server text',
          'sourceType': 'Video',
          'sourceId': 'v1',
          'locator': {'type': 'media', 'start': 0, 'duration': 1000},
          'createdAt': t.toIso8601String(),
          'updatedAt': t.toIso8601String(),
        },
      );
      expect(merged.contextText, 'Server text');
    });

    test('local newer keeps local row', () {
      final localTime = DateTime.utc(2026, 2, 1);
      final serverTime = DateTime.utc(2026, 1, 1);
      final local = _contextRow(
        contextText: 'Local text',
        createdAt: localTime,
        updatedAt: localTime,
      );
      final merged = mergeVocabularyContextLastWriteWins(
        local: local,
        server: {
          'id': 'ctx-1',
          'vocabularyItemId': 'item-1',
          'text': 'Server text',
          'sourceType': 'Video',
          'sourceId': 'v1',
          'locator': {'type': 'media', 'start': 0, 'duration': 1000},
          'createdAt': serverTime.toIso8601String(),
          'updatedAt': serverTime.toIso8601String(),
        },
      );
      expect(merged.contextText, 'Local text');
    });
  });
}
