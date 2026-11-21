/// Due count + first words for the Review tab's due card.
library;

import 'vocabulary_models.dart';
import 'vocabulary_srs.dart';

/// How many due words the due card previews before the overflow chip.
const int kVocabularyDuePreviewWords = 5;

/// What the due card needs from the due queue: the total count and the
/// first [kVocabularyDuePreviewWords] words.
final class VocabularyDuePreview {
  const VocabularyDuePreview({required this.count, required this.firstWords});

  /// Number of due items — same `isVocabularyItemDue` predicate and item
  /// order as the `VocabularyReviewMode.due` session queue.
  final int count;

  /// First `min(count, [kVocabularyDuePreviewWords])` due words, unmodifiable.
  final List<String> firstWords;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabularyDuePreview &&
          count == other.count &&
          _wordsEqual(firstWords, other.firstWords);

  @override
  int get hashCode => Object.hash(count, Object.hashAll(firstWords));

  @override
  String toString() =>
      'VocabularyDuePreview(count: $count, firstWords: $firstWords)';
}

/// Single pass over [items] — no full due-queue or word-list allocation.
VocabularyDuePreview buildVocabularyDuePreview({
  required List<VocabularyItem> items,
  required DateTime now,
  int maxWords = kVocabularyDuePreviewWords,
}) {
  final words = <String>[];
  var count = 0;
  for (final item in items) {
    if (!isVocabularyItemDue(
      nextReviewAt: item.nextReviewAt,
      lastReviewedAt: item.lastReviewedAt,
      now: now,
    )) {
      continue;
    }
    count++;
    if (words.length < maxWords) words.add(item.word);
  }
  return VocabularyDuePreview(
    count: count,
    firstWords: words.isEmpty ? const <String>[] : List.unmodifiable(words),
  );
}

bool _wordsEqual(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
