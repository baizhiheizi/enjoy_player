/// Library screen source mode (local Drift vs remote cloud index).
library;

/// Where the unified Library screen loads media from.
enum LibrarySource {
  local,
  cloud,
}

/// Parses `source` from a library route [uri]. Defaults to [LibrarySource.local].
LibrarySource librarySourceFromUri(Uri uri) {
  final raw = uri.queryParameters['source']?.trim().toLowerCase();
  if (raw == 'cloud') return LibrarySource.cloud;
  return LibrarySource.local;
}

/// Shell route for [source] (local omits the query param).
String libraryRouteForSource(LibrarySource source) {
  return switch (source) {
    LibrarySource.local => '/library',
    LibrarySource.cloud => '/library?source=cloud',
  };
}
