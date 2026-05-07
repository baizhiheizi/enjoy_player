/// Riverpod access to [MediaLibraryRepository].
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/db/app_database_provider.dart';
import '../../../data/files/file_storage.dart';
import '../data/library_repository.dart';

part 'library_repository_provider.g.dart';

@Riverpod(keepAlive: true)
MediaLibraryRepository mediaLibraryRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return MediaLibraryRepository(db, FileStorage());
}
