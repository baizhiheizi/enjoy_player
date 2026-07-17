/// Riverpod access to [VocabularyRepository] and derived vocabulary UI state.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/vocabulary/data/vocabulary_repository.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_stats.dart';

part 'vocabulary_providers.g.dart';

@Riverpod(keepAlive: true)
VocabularyRepository vocabularyRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return VocabularyRepository(db);
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
