/// Stream of all library media (manual provider — avoids riverpod_generator + Drift edge case).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/library/domain/media.dart';

import 'library_repository_provider.dart';

final libraryMediaProvider = StreamProvider<List<Media>>((ref) {
  return ref.watch(mediaLibraryRepositoryProvider).watchAll();
});
