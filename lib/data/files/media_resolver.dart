/// Resolve media kind from filename extension.
library;

import 'package:path/path.dart' as p;

bool isVideoFileName(String fileName) {
  switch (p.extension(fileName).toLowerCase()) {
    case '.mp4':
    case '.webm':
    case '.mkv':
    case '.mov':
    case '.avi':
    case '.m4v':
    case '.ogv':
      return true;
    default:
      return false;
  }
}
