import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';
import 'package:enjoy_player/features/vocabulary/data/vocabulary_repository.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';

void main() {
  late AppDatabase db;
  late List<(SyncEntityType, String, SyncAction)> enqueued;
  late VocabularyRepository repo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    enqueued = [];
    repo = VocabularyRepository(
      db,
      enqueueSync: (type, id, action) async {
        enqueued.add((type, id, action));
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('addWithContext enqueues item+context create; never reviews', () async {
    final result = await repo.addWithContext(
      word: 'hello',
      language: 'en',
      targetLanguage: 'zh',
      text: 'Hello there',
      sourceType: VocabularySourceType.video,
      sourceId: 'v1',
      mediaLocator: const MediaLocator(start: 0, duration: 1000),
    );
    expect(result.isNewContext, isTrue);
    expect(
      enqueued.map((e) => (e.$1, e.$3)),
      containsAll([
        (SyncEntityType.vocabularyItem, SyncAction.create),
        (SyncEntityType.vocabularyContext, SyncAction.create),
      ]),
    );
    expect(enqueued.any((e) => e.$1.name.contains('review')), isFalse);
  });

  test('markReviewed enqueues item update only', () async {
    final added = await repo.addWithContext(
      word: 'world',
      language: 'en',
      targetLanguage: 'zh',
      text: 'World peace',
      sourceType: VocabularySourceType.audio,
      sourceId: 'a1',
      mediaLocator: const MediaLocator(start: 0, duration: 500),
    );
    enqueued.clear();
    await repo.markReviewed(
      itemId: added.item.id,
      rating: VocabularyRating.know,
    );
    expect(enqueued, hasLength(1));
    expect(enqueued.single.$1, SyncEntityType.vocabularyItem);
    expect(enqueued.single.$3, SyncAction.update);
  });

  test('deleteItem enqueues item delete', () async {
    final added = await repo.addWithContext(
      word: 'bye',
      language: 'en',
      targetLanguage: 'zh',
      text: 'Goodbye',
      sourceType: VocabularySourceType.video,
      sourceId: 'v2',
      mediaLocator: const MediaLocator(start: 10, duration: 20),
    );
    enqueued.clear();
    await repo.deleteItem(added.item.id);
    expect(
      enqueued,
      contains((
        SyncEntityType.vocabularyItem,
        added.item.id,
        SyncAction.delete,
      )),
    );
  });
}
