/// Shared vocabulary filter pipeline — the single owner of the narrowing
/// semantics the word list and the Anki CSV export both apply.
library;

import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';

/// The narrowing inputs the vocabulary filter pipeline reads.
abstract interface class VocabularyFilterSpec {
  VocabularyStatus? get status;
  String? get language;
  String get query;
}

/// Apply [filters] to [items] (status ∩ language ∩ search contains).
///
/// The query is trimmed before matching, so a padded search term selects the
/// same rows in the word list and in the exported CSV.
List<VocabularyItem> filterVocabularyItems(
  List<VocabularyItem> items,
  VocabularyFilterSpec filters,
) {
  Iterable<VocabularyItem> result = items;
  final status = filters.status;
  if (status != null) {
    result = result.where((i) => i.status == status);
  }
  final language = filters.language;
  if (language != null) {
    result = result.where((i) => i.language == language);
  }
  final q = filters.query.trim().toLowerCase();
  if (q.isNotEmpty) {
    result = result.where(
      (i) =>
          i.word.toLowerCase().contains(q) ||
          i.language.toLowerCase().contains(q),
    );
  }
  return result.toList();
}
