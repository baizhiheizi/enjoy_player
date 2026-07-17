/// Vocabulary SRS (SM-2 variant) — port of web `vocabulary-srs.ts`.
library;

import 'vocabulary_models.dart';

const double kMinEaseFactor = 1.3;
const double kMaxEaseFactor = 2.5;
const double kDefaultEaseFactor = 2.5;
const int kMinIntervalDays = 1;
const int kMaxIntervalDays = 365;

/// Next review for a freshly added item: [now] + 24 hours.
DateTime newItemNextReviewAt(DateTime now) =>
    now.add(const Duration(hours: 24));

/// Whether an item is due for review (web `getDueVocabularyItems` filter).
bool isVocabularyItemDue({
  required DateTime nextReviewAt,
  required DateTime? lastReviewedAt,
  required DateTime now,
}) =>
    !nextReviewAt.isAfter(now) &&
    (lastReviewedAt == null || nextReviewAt.isAfter(lastReviewedAt));

/// Calculate next review fields from current SRS state and [rating].
///
/// Port of web `calculateNextReview`. [now] is injectable for tests.
ReviewUpdate calculateNextReview({
  required double easeFactor,
  required int interval,
  required int reviewsCount,
  required VocabularyStatus status,
  required VocabularyRating rating,
  required DateTime now,
}) {
  final lastReviewedAt = now;
  final currentEaseFactor = easeFactor;
  final currentInterval = interval;
  final currentReviewCount = reviewsCount;

  var newEaseFactor = currentEaseFactor;
  var newInterval = currentInterval;
  var newStatus = status;
  final newReviewCount = currentReviewCount + 1;

  switch (rating) {
    case VocabularyRating.dontKnow:
      newEaseFactor = currentEaseFactor - 0.15;
      if (newEaseFactor < kMinEaseFactor) newEaseFactor = kMinEaseFactor;
      newInterval = kMinIntervalDays;
      newStatus = VocabularyStatus.new_;
    case VocabularyRating.know:
      newInterval = currentReviewCount == 0 || currentInterval == 0
          ? kMinIntervalDays
          : _clampInterval((currentInterval * currentEaseFactor).round());
      if (newInterval < kMinIntervalDays) newInterval = kMinIntervalDays;
      newStatus = currentReviewCount < 3
          ? VocabularyStatus.learning
          : VocabularyStatus.reviewing;
    case VocabularyRating.knowWell:
      newEaseFactor = currentEaseFactor + 0.1;
      if (newEaseFactor > kMaxEaseFactor) newEaseFactor = kMaxEaseFactor;
      newInterval = currentInterval == 0
          ? kMinIntervalDays
          : _clampInterval((currentInterval * newEaseFactor * 1.5).round());
      if (newInterval < kMinIntervalDays) newInterval = kMinIntervalDays;
      newStatus = newReviewCount >= 5
          ? VocabularyStatus.mastered
          : VocabularyStatus.reviewing;
  }

  final nextReviewAt = _utcMidnightPlusDays(now, newInterval);

  return ReviewUpdate(
    status: newStatus,
    easeFactor: newEaseFactor,
    interval: newInterval,
    nextReviewAt: nextReviewAt,
    reviewsCount: newReviewCount,
    lastReviewedAt: lastReviewedAt,
  );
}

int _clampInterval(int days) {
  if (days < kMinIntervalDays) return kMinIntervalDays;
  if (days > kMaxIntervalDays) return kMaxIntervalDays;
  return days;
}

/// UTC midnight of calendar day `(now UTC + [days])`.
DateTime _utcMidnightPlusDays(DateTime now, int days) {
  final utc = now.toUtc();
  final target = DateTime.utc(utc.year, utc.month, utc.day + days);
  return target;
}
