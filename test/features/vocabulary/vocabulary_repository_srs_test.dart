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

  Future<VocabularyItem> seedItem() async {
    final result = await repo.addWithContext(
      word: 'review',
      language: 'en',
      targetLanguage: 'zh',
      text: 'Review this word.',
      sourceType: VocabularySourceType.video,
      sourceId: 'v1',
      mediaLocator: const MediaLocator(start: 0, duration: 1000),
    );
    return result.item;
  }

  group('markReviewed / undoLatestReview', () {
    test('markReviewed applies SRS and writes audit', () async {
      final item = await seedItem();
      final now = DateTime.utc(2024, 6, 15, 12);
      final updated = await repo.markReviewed(
        itemId: item.id,
        rating: VocabularyRating.know,
        now: now,
      );
      expect(updated, isNotNull);
      expect(updated!.status, VocabularyStatus.learning);
      expect(updated.interval, 1);
      expect(updated.reviewsCount, 1);
      expect(updated.lastReviewedAt, now);

      final latest = await db.vocabularyReviewDao.latestForItem(item.id);
      expect(latest, isNotNull);
      expect(latest!.rating, 1);
      expect(latest.reviewsCountBefore, 0);
      expect(latest.statusBefore, 'new');
    });

    test('undoLatestReview restores pre-image', () async {
      final item = await seedItem();
      final before = await repo.getItem(item.id);
      await repo.markReviewed(
        itemId: item.id,
        rating: VocabularyRating.knowWell,
        now: DateTime.utc(2024, 6, 15, 12),
      );
      final undone = await repo.undoLatestReview(item.id);
      expect(undone, isNotNull);
      expect(undone!.status, before!.status);
      expect(undone.easeFactor, before.easeFactor);
      expect(undone.interval, before.interval);
      expect(undone.reviewsCount, before.reviewsCount);
      expect(undone.nextReviewAt, before.nextReviewAt);
      expect(undone.lastReviewedAt, before.lastReviewedAt);

      final audit = await db.vocabularyReviewDao.latestForItem(item.id);
      expect(audit, isNull);
    });

    test('undo with empty stack returns null', () async {
      final item = await seedItem();
      expect(await repo.undoLatestReview(item.id), isNull);
    });

    test('second undo after one review returns null', () async {
      final item = await seedItem();
      await repo.markReviewed(itemId: item.id, rating: VocabularyRating.know);
      await repo.undoLatestReview(item.id);
      expect(await repo.undoLatestReview(item.id), isNull);
    });
  });
}
