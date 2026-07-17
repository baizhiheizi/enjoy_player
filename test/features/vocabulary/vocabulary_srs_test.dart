import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_srs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixedNow = DateTime.utc(2024, 6, 15, 12, 30, 0);

  ReviewUpdate review({
    double easeFactor = kDefaultEaseFactor,
    int interval = 0,
    int reviewsCount = 0,
    VocabularyStatus status = VocabularyStatus.new_,
    required VocabularyRating rating,
    DateTime? now,
  }) => calculateNextReview(
    easeFactor: easeFactor,
    interval: interval,
    reviewsCount: reviewsCount,
    status: status,
    rating: rating,
    now: now ?? fixedNow,
  );

  group('calculateNextReview — rating 0', () {
    test('resets interval to MIN', () {
      expect(
        review(interval: 10, rating: VocabularyRating.dontKnow).interval,
        1,
      );
    });

    test('decreases ease by 0.15', () {
      expect(
        review(easeFactor: 2.5, rating: VocabularyRating.dontKnow).easeFactor,
        closeTo(2.35, 1e-10),
      );
    });

    test('clamps ease at MIN', () {
      expect(
        review(easeFactor: 1.4, rating: VocabularyRating.dontKnow).easeFactor,
        greaterThanOrEqualTo(kMinEaseFactor),
      );
    });

    test('sets status to new', () {
      expect(
        review(
          status: VocabularyStatus.reviewing,
          rating: VocabularyRating.dontKnow,
        ).status,
        VocabularyStatus.new_,
      );
    });

    test('increments reviewsCount', () {
      expect(
        review(reviewsCount: 5, rating: VocabularyRating.dontKnow).reviewsCount,
        6,
      );
    });

    test('nextReviewAt is UTC midnight + interval days', () {
      final result = review(rating: VocabularyRating.dontKnow);
      expect(result.nextReviewAt, DateTime.utc(2024, 6, 16));
      expect(result.nextReviewAt.hour, 0);
    });
  });

  group('calculateNextReview — rating 1', () {
    test('MIN interval for new items', () {
      expect(
        review(
          reviewsCount: 0,
          interval: 0,
          rating: VocabularyRating.know,
        ).interval,
        1,
      );
    });

    test('interval = round(interval * ease)', () {
      expect(
        review(
          reviewsCount: 1,
          interval: 2,
          easeFactor: 2.5,
          rating: VocabularyRating.know,
        ).interval,
        5,
      );
    });

    test('caps at MAX_INTERVAL', () {
      expect(
        review(
          reviewsCount: 10,
          interval: 300,
          easeFactor: 2.5,
          rating: VocabularyRating.know,
        ).interval,
        lessThanOrEqualTo(kMaxIntervalDays),
      );
    });

    test('learning when pre-count < 3', () {
      expect(
        review(reviewsCount: 0, rating: VocabularyRating.know).status,
        VocabularyStatus.learning,
      );
    });

    test('reviewing when pre-count >= 3', () {
      expect(
        review(reviewsCount: 3, rating: VocabularyRating.know).status,
        VocabularyStatus.reviewing,
      );
    });

    test('does not change ease', () {
      expect(
        review(easeFactor: 2.5, rating: VocabularyRating.know).easeFactor,
        2.5,
      );
    });
  });

  group('calculateNextReview — rating 2', () {
    test('MIN interval when interval is 0', () {
      expect(
        review(interval: 0, rating: VocabularyRating.knowWell).interval,
        1,
      );
    });

    test('interval uses increased ease * 1.5', () {
      // round(2 * 2.5 * 1.5) = 8
      expect(
        review(
          interval: 2,
          easeFactor: 2.5,
          reviewsCount: 1,
          rating: VocabularyRating.knowWell,
        ).interval,
        8,
      );
    });

    test('increases ease by 0.1 capped at MAX', () {
      expect(
        review(easeFactor: 2.4, rating: VocabularyRating.knowWell).easeFactor,
        closeTo(2.5, 1e-10),
      );
      expect(
        review(easeFactor: 2.5, rating: VocabularyRating.knowWell).easeFactor,
        kMaxEaseFactor,
      );
    });

    test('mastered when post-count >= 5', () {
      expect(
        review(reviewsCount: 4, rating: VocabularyRating.knowWell).status,
        VocabularyStatus.mastered,
      );
      expect(
        review(reviewsCount: 5, rating: VocabularyRating.knowWell).status,
        VocabularyStatus.mastered,
      );
    });

    test('reviewing before mastery', () {
      expect(
        review(reviewsCount: 2, rating: VocabularyRating.knowWell).status,
        VocabularyStatus.reviewing,
      );
    });
  });

  group('status transitions', () {
    test('new → learning after first successful review', () {
      expect(
        review(
          status: VocabularyStatus.new_,
          reviewsCount: 0,
          rating: VocabularyRating.know,
        ).status,
        VocabularyStatus.learning,
      );
    });

    test('rating 0 resets any status to new', () {
      for (final status in VocabularyStatus.values) {
        expect(
          review(
            status: status,
            reviewsCount: 10,
            rating: VocabularyRating.dontKnow,
          ).status,
          VocabularyStatus.new_,
        );
      }
    });
  });

  group('isVocabularyItemDue', () {
    test('due when nextReviewAt <= now and lastReviewedAt is null', () {
      expect(
        isVocabularyItemDue(
          nextReviewAt: fixedNow,
          lastReviewedAt: null,
          now: fixedNow,
        ),
        isTrue,
      );
    });

    test('not due when nextReviewAt > now', () {
      expect(
        isVocabularyItemDue(
          nextReviewAt: fixedNow.add(const Duration(hours: 1)),
          lastReviewedAt: null,
          now: fixedNow,
        ),
        isFalse,
      );
    });

    test('excludes corrupt nextReviewAt <= lastReviewedAt', () {
      final last = fixedNow.subtract(const Duration(days: 1));
      expect(
        isVocabularyItemDue(
          nextReviewAt: last,
          lastReviewedAt: last,
          now: fixedNow,
        ),
        isFalse,
      );
    });

    test('due when nextReviewAt > lastReviewedAt and <= now', () {
      expect(
        isVocabularyItemDue(
          nextReviewAt: fixedNow.subtract(const Duration(hours: 1)),
          lastReviewedAt: fixedNow.subtract(const Duration(days: 2)),
          now: fixedNow,
        ),
        isTrue,
      );
    });
  });

  group('newItemNextReviewAt', () {
    test('is now + 24 hours', () {
      expect(
        newItemNextReviewAt(fixedNow),
        fixedNow.add(const Duration(hours: 24)),
      );
    });
  });
}
