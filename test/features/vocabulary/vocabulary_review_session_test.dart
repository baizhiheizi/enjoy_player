import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session.dart';
import 'package:enjoy_player/features/vocabulary/data/vocabulary_repository.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
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

  Future<void> seedWords(int count) async {
    final repo = VocabularyRepository(db);
    for (var i = 0; i < count; i++) {
      await repo.addWithContext(
        word: 'word$i',
        language: 'en',
        targetLanguage: 'zh',
        text: 'Context for word$i',
        sourceType: VocabularySourceType.video,
        sourceId: 'v1',
        mediaLocator: MediaLocator(start: i * 1000, duration: 2000),
        now: DateTime.utc(2020, 1, 1),
      );
    }
  }

  test('flip rate skip undo and in-flight guard', () async {
    await seedWords(3);
    final session = container.read(vocabularyReviewSessionProvider.notifier);

    final started = await session.start(
      const ReviewSelectionOptions(mode: VocabularyReviewMode.all),
      now: DateTime.utc(2030, 1, 1),
    );
    expect(started, isTrue);

    var state = container.read(vocabularyReviewSessionProvider);
    expect(state.total, 3);
    expect(state.flipped, isFalse);

    session.flip();
    state = container.read(vocabularyReviewSessionProvider);
    expect(state.flipped, isTrue);
    expect(state.remaining, 2);

    session.unflip();
    state = container.read(vocabularyReviewSessionProvider);
    expect(state.flipped, isFalse);

    session.toggleFlip();
    state = container.read(vocabularyReviewSessionProvider);
    expect(state.flipped, isTrue);

    await session.rate(VocabularyRating.know);
    state = container.read(vocabularyReviewSessionProvider);
    expect(state.index, 1);
    expect(state.ratedStack, hasLength(1));
    expect(state.flipped, isFalse);

    session.skip();
    state = container.read(vocabularyReviewSessionProvider);
    expect(state.index, 2);

    session.flip();
    await session.rate(VocabularyRating.dontKnow);
    state = container.read(vocabularyReviewSessionProvider);
    expect(state.completed, isTrue);
    expect(state.ratedStack, hasLength(2));

    await session.undo();
    state = container.read(vocabularyReviewSessionProvider);
    expect(state.completed, isFalse);
    expect(state.ratedStack, hasLength(1));
    expect(state.currentItem, isNotNull);
  });

  test('start returns false for empty due queue', () async {
    await seedWords(1);
    final session = container.read(vocabularyReviewSessionProvider.notifier);
    // Items are due in 24h from 2020 seed; "now" before that → empty due.
    final started = await session.start(
      const ReviewSelectionOptions(mode: VocabularyReviewMode.due),
      now: DateTime.utc(2019, 1, 1),
    );
    expect(started, isFalse);
  });
}
