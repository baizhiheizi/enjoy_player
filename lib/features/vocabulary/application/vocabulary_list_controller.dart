/// Filter / search state for the Vocabulary All Words tab.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';

const Duration kVocabularySearchDebounce = Duration(milliseconds: 150);

/// Status + language filters and debounced search query for All Words.
final class VocabularyListFilters {
  const VocabularyListFilters({this.status, this.language, this.query = ''});

  final VocabularyStatus? status;
  final String? language;
  final String query;

  VocabularyListFilters copyWith({
    VocabularyStatus? status,
    String? language,
    String? query,
    bool clearStatus = false,
    bool clearLanguage = false,
  }) {
    return VocabularyListFilters(
      status: clearStatus ? null : (status ?? this.status),
      language: clearLanguage ? null : (language ?? this.language),
      query: query ?? this.query,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabularyListFilters &&
          status == other.status &&
          language == other.language &&
          query == other.query;

  @override
  int get hashCode => Object.hash(status, language, query);
}

final vocabularyListFiltersProvider =
    NotifierProvider<VocabularyListFiltersNotifier, VocabularyListFilters>(
      VocabularyListFiltersNotifier.new,
    );

class VocabularyListFiltersNotifier extends Notifier<VocabularyListFilters> {
  Timer? _debounce;
  String _pending = '';

  @override
  VocabularyListFilters build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _debounce = null;
    });
    return const VocabularyListFilters();
  }

  void setStatus(VocabularyStatus? status) {
    state = status == null
        ? state.copyWith(clearStatus: true)
        : state.copyWith(status: status);
  }

  void setLanguage(String? language) {
    state = language == null
        ? state.copyWith(clearLanguage: true)
        : state.copyWith(language: language);
  }

  void setQuery(String value) {
    _pending = value;
    _debounce?.cancel();
    _debounce = Timer(kVocabularySearchDebounce, () {
      state = state.copyWith(query: _pending.trim());
    });
  }

  void clearQuery() {
    _debounce?.cancel();
    _debounce = null;
    _pending = '';
    state = state.copyWith(query: '');
  }
}

/// Apply [filters] to [items] (status ∩ language ∩ search contains).
List<VocabularyItem> filterVocabularyItems(
  List<VocabularyItem> items,
  VocabularyListFilters filters,
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
  final q = filters.query.toLowerCase();
  if (q.isNotEmpty) {
    result = result.where(
      (i) =>
          i.word.toLowerCase().contains(q) ||
          i.language.toLowerCase().contains(q),
    );
  }
  return result.toList();
}
