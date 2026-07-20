import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/ai/domain/models/contextual_translation_result.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/vocabulary/data/vocabulary_repository.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_explanation_codec.dart';
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

  test('codec round-trips dictionary and contextual JSON', () {
    const dict = DictionaryResult(
      word: 'hello',
      sourceLanguage: 'en',
      targetLanguage: 'zh',
      ipa: 'həˈləʊ',
      senses: [DictionarySense(definition: 'a greeting', translation: '你好')],
    );
    final dictJson = encodeDictionaryExplanation(dict);
    final decodedDict = decodeDictionaryExplanation(dictJson);
    expect(decodedDict?.word, 'hello');
    expect(decodedDict?.senses.single.definition, 'a greeting');

    const ctx = ContextualTranslationResult(translatedText: '你好世界');
    final ctxJson = encodeContextualExplanation(ctx);
    expect(decodeContextualExplanation(ctxJson)?.translatedText, '你好世界');
    expect(decodeDictionaryExplanation('not-json'), isNull);
  });

  test('updateItemExplanation persists without changing SRS', () async {
    final added = await repo.addWithContext(
      word: 'hello',
      language: 'en',
      targetLanguage: 'zh',
      text: 'Hello world.',
      sourceType: VocabularySourceType.video,
      sourceId: 'v1',
      mediaLocator: locator,
    );
    final before = added.item;
    const dict = DictionaryResult(
      word: 'hello',
      sourceLanguage: 'en',
      targetLanguage: 'zh',
      senses: [DictionarySense(definition: 'greeting')],
    );
    final updated = await repo.updateItemExplanation(
      itemId: before.id,
      explanation: encodeDictionaryExplanation(dict),
    );
    expect(updated, isNotNull);
    expect(updated!.explanation, isNotNull);
    expect(updated.status, before.status);
    expect(updated.easeFactor, before.easeFactor);
    expect(updated.interval, before.interval);
    expect(updated.reviewsCount, before.reviewsCount);
    expect(
      decodeDictionaryExplanation(updated.explanation)?.senses,
      hasLength(1),
    );
  });

  test('updateContextExplanation isolates sibling contexts', () async {
    final first = await repo.addWithContext(
      word: 'hello',
      language: 'en',
      targetLanguage: 'zh',
      text: 'First.',
      sourceType: VocabularySourceType.video,
      sourceId: 'v1',
      mediaLocator: locator,
    );
    final second = await repo.addWithContext(
      word: 'hello',
      language: 'en',
      targetLanguage: 'zh',
      text: 'Second.',
      sourceType: VocabularySourceType.video,
      sourceId: 'v1',
      mediaLocator: const MediaLocator(start: 2000, duration: 3000),
    );
    expect(second.item.id, first.item.id);

    await repo.updateContextExplanation(
      contextId: first.context.id,
      explanation: encodeContextualExplanation(
        const ContextualTranslationResult(translatedText: '第一'),
      ),
    );

    final contexts = await repo.getContextsForItem(first.item.id);
    final a = contexts.firstWhere((c) => c.id == first.context.id);
    final b = contexts.firstWhere((c) => c.id == second.context.id);
    expect(decodeContextualExplanation(a.explanation)?.translatedText, '第一');
    expect(b.explanation, isNull);
  });
}
