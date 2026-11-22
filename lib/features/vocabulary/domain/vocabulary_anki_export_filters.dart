/// Filters for Anki CSV export (web ExportAnkiDialog parity).
library;

import 'package:enjoy_player/features/vocabulary/domain/vocabulary_filters.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';

/// Search + status + language narrowing before Anki CSV generation.
final class VocabularyAnkiExportFilters implements VocabularyFilterSpec {
  const VocabularyAnkiExportFilters({
    this.query = '',
    this.status,
    this.language,
  });

  @override
  final String query;

  @override
  final VocabularyStatus? status;

  @override
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
