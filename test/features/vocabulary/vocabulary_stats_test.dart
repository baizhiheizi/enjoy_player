import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_srs.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_stats.dart';
import 'package:flutter_test/flutter_test.dart';

VocabularyItem _item({
  required String id,
  VocabularyStatus status = VocabularyStatus.new_,
  DateTime? nextReviewAt,
  DateTime? lastReviewedAt,
  String language = 'en',
}) {
  final created = DateTime.utc(2024, 1, 1);
  return VocabularyItem(
    id: id,
    word: id,
    language: language,
    targetLanguage: 'zh',
    status: status,
    easeFactor: kDefaultEaseFactor,
    interval: 0,
    nextReviewAt: nextReviewAt ?? DateTime.utc(2024, 6, 15, 12),
    reviewsCount: 0,
    lastReviewedAt: lastReviewedAt,
    contextsCount: 0,
    createdAt: created,
    updatedAt: created,
  );
}

void main() {
  final now = DateTime.utc(2024, 6, 15, 12);

  group('computeVocabularyStats', () {
    test('empty list yields zeros', () {
      expect(
        computeVocabularyStats([], now: now),
        const VocabularyStats(
          total: 0,
          due: 0,
          newCount: 0,
          learningCount: 0,
          reviewingCount: 0,
          masteredCount: 0,
        ),
      );
    });

    test('counts statuses and due items', () {
      final items = [
        _item(id: 'due-new', status: VocabularyStatus.new_),
        _item(
          id: 'not-due-learning',
          status: VocabularyStatus.learning,
          nextReviewAt: now.add(const Duration(days: 1)),
        ),
        _item(
          id: 'due-reviewing',
          status: VocabularyStatus.reviewing,
          nextReviewAt: now.subtract(const Duration(hours: 1)),
          lastReviewedAt: now.subtract(const Duration(days: 2)),
        ),
        _item(
          id: 'mastered',
          status: VocabularyStatus.mastered,
          nextReviewAt: now.add(const Duration(days: 30)),
        ),
        _item(
          id: 'corrupt-not-due',
          status: VocabularyStatus.new_,
          nextReviewAt: now.subtract(const Duration(days: 1)),
          lastReviewedAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      final stats = computeVocabularyStats(items, now: now);
      expect(stats.total, 5);
      expect(stats.due, 2); // due-new + due-reviewing
      expect(stats.newCount, 2);
      expect(stats.learningCount, 1);
      expect(stats.reviewingCount, 1);
      expect(stats.masteredCount, 1);
      expect(
        stats.newCount +
            stats.learningCount +
            stats.reviewingCount +
            stats.masteredCount,
        stats.total,
      );
    });
  });
}
