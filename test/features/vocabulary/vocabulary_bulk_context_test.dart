import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
import 'package:enjoy_player/features/vocabulary/data/vocabulary_repository.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_locator_json.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SelectCounter extends QueryInterceptor {
  final List<String> statements = <String>[];

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    statements.add(statement);
    return executor.runSelect(statement, args);
  }

  int contextSelects() =>
      statements.where((s) => s.contains('vocabulary_contexts')).length;
}

void main() {
  late AppDatabase db;
  late _SelectCounter counter;

  setUp(() {
    counter = _SelectCounter();
    db = AppDatabase(executor: NativeDatabase.memory().interceptWith(counter));
  });

  tearDown(() async {
    await db.close();
  });

  VocabularyItemRow itemRow(String id, {String word = 'hello'}) =>
      VocabularyItemRow(
        id: id,
        word: word,
        language: 'en',
        targetLanguage: 'zh',
        status: VocabularyStatus.new_.wire,
        easeFactor: 2.5,
        interval: 0,
        nextReviewAt: DateTime.utc(2026, 1, 1),
        reviewsCount: 0,
        lastReviewedAt: null,
        contextsCount: 1,
        explanation: null,
        syncStatus: 'local',
        serverUpdatedAt: null,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

  VocabularyContextRow contextRow({
    required String id,
    required String itemId,
    required String text,
    required DateTime createdAt,
  }) => VocabularyContextRow(
    id: id,
    vocabularyItemId: itemId,
    contextText: text,
    sourceType: VocabularySourceType.video.wire,
    sourceId: 'video-1',
    locatorJson: encodeLocatorForDb(
      media: const MediaLocator(start: 0, duration: 1000),
    ),
    explanation: null,
    syncStatus: 'local',
    serverUpdatedAt: null,
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  group('VocabularyContextDao.firstContextTextsByItemIds', () {
    test('keeps the earliest context per item', () async {
      await db.vocabularyItemDao.insertRow(itemRow('item-1'));
      await db.vocabularyContextDao.insertRow(
        contextRow(
          id: 'ctx-2',
          itemId: 'item-1',
          text: 'later',
          createdAt: DateTime.utc(2026, 1, 2),
        ),
      );
      await db.vocabularyContextDao.insertRow(
        contextRow(
          id: 'ctx-1',
          itemId: 'item-1',
          text: 'earlier',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      final result = await db.vocabularyContextDao.firstContextTextsByItemIds([
        'item-1',
      ]);

      expect(result, {'item-1': 'earlier'});
    });

    test('omits items without contexts', () async {
      await db.vocabularyItemDao.insertRow(itemRow('item-1'));
      await db.vocabularyItemDao.insertRow(itemRow('item-2'));
      await db.vocabularyContextDao.insertRow(
        contextRow(
          id: 'ctx-1',
          itemId: 'item-1',
          text: 'only',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      final result = await db.vocabularyContextDao.firstContextTextsByItemIds([
        'item-1',
        'item-2',
      ]);

      expect(result, {'item-1': 'only'});
    });

    test('returns an empty map for an empty id list', () async {
      final result = await db.vocabularyContextDao.firstContextTextsByItemIds(
        const [],
      );

      expect(result, isEmpty);
    });

    test('chunks long id lists and still returns every item', () async {
      final ids = List<String>.generate(1000, (i) => 'item-$i');
      for (final id in ids) {
        await db.vocabularyItemDao.insertRow(itemRow(id));
        await db.vocabularyContextDao.insertRow(
          contextRow(
            id: 'ctx-$id',
            itemId: id,
            text: 'text for $id',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
      }

      final result = await db.vocabularyContextDao.firstContextTextsByItemIds(
        ids,
      );

      expect(result.length, 1000);
      expect(result['item-0'], 'text for item-0');
      expect(result['item-999'], 'text for item-999');
    });
  });

  group('vocabularyFirstContextsProvider', () {
    ProviderContainer makeContainer() {
      final container = ProviderContainer(
        overrides: [
          vocabularyRepositoryProvider.overrideWithValue(
            VocabularyRepository(db),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    Future<void> awaitItems(ProviderContainer container) {
      final completer = Completer<void>();
      final sub = container.listen(vocabularyItemsProvider, (_, next) {
        if (next.valueOrNull != null && !completer.isCompleted) {
          completer.complete();
        }
      });
      addTearDown(sub.close);
      return completer.future;
    }

    Future<Map<String, String>> awaitContexts(ProviderContainer container) {
      final completer = Completer<Map<String, String>>();
      final sub = container.listen(vocabularyFirstContextsProvider, (_, next) {
        final value = next.valueOrNull;
        if (value != null && !completer.isCompleted) completer.complete(value);
      });
      addTearDown(sub.close);
      return completer.future;
    }

    test('reads every visible word in a single query', () async {
      const itemCount = 25;
      for (var i = 0; i < itemCount; i++) {
        final id = 'item-$i';
        await db.vocabularyItemDao.insertRow(itemRow(id, word: 'word$i'));
        await db.vocabularyContextDao.insertRow(
          contextRow(
            id: 'ctx-$id',
            itemId: id,
            text: 'context $i',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
      }
      counter.statements.clear();

      final container = makeContainer();
      await awaitItems(container);
      final contexts = await awaitContexts(container);

      expect(contexts.length, itemCount);
      expect(contexts['item-0'], 'context 0');
      expect(contexts['item-24'], 'context 24');
      expect(counter.contextSelects(), 1);
    });

    test('issues no query when no word is visible', () async {
      final container = makeContainer();
      await awaitItems(container);
      final contexts = await awaitContexts(container);

      expect(contexts, isEmpty);
      expect(counter.contextSelects(), 0);
    });
  });
}
