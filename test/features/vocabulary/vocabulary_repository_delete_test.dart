import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/vocabulary/data/vocabulary_repository.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late VocabularyRepository repo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = VocabularyRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('deleteItem cascades contexts and reviews', () async {
    final added = await repo.addWithContext(
      word: 'cascade',
      language: 'en',
      targetLanguage: 'zh',
      text: 'Cascade delete.',
      sourceType: VocabularySourceType.audio,
      sourceId: 'a1',
      mediaLocator: const MediaLocator(start: 0, duration: 500),
    );
    await repo.addWithContext(
      word: 'cascade',
      language: 'en',
      targetLanguage: 'zh',
      text: 'Second context.',
      sourceType: VocabularySourceType.audio,
      sourceId: 'a1',
      mediaLocator: const MediaLocator(start: 500, duration: 500),
    );
    await repo.markReviewed(
      itemId: added.item.id,
      rating: VocabularyRating.know,
    );

    await repo.deleteItem(added.item.id);

    expect(await repo.getItem(added.item.id), isNull);
    expect(await repo.getContextsForItem(added.item.id), isEmpty);
    expect(await db.vocabularyReviewDao.latestForItem(added.item.id), isNull);
  });

  test('deleteItem is a no-op for missing id', () async {
    await repo.deleteItem('missing-id');
  });
}
