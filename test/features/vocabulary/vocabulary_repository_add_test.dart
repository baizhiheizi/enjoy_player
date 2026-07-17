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

  const locator = MediaLocator(start: 1000, duration: 5000);

  Future<AddVocabularyResult> add({
    String word = 'Hello!',
    String language = 'en',
    String targetLanguage = 'zh',
    String text = 'Hello world.',
    String sourceId = 'video-1',
    MediaLocator mediaLocator = locator,
  }) => repo.addWithContext(
    word: word,
    language: language,
    targetLanguage: targetLanguage,
    text: text,
    sourceType: VocabularySourceType.video,
    sourceId: sourceId,
    mediaLocator: mediaLocator,
  );

  group('addWithContext', () {
    test('creates new item with defaults and first context', () async {
      final result = await add();
      expect(result.isNewContext, isTrue);
      expect(result.item.word, 'hello');
      expect(result.item.status, VocabularyStatus.new_);
      expect(result.item.easeFactor, 2.5);
      expect(result.item.interval, 0);
      expect(result.item.reviewsCount, 0);
      expect(result.item.contextsCount, 1);
      expect(result.item.syncStatus, 'local');
      expect(result.context.text, 'Hello world.');
      expect(result.context.locator, locator);

      final loaded = await repo.getItem(result.item.id);
      expect(loaded, isNotNull);
      expect(loaded!.contextsCount, 1);
    });

    test('adds second context and bumps contextsCount', () async {
      final first = await add(text: 'First sentence.');
      final second = await add(
        text: 'Second sentence.',
        mediaLocator: const MediaLocator(start: 2000, duration: 3000),
      );
      expect(second.isNewContext, isTrue);
      expect(second.item.id, first.item.id);
      expect(second.item.contextsCount, 2);

      final contexts = await repo.getContextsForItem(first.item.id);
      expect(contexts, hasLength(2));
    });

    test('duplicate media locator is a no-op', () async {
      final first = await add();
      final dup = await add(text: 'Different text same locator');
      expect(dup.isNewContext, isFalse);
      expect(dup.context.id, first.context.id);
      expect(dup.item.contextsCount, 1);

      final contexts = await repo.getContextsForItem(first.item.id);
      expect(contexts, hasLength(1));
    });

    test('different targetLanguage creates a separate item', () async {
      final zh = await add(targetLanguage: 'zh');
      final en = await add(targetLanguage: 'en');
      expect(zh.item.id, isNot(en.item.id));
      expect(zh.item.targetLanguage, 'zh');
      expect(en.item.targetLanguage, 'en');
    });

    test('findByWord normalizes input', () async {
      await add(word: 'Hello!');
      final found = await repo.findByWord(
        word: 'hello',
        language: 'en',
        targetLanguage: 'zh',
      );
      expect(found, isNotNull);
      expect(found!.word, 'hello');
    });
  });
}
