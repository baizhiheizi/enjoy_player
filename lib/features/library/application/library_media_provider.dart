/// Stream of all library media (manual provider — avoids riverpod_generator + Drift edge case).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/library/domain/media.dart';

import 'library_repository_provider.dart';
import 'library_search_provider.dart';

final libraryMediaProvider = StreamProvider<List<Media>>((ref) {
  return ref.watch(mediaLibraryRepositoryProvider).watchAll();
});

/// Up to 12 most recently updated items for [HomeScreen] (pre-sorted).
final libraryHomeRecentsProvider = StreamProvider<List<Media>>((ref) {
  const recentLimit = 12;
  final repo = ref.watch(mediaLibraryRepositoryProvider);
  return repo.watchAll().map((items) {
    final sorted = [...items]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.take(recentLimit).toList();
  });
});

/// Pre-filtered + title-sorted audio/video lists for [LibraryScreen].
final libraryFilteredListsProvider =
    StreamProvider<({List<Media> audio, List<Media> video})>((ref) {
      final repo = ref.watch(mediaLibraryRepositoryProvider);
      final query = ref.watch(librarySearchProvider);
      return repo.watchAll().map((items) {
        final filtered = _filterMediaByQuery(items, query);
        final audioItems =
            filtered.where((m) => m.kind == MediaKind.audio).toList()
              ..sort((a, b) => a.title.compareTo(b.title));
        final videoItems =
            filtered.where((m) => m.kind == MediaKind.video).toList()
              ..sort((a, b) => a.title.compareTo(b.title));
        return (audio: audioItems, video: videoItems);
      });
    });

List<Media> _filterMediaByQuery(List<Media> items, String query) {
  if (query.isEmpty) return items;
  final lower = query.toLowerCase();
  return items.where((m) => m.title.toLowerCase().contains(lower)).toList();
}
