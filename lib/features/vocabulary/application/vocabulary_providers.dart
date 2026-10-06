/// Riverpod access to [VocabularyRepository] and derived vocabulary UI state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_list_controller.dart';
import 'package:enjoy_player/features/vocabulary/data/vocabulary_repository.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_stats.dart';

part 'vocabulary_providers.g.dart';

@Riverpod(keepAlive: true)
VocabularyRepository vocabularyRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return VocabularyRepository(db, enqueueSync: ref.read(syncEnqueueProvider));
}

/// Live list of all vocabulary items (updates after add/rate/delete).
@riverpod
Stream<List<VocabularyItem>> vocabularyItems(Ref ref) {
  return ref.watch(vocabularyRepositoryProvider).watchAll();
}

/// Aggregated stats for the Vocabulary stats strip.
@riverpod
VocabularyStats vocabularyStats(Ref ref) {
  final items = ref.watch(vocabularyItemsProvider).valueOrNull ?? const [];
  return computeVocabularyStats(items, now: DateTime.now());
}

/// Distinct, sorted languages across all items for the word-list filter
/// menu (issue #827 C2). Re-runs on every `vocabularyItemsProvider`
/// emission — each emission carries a fresh list — and the result is
/// cached between emissions, so word-list rebuilds that are unrelated to
/// the items (filter toggles, keystroke setStates) stop re-deriving it.
@riverpod
List<String> vocabularyListLanguages(Ref ref) {
  final items =
      ref.watch(vocabularyItemsProvider).valueOrNull ??
      const <VocabularyItem>[];
  return items.map((i) => i.language).toSet().toList()..sort();
}

/// [filterVocabularyItems] keyed on `(items, filters)` (issue #827 C2) —
/// the word list watches this instead of re-filtering inside `build` on
/// every rebuild. Re-runs when the items stream emits or the filters
/// change; cached otherwise.
@riverpod
List<VocabularyItem> vocabularyVisibleItems(Ref ref) {
  final items =
      ref.watch(vocabularyItemsProvider).valueOrNull ??
      const <VocabularyItem>[];
  return filterVocabularyItems(items, ref.watch(vocabularyListFiltersProvider));
}

/// First saved context sentence of a word (the word list's second line).
final vocabularyFirstContextProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, itemId) async {
      final contexts = await ref
          .watch(vocabularyRepositoryProvider)
          .getContextsForItem(itemId);
      return contexts.isEmpty ? null : contexts.first.text;
    });
