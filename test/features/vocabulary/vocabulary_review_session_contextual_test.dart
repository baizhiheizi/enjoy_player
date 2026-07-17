import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/ai/application/ai_capability_providers.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/contextual_translation_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/contextual_translation_result.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session.dart';
import 'package:enjoy_player/features/vocabulary/data/vocabulary_repository.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_explanation_codec.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_session_selection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeContextual implements ContextualTranslationCapability {
  const _FakeContextual();

  @override
  Future<ContextualTranslationResult> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    String? context,
  }) async {
    return ContextualTranslationResult(translatedText: '译:$text');
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
        contextualTranslationCapabilityProvider.overrideWithValue(
          const _FakeContextual(),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('fetchContextualTranslation updates only primary context', () async {
    final repo = VocabularyRepository(db);
    final first = await repo.addWithContext(
      word: 'hello',
      language: 'en',
      targetLanguage: 'zh',
      text: 'First sentence.',
      sourceType: VocabularySourceType.video,
      sourceId: 'v1',
      mediaLocator: const MediaLocator(start: 0, duration: 1000),
      now: DateTime.utc(2020, 1, 1),
    );
    final second = await repo.addWithContext(
      word: 'hello',
      language: 'en',
      targetLanguage: 'zh',
      text: 'Second sentence.',
      sourceType: VocabularySourceType.video,
      sourceId: 'v1',
      mediaLocator: const MediaLocator(start: 2000, duration: 1000),
      now: DateTime.utc(2020, 1, 2),
    );

    final session = container.read(vocabularyReviewSessionProvider.notifier);
    await session.start(
      const ReviewSelectionOptions(mode: VocabularyReviewMode.all),
      now: DateTime.utc(2030, 1, 1),
    );
    session.flip();
    await session.fetchContextualTranslation();

    final state = container.read(vocabularyReviewSessionProvider);
    final primary = state.primaryContextFor(first.item.id)!;
    expect(primary.id, first.context.id); // earliest createdAt
    expect(
      decodeContextualExplanation(primary.explanation)?.translatedText,
      '译:First sentence.',
    );

    final contexts = await repo.getContextsForItem(first.item.id);
    final sibling = contexts.firstWhere((c) => c.id == second.context.id);
    expect(sibling.explanation, isNull);
  });
}
