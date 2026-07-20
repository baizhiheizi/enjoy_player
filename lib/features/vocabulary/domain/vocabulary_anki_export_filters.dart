/// Filters for Anki CSV export (web ExportAnkiDialog parity).
library;

import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';

/// Search + status + language narrowing before Anki CSV generation.
final class VocabularyAnkiExportFilters {
  const VocabularyAnkiExportFilters({
    this.query = '',
    this.status,
    this.language,
  });

  final String query;
  final VocabularyStatus? status;
  final String? language;

  VocabularyAnkiExportFilters copyWith({
    String? query,
    VocabularyStatus? status,
    String? language,
    bool clearStatus = false,
    bool clearLanguage = false,
  }) {
    return VocabularyAnkiExportFilters(
      query: query ?? this.query,
      status: clearStatus ? null : (status ?? this.status),
      language: clearLanguage ? null : (language ?? this.language),
    );
  }
}

/// Apply [filters] to [items] (status ∩ language ∩ search contains).
List<VocabularyItem> filterVocabularyItemsForAnkiExport(
  List<VocabularyItem> items,
  VocabularyAnkiExportFilters filters,
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
