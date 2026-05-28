/// Resolves Dexie-style `Audio` / `Video` target type for a library media id.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/media_target_resolver.dart';

part 'dexie_target_type_provider.g.dart';

@riverpod
Future<String?> dexieTargetTypeForMedia(Ref ref, String mediaId) {
  final db = ref.watch(appDatabaseProvider);
  return dexieTargetTypeForId(db, mediaId);
}
