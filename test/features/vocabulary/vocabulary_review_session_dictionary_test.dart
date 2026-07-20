import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/ai/application/ai_capability_providers.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/dictionary_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session.dart';
import 'package:enjoy_player/features/vocabulary/data/vocabulary_repository.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_explanation_codec.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_session_selection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeDictionary implements DictionaryCapability {
  const _FakeDictionary();

  @override
  Future<DictionaryResult> lookupDictionary({
    required String word,
    required String sourceLanguage,
    required String targetLanguage,
    bool? forceRefresh,
  }) async {
    return DictionaryResult(
      word: word,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      senses: const [DictionarySense(definition: 'test sense')],
    );
  }
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        dictionaryCapabilityProvider.overrideWithValue(const _FakeDictionary()),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('fetchDictionary persists explanation without changing SRS', () async {
    final repo = VocabularyRepository(db);
    final added = await repo.addWithContext(
      word: 'hello',
      language: 'en',
      targetLanguage: 'zh',
      text: 'Hello world.',
      sourceType: VocabularySourceType.video,
      sourceId: 'v1',
      mediaLocator: const MediaLocator(start: 0, duration: 1000),
      now: DateTime.utc(2020, 1, 1),
    );

    final session = container.read(vocabularyReviewSessionProvider.notifier);
    await session.start(
      const ReviewSelectionOptions(mode: VocabularyReviewMode.all),
      now: DateTime.utc(2030, 1, 1),
    );
    session.flip();
    await session.fetchDictionary();

    final state = container.read(vocabularyReviewSessionProvider);
    expect(state.dictionaryFetchInFlight, isFalse);
    expect(state.dictionaryError, isNull);
    final item = state.queue.single;
    expect(item.explanation, isNotNull);
    expect(
      decodeDictionaryExplanation(item.explanation)?.senses.single.definition,
      'test sense',
    );
    expect(item.status, added.item.status);
    expect(item.reviewsCount, added.item.reviewsCount);
    expect(item.easeFactor, added.item.easeFactor);
  });
}
