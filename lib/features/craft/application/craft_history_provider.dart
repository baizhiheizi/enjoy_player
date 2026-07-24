/// Craft history: `provider = 'craft'` media items, newest-edited first.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/library/application/library_repository_provider.dart';
import 'package:enjoy_player/features/library/domain/media.dart';

/// Streams every Crafted library item still tagged as Craft history,
/// sorted by [Media.updatedAt] descending. Removing a history record
/// clears Craft provenance (`provider` → `user`) so the item leaves this
/// list while the audio file stays in the library.
final craftHistoryProvider = StreamProvider<List<Media>>((ref) {
  return ref.watch(mediaLibraryRepositoryProvider).watchAll().map((items) {
    final craft = items.where((m) => m.provider == 'craft').toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return craft;
  });
});
