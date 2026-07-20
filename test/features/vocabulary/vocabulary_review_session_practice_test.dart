import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session.dart';
import 'package:enjoy_player/features/vocabulary/data/vocabulary_repository.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_review_practice.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_session_selection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('loads all contexts and defaults to earliest index', () async {
    final repo = VocabularyRepository(db);
    final first = await repo.addWithContext(
      word: 'relic',
      language: 'en',
      targetLanguage: 'zh',
      text: 'first context',
      sourceType: VocabularySourceType.video,
      sourceId: 'v1',
      mediaLocator: const MediaLocator(start: 0, duration: 1000),
      now: DateTime.utc(2020, 1, 1),
    );
    await repo.addWithContext(
      word: 'relic',
      language: 'en',
      targetLanguage: 'zh',
      text: 'second context',
      sourceType: VocabularySourceType.video,
      sourceId: 'v2',
      mediaLocator: const MediaLocator(start: 2000, duration: 1000),
      now: DateTime.utc(2020, 1, 2),
    );

    final session = container.read(vocabularyReviewSessionProvider.notifier);
    await session.start(
      const ReviewSelectionOptions(mode: VocabularyReviewMode.all),
      now: DateTime.utc(2030, 1, 1),
    );
    final state = container.read(vocabularyReviewSessionProvider);
    expect(state.currentContextsCount, 2);
    expect(state.currentActiveContextIndex, 0);
    expect(state.currentPrimaryContext?.text, 'first context');
    expect(state.currentPrimaryContext?.id, first.context.id);
  });

  test('selectContext clamps and updates active context', () async {
    final repo = VocabularyRepository(db);
    await repo.addWithContext(
      word: 'relic',
      language: 'en',
      targetLanguage: 'zh',
      text: 'first',
      sourceType: VocabularySourceType.video,
      sourceId: 'v1',
      mediaLocator: const MediaLocator(start: 0, duration: 1000),
      now: DateTime.utc(2020, 1, 1),
    );
    await repo.addWithContext(
      word: 'relic',
      language: 'en',
      targetLanguage: 'zh',
      text: 'second',
      sourceType: VocabularySourceType.video,
      sourceId: 'v2',
      mediaLocator: const MediaLocator(start: 0, duration: 1000),
      now: DateTime.utc(2020, 1, 2),
    );

    final session = container.read(vocabularyReviewSessionProvider.notifier);
    await session.start(
      const ReviewSelectionOptions(mode: VocabularyReviewMode.all),
      now: DateTime.utc(2030, 1, 1),
    );
    await session.selectContext(1);
    expect(
      container
          .read(vocabularyReviewSessionProvider)
          .currentPrimaryContext
          ?.text,
      'second',
    );
    await session.selectContext(99);
    expect(
      container.read(vocabularyReviewSessionProvider).currentActiveContextIndex,
      1,
    );
  });

  test('rate and flip blocked while practice sheet open', () async {
    final item = VocabularyItem(
      id: 'i1',
      word: 'hello',
      language: 'en',
      targetLanguage: 'zh',
      status: VocabularyStatus.new_,
      easeFactor: 2.5,
      interval: 0,
      reviewsCount: 0,
      nextReviewAt: DateTime.utc(2030),
      createdAt: DateTime.utc(2020),
      updatedAt: DateTime.utc(2020),
      contextsCount: 1,
    );
    final session = container.read(vocabularyReviewSessionProvider.notifier);
    session.startWithQueue([item]);
    session.debugSetPracticeMode(ReviewPracticeMode.clip);
    session.flip();
    expect(container.read(vocabularyReviewSessionProvider).flipped, isFalse);

    await session.clearPractice();
    session.flip();
    expect(container.read(vocabularyReviewSessionProvider).flipped, isTrue);

    session.debugSetPracticeMode(ReviewPracticeMode.echo);
    await session.rate(VocabularyRating.know);
    expect(container.read(vocabularyReviewSessionProvider).flipped, isTrue);
    expect(container.read(vocabularyReviewSessionProvider).index, 0);
  });

  test(
    'preparePracticeClip enters clipOpening without claiming surface',
    () async {
      final repo = VocabularyRepository(db);
      await repo.addWithContext(
        word: 'clip',
        language: 'en',
        targetLanguage: 'zh',
        text: 'segment',
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
      session.preparePracticeClip();
      final state = container.read(vocabularyReviewSessionProvider);
      expect(state.practicePhase, ReviewPracticePhase.clipOpening);
      expect(state.practiceMode, ReviewPracticeMode.clip);
      expect(state.clipPlayInFlight, isTrue);
      expect(state.claimsVideoSurface, isFalse);
    },
  );

  test('clearPractice resets phase and keeps review session', () async {
    final repo = VocabularyRepository(db);
    await repo.addWithContext(
      word: 'hello',
      language: 'en',
      targetLanguage: 'zh',
      text: 'segment',
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
    session.preparePracticeClip();
    await session.clearPractice();
    final state = container.read(vocabularyReviewSessionProvider);
    expect(state.practicePhase, ReviewPracticePhase.none);
    expect(state.practiceMode, ReviewPracticeMode.none);
    expect(state.hasActiveSession, isTrue);
    expect(state.currentItem?.word, 'hello');
  });

  test('openPracticeEcho is recorder-only (no player session)', () async {
    final repo = VocabularyRepository(db);
    await repo.addWithContext(
      word: 'echo',
      language: 'en',
      targetLanguage: 'zh',
      text: 'say it',
      sourceType: VocabularySourceType.video,
      sourceId: 'v1',
      mediaLocator: const MediaLocator(start: 1000, duration: 2000),
      now: DateTime.utc(2020, 1, 1),
    );
    final session = container.read(vocabularyReviewSessionProvider.notifier);
    await session.start(
      const ReviewSelectionOptions(mode: VocabularyReviewMode.all),
      now: DateTime.utc(2030, 1, 1),
    );
    await session.openPracticeEcho();
    final state = container.read(vocabularyReviewSessionProvider);
    expect(state.practicePhase, ReviewPracticePhase.echo);
    expect(state.claimsVideoSurface, isFalse);
    expect(container.read(playerControllerProvider), isNull);
  });

  test('selectContext clears practice mode', () async {
    final repo = VocabularyRepository(db);
    await repo.addWithContext(
      word: 'relic',
      language: 'en',
      targetLanguage: 'zh',
      text: 'first',
      sourceType: VocabularySourceType.video,
      sourceId: 'v1',
      mediaLocator: const MediaLocator(start: 0, duration: 1000),
      now: DateTime.utc(2020, 1, 1),
    );
    await repo.addWithContext(
      word: 'relic',
      language: 'en',
      targetLanguage: 'zh',
      text: 'second',
      sourceType: VocabularySourceType.video,
      sourceId: 'v2',
      mediaLocator: const MediaLocator(start: 0, duration: 1000),
      now: DateTime.utc(2020, 1, 2),
    );

    final session = container.read(vocabularyReviewSessionProvider.notifier);
    await session.start(
      const ReviewSelectionOptions(mode: VocabularyReviewMode.all),
      now: DateTime.utc(2030, 1, 1),
    );
    session.debugSetPracticeMode(ReviewPracticeMode.clip);
    await session.selectContext(1);
    expect(
      container.read(vocabularyReviewSessionProvider).practiceMode,
      ReviewPracticeMode.none,
    );
  });
}
