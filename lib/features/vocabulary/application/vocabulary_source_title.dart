/// Resolve vocabulary context sourceId → human-readable media title.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/library/application/library_repository_provider.dart';

/// Looks up the library media title for [sourceId].
///
/// Returns `null` when the media is missing or untitled so the UI can fall
/// back to a short unknown-source label (never a raw UUID dump).
final vocabularySourceTitleProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, sourceId) async {
      final id = sourceId.trim();
      if (id.isEmpty) return null;
      final media = await ref.watch(mediaLibraryRepositoryProvider).getById(id);
      final title = media?.title.trim();
      if (title == null || title.isEmpty) return null;
      return title;
    });
