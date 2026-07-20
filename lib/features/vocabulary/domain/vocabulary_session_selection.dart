/// Review session queue selection (modes + Fisher–Yates).
library;

import 'dart:math';

import 'vocabulary_models.dart';
import 'vocabulary_srs.dart';

/// How to build the flashcard queue before a review session.
enum VocabularyReviewMode { due, all, byStatus, byLanguage, random }

/// Ephemeral inputs to [buildVocabularySessionQueue] (not persisted).
final class ReviewSelectionOptions {
  const ReviewSelectionOptions({
    required this.mode,
    this.status,
    this.language,
    this.randomCount = 20,
  });

  final VocabularyReviewMode mode;

  /// Required when [mode] is [VocabularyReviewMode.byStatus].
  final VocabularyStatus? status;

  /// Source language (BCP-47) when [mode] is [VocabularyReviewMode.byLanguage].
  final String? language;

  /// Cap for [VocabularyReviewMode.random] (default 20).
  final int randomCount;
}

/// Build an ordered session queue from [items] and [options].
///
/// Returns an empty list when nothing matches (caller shows a message).
/// Random mode shuffles a copy via Fisher–Yates using injectable [random].
List<VocabularyItem> buildVocabularySessionQueue({
  required List<VocabularyItem> items,
  required ReviewSelectionOptions options,
  required DateTime now,
  Random? random,
}) {
  switch (options.mode) {
    case VocabularyReviewMode.due:
      return items
          .where(
            (item) => isVocabularyItemDue(
              nextReviewAt: item.nextReviewAt,
              lastReviewedAt: item.lastReviewedAt,
              now: now,
            ),
          )
          .toList(growable: false);
    case VocabularyReviewMode.all:
      return List<VocabularyItem>.of(items, growable: false);
    case VocabularyReviewMode.byStatus:
      final status = options.status;
      if (status == null) return const [];
      return items
          .where((item) => item.status == status)
          .toList(growable: false);
    case VocabularyReviewMode.byLanguage:
      final language = options.language;
      if (language == null) return const [];
      return items
          .where((item) => item.language == language)
          .toList(growable: false);
    case VocabularyReviewMode.random:
      if (items.isEmpty) return const [];
      final copy = List<VocabularyItem>.of(items);
      _fisherYatesShuffle(copy, random ?? Random());
      final n = options.randomCount < copy.length
          ? options.randomCount
          : copy.length;
      if (n <= 0) return const [];
      return copy.sublist(0, n);
  }
}

void _fisherYatesShuffle(List<VocabularyItem> list, Random random) {
  for (var i = list.length - 1; i > 0; i--) {
    final j = random.nextInt(i + 1);
    final tmp = list[i];
    list[i] = list[j];
    list[j] = tmp;
  }
}
