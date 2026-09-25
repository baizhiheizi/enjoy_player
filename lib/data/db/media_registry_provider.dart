/// Riverpod access to the [MediaRegistry] read/write seam (issue #765).
///
/// Callers that only read or write library rows cross this seam directly;
/// import/relink policy stays in `MediaLibraryRepository`. Manual provider —
/// same rationale as `library_media_provider.dart` (avoids riverpod_generator
/// for a one-line dependency pass-through); keepAlive like the repository
/// provider it sits beside.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database_provider.dart';
import 'media_registry.dart';

final mediaRegistryProvider = Provider<MediaRegistry>((ref) {
  return MediaRegistry(ref.watch(appDatabaseProvider));
});
