/// Derived vocabulary book stats for the P1 stats strip.
library;

import 'vocabulary_models.dart';
import 'vocabulary_srs.dart';

/// Aggregates over a snapshot of [VocabularyItem]s at [now].
final class VocabularyStats {
  const VocabularyStats({
    required this.total,
    required this.due,
    required this.newCount,
    required this.learningCount,
    required this.reviewingCount,
    required this.masteredCount,
  });

  final int total;
  final int due;
  final int newCount;
  final int learningCount;
  final int reviewingCount;
  final int masteredCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabularyStats &&
          total == other.total &&
          due == other.due &&
          newCount == other.newCount &&
          learningCount == other.learningCount &&
          reviewingCount == other.reviewingCount &&
          masteredCount == other.masteredCount;

  @override
  int get hashCode => Object.hash(
    total,
    due,
    newCount,
    learningCount,
    reviewingCount,
    masteredCount,
  );

  @override
  String toString() =>
      'VocabularyStats(total: $total, due: $due, new: $newCount, '
      'learning: $learningCount, reviewing: $reviewingCount, '
      'mastered: $masteredCount)';
}

/// Compute [VocabularyStats] from [items] using the foundation due predicate.
VocabularyStats computeVocabularyStats(
  List<VocabularyItem> items, {
  required DateTime now,
}) {
  var due = 0;
  var newCount = 0;
  var learningCount = 0;
  var reviewingCount = 0;
  var masteredCount = 0;

  for (final item in items) {
    if (isVocabularyItemDue(
      nextReviewAt: item.nextReviewAt,
      lastReviewedAt: item.lastReviewedAt,
      now: now,
    )) {
      due++;
    }
    switch (item.status) {
      case VocabularyStatus.new_:
        newCount++;
      case VocabularyStatus.learning:
        learningCount++;
      case VocabularyStatus.reviewing:
        reviewingCount++;
      case VocabularyStatus.mastered:
        masteredCount++;
    }
  }

  return VocabularyStats(
    total: items.length,
    due: due,
    newCount: newCount,
    learningCount: learningCount,
    reviewingCount: reviewingCount,
    masteredCount: masteredCount,
  );
}
