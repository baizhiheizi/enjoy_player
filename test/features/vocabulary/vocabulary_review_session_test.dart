import 'package:drift/drift.dart' show QueryExecutor;
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
    final started = await session.start(
      const ReviewSelectionOptions(mode: VocabularyReviewMode.due),
      now: DateTime.utc(2019, 1, 1),
    );
    expect(started, isFalse);
  });

  group('session start bulk context load (issue #827 B2)', () {
    late _CountingContextDb countingDb;
    late ProviderContainer countingContainer;

    setUp(() {
      countingDb = _CountingContextDb(NativeDatabase.memory());
      countingContainer = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(countingDb)],
      );
    });

    tearDown(() async {
      countingContainer.dispose();
      await countingDb.close();
    });

    test(
      'loads all contexts in one bulk query, zero per-item queries',
      () async {
        final repo = VocabularyRepository(countingDb);
        for (var i = 0; i < 4; i++) {
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

        final session = countingContainer.read(
          vocabularyReviewSessionProvider.notifier,
        );
        final started = await session.start(
          const ReviewSelectionOptions(mode: VocabularyReviewMode.all),
          now: DateTime.utc(2030, 1, 1),
        );

        expect(started, isTrue);
        expect(countingDb.contextDao.byItemIdsCalls, 1);
        expect(countingDb.contextDao.byItemIdCalls, 0);
        final state = countingContainer.read(vocabularyReviewSessionProvider);
        expect(state.contextsByItemId.keys, hasLength(4));
        for (final item in state.queue) {
          expect(state.contextsFor(item.id), hasLength(1));
        }
      },
    );

    test('sorts each item contexts by createdAt ascending', () async {
      final repo = VocabularyRepository(countingDb);
      final first = await repo.addWithContext(
        word: 'word0',
        language: 'en',
        targetLanguage: 'zh',
        text: 'later context',
        sourceType: VocabularySourceType.video,
        sourceId: 'v1',
        mediaLocator: const MediaLocator(start: 0, duration: 2000),
        now: DateTime.utc(2020, 1, 5),
      );
      final second = await repo.addWithContext(
        word: 'word0',
        language: 'en',
        targetLanguage: 'zh',
        text: 'earlier context',
        sourceType: VocabularySourceType.video,
        sourceId: 'v2',
        mediaLocator: const MediaLocator(start: 5000, duration: 2000),
        now: DateTime.utc(2020, 1, 1),
      );
      expect(second.item.id, first.item.id);

      final session = countingContainer.read(
        vocabularyReviewSessionProvider.notifier,
      );
      await session.start(
        const ReviewSelectionOptions(mode: VocabularyReviewMode.all),
        now: DateTime.utc(2030, 1, 1),
      );

      final state = countingContainer.read(vocabularyReviewSessionProvider);
      final contexts = state.contextsFor(first.item.id);
      expect(contexts.map((c) => c.text), ['earlier context', 'later context']);
    });
  });
}

class _CountingContextDao extends VocabularyContextDao {
  _CountingContextDao(super.db);

  int byItemIdCalls = 0;
  int byItemIdsCalls = 0;

  @override
  Future<List<VocabularyContextRow>> getByItemId(String vocabularyItemId) {
    byItemIdCalls++;
    return super.getByItemId(vocabularyItemId);
  }

  @override
  Future<List<VocabularyContextRow>> getByItemIds(Iterable<String> itemIds) {
    byItemIdsCalls++;
    return super.getByItemIds(itemIds);
  }
}

class _CountingContextDb extends AppDatabase {
  _CountingContextDb(QueryExecutor executor) : super(executor: executor);

  late final _CountingContextDao contextDao = _CountingContextDao(this);

  @override
  VocabularyContextDao get vocabularyContextDao => contextDao;
}
