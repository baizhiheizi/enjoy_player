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
    test('null local returns server row as new insert', () {
      final serverTime = DateTime.utc(2026, 1, 5);
      final merged = mergeVocabularyContextLastWriteWins(
        local: null,
        server: {
          'id': 'ctx-new',
          'vocabularyItemId': 'item-1',
          'text': 'New context from server.',
          'sourceType': 'Audio',
          'sourceId': 'a1',
          'locator': {'type': 'text', 'start': 5},
          'createdAt': serverTime.toIso8601String(),
          'updatedAt': serverTime.toIso8601String(),
        },
      );
      expect(merged.id, 'ctx-new');
      expect(merged.contextText, 'New context from server.');
      expect(merged.sourceType, 'Audio');
    });

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

  group('mergeVocabularyItemConflict adoptServerMetadata', () {
    test('local SRS newer but server.updatedAt after localSrsReference '
        'adopts server word/explanation', () {
      final localReviewTime = DateTime.utc(2026, 1, 10);
      final localUpdatedAt = DateTime.utc(2026, 1, 10);
      final serverTime = DateTime.utc(2026, 1, 20);
      final local = _itemRow(
        word: 'Local Word',
        explanation: 'Local explanation',
        easeFactor: 3.0,
        interval: 15,
        reviewsCount: 5,
        lastReviewedAt: localReviewTime,
        createdAt: localUpdatedAt,
        updatedAt: localUpdatedAt,
      );

      final merged = mergeVocabularyItemConflict(
        local: local,
        server: {
          'id': 'item-1',
          'word': 'Server Word',
          'language': 'en',
          'targetLanguage': 'zh-CN',
          'status': 'learning',
          'easeFactor': 2.5,
          'interval': 1,
          'nextReviewAt': serverTime.toIso8601String(),
          'reviewsCount': 2,
          'lastReviewedAt': DateTime.utc(2026, 1, 5).toIso8601String(),
          'contextsCount': 3,
          'explanation': 'Server explanation',
          'createdAt': serverTime.toIso8601String(),
          'updatedAt': serverTime.toIso8601String(),
        },
      );

      expect(merged.word, 'Server Word');
      expect(merged.explanation, 'Server explanation');
      expect(merged.easeFactor, 3.0);
      expect(merged.interval, 15);
      expect(merged.reviewsCount, 5);
      expect(merged.syncStatus, 'synced');
    });

    test('local SRS newer and server.updatedAt before localSrsReference '
        'keeps local word/explanation', () {
      final localReviewTime = DateTime.utc(2026, 2, 1);
      final serverTime = DateTime.utc(2026, 1, 15);
      final local = _itemRow(
        word: 'Local Word',
        explanation: 'Local explanation',
        easeFactor: 3.0,
        interval: 15,
        reviewsCount: 5,
        lastReviewedAt: localReviewTime,
        createdAt: localReviewTime,
        updatedAt: localReviewTime,
      );

      final merged = mergeVocabularyItemConflict(
        local: local,
        server: {
          'id': 'item-1',
          'word': 'Server Word',
          'language': 'en',
          'targetLanguage': 'zh-CN',
          'status': 'learning',
          'easeFactor': 2.5,
          'interval': 1,
          'nextReviewAt': serverTime.toIso8601String(),
          'reviewsCount': 2,
          'lastReviewedAt': DateTime.utc(2026, 1, 5).toIso8601String(),
          'contextsCount': 3,
          'explanation': 'Server explanation',
          'createdAt': serverTime.toIso8601String(),
          'updatedAt': serverTime.toIso8601String(),
        },
      );

      expect(merged.word, 'Local Word');
      expect(merged.explanation, 'Local explanation');
      expect(merged.easeFactor, 3.0);
      expect(merged.interval, 15);
    });

    test('neither side reviewed: higher reviewsCount wins SRS', () {
      final localTime = DateTime.utc(2026, 1, 10);
      final serverTime = DateTime.utc(2026, 1, 20);
      final local = _itemRow(
        word: 'Local Word',
        reviewsCount: 10,
        lastReviewedAt: null,
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
          'status': 'learning',
          'easeFactor': 2.5,
          'interval': 1,
          'nextReviewAt': serverTime.toIso8601String(),
          'reviewsCount': 3,
          'contextsCount': 1,
          'createdAt': serverTime.toIso8601String(),
          'updatedAt': serverTime.toIso8601String(),
        },
      );

      expect(merged.reviewsCount, 10);
      expect(merged.easeFactor, 2.5);
      expect(merged.syncStatus, 'synced');
    });
  });

  group('vocabularyContextRowFromServerJson', () {
    test('handles null locator as empty JSON object', () {
      final t = DateTime.utc(2026, 1, 1);
      final row = vocabularyContextRowFromServerJson({
        'id': 'ctx-1',
        'vocabularyItemId': 'item-1',
        'text': 'Hello',
        'sourceType': 'Video',
        'sourceId': 'v1',
        'locator': null,
        'createdAt': t.toIso8601String(),
        'updatedAt': t.toIso8601String(),
      });
      expect(row.locatorJson, '{}');
    });

    test('handles String locator passthrough', () {
      final t = DateTime.utc(2026, 1, 1);
      final row = vocabularyContextRowFromServerJson({
        'id': 'ctx-2',
        'vocabularyItemId': 'item-1',
        'text': 'Hello',
        'sourceType': 'Video',
        'sourceId': 'v1',
        'locator': '{"type":"text","start":5}',
        'createdAt': t.toIso8601String(),
        'updatedAt': t.toIso8601String(),
      });
      expect(row.locatorJson, '{"type":"text","start":5}');
    });

    test('handles Map locator by encoding to JSON', () {
      final t = DateTime.utc(2026, 1, 1);
      final row = vocabularyContextRowFromServerJson({
        'id': 'ctx-3',
        'vocabularyItemId': 'item-1',
        'text': 'Hello',
        'sourceType': 'Audio',
        'sourceId': 'a1',
        'locator': {'type': 'media', 'start': 0, 'duration': 2000},
        'createdAt': t.toIso8601String(),
        'updatedAt': t.toIso8601String(),
      });
      expect(row.locatorJson, contains('"type":"media"'));
      expect(row.locatorJson, contains('"duration":2000'));
    });

    test('applies defaults for missing fields', () {
      final row = vocabularyContextRowFromServerJson({'id': 'ctx-4'});
      expect(row.vocabularyItemId, '');
      expect(row.contextText, '');
      expect(row.sourceType, 'Video');
      expect(row.sourceId, '');
      expect(row.locatorJson, '{}');
      expect(row.explanation, isNull);
      expect(row.syncStatus, 'synced');
      expect(row.serverUpdatedAt, isNull);
    });
  });

  group('vocabularyItemRowFromServerJson', () {
    test('applies defaults for missing fields', () {
      final row = vocabularyItemRowFromServerJson({'id': 'item-x'});
      expect(row.word, '');
      expect(row.language, 'und');
      expect(row.targetLanguage, 'und');
      expect(row.status, 'new');
      expect(row.easeFactor, 2.5);
      expect(row.interval, 0);
      expect(row.reviewsCount, 0);
      expect(row.lastReviewedAt, isNull);
      expect(row.contextsCount, 0);
      expect(row.explanation, isNull);
      expect(row.syncStatus, 'synced');
      expect(row.serverUpdatedAt, isNull);
    });

    test('parses numeric fields from num types', () {
      final t = DateTime.utc(2026, 1, 1);
      final row = vocabularyItemRowFromServerJson({
        'id': 'item-y',
        'word': 'test',
        'easeFactor': 3,
        'interval': 5.0,
        'reviewsCount': 2.0,
        'contextsCount': 1.5,
        'nextReviewAt': t.toIso8601String(),
        'createdAt': t.toIso8601String(),
        'updatedAt': t.toIso8601String(),
      });
      expect(row.easeFactor, 3.0);
      expect(row.interval, 5);
      expect(row.reviewsCount, 2);
      expect(row.contextsCount, 1);
    });
  });

  group('prepareForSyncVocabularyItemMap with optional fields', () {
    test('includes lastReviewedAt and explanation when present', () {
      final now = DateTime.utc(2026, 1, 1);
      final reviewed = DateTime.utc(2025, 12, 25);
      final row = _itemRow(
        lastReviewedAt: reviewed,
        explanation: 'A greeting',
        createdAt: now,
        updatedAt: now,
      );
      final m = prepareForSyncVocabularyItemMap(row);
      expect(m['lastReviewedAt'], reviewed.toUtc().toIso8601String());
      expect(m['explanation'], 'A greeting');
    });
  });

  group('prepareForSyncVocabularyContextMap with explanation', () {
    test('includes explanation when present', () {
      final now = DateTime.utc(2026, 1, 1);
      final row = _contextRow(
        explanation: 'Used as a greeting',
        createdAt: now,
        updatedAt: now,
      );
      final m = prepareForSyncVocabularyContextMap(row);
      expect(m['explanation'], 'Used as a greeting');
    });

    test('omits explanation when null', () {
      final now = DateTime.utc(2026, 1, 1);
      final row = _contextRow(
        explanation: null,
        createdAt: now,
        updatedAt: now,
      );
      final m = prepareForSyncVocabularyContextMap(row);
      expect(m.containsKey('explanation'), isFalse);
    });
  });
}
