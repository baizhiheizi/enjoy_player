/// Resolve a local filesystem thumbnail path when supported on this platform.
library;

import 'dart:io' show File, Platform;

File? localThumbnailFile(String? path) {
  if (path == null || path.isEmpty) return null;
  if (!(Platform.isWindows ||
      Platform.isLinux ||
      Platform.isMacOS ||
      Platform.isAndroid ||
      Platform.isIOS)) {
    return null;
  }
  final f = File(path);
  return f.existsSync() ? f : null;
}
