/// Riverpod access to the [MediaRegistry] read/write seam (issue #765).
///
/// Callers that only read or write library rows cross this seam directly;
/// import/relink policy stays in `MediaLibraryRepository`. Manual provider —
/// same rationale as `library_media_provider.dart` (avoids riverpod_generator
/// for a one-line dependency pass-through).
///
/// Lifetime: a bare `Provider` in this repo's flutter_riverpod 2.x is
/// keep-alive (disposal is opt-in via `.autoDispose`, which manual providers
/// here use when they mean it). The registry holds no resources of its own,
/// so it lives for the container's lifetime like the generated
/// `@Riverpod(keepAlive: true)` `mediaLibraryRepositoryProvider` beside it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database_provider.dart';
import 'media_registry.dart';

final mediaRegistryProvider = Provider<MediaRegistry>((ref) {
  return MediaRegistry(ref.watch(appDatabaseProvider));
});
