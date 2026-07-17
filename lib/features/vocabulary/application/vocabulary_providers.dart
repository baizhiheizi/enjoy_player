/// Riverpod access to [VocabularyRepository].
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/vocabulary/data/vocabulary_repository.dart';

part 'vocabulary_providers.g.dart';

@Riverpod(keepAlive: true)
VocabularyRepository vocabularyRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return VocabularyRepository(db);
}
