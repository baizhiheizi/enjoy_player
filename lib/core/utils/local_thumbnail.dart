/// Resolve a local filesystem thumbnail path.
library;

import 'dart:io' show File;

File? localThumbnailFile(String? path) {
  if (path == null || path.isEmpty) return null;
  final f = File(path);
  return f.existsSync() ? f : null;
}
