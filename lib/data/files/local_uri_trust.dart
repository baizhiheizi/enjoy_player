/// Cheap local-file trust checks for open (size + optional mtime).
library;

import 'dart:io';

/// Returns true when [localUri] exists and matches stored trust metadata.
///
/// Full content hashing is intentionally not performed here (see FR-004a).
Future<bool> localUriTrusted({
  required String? localUri,
  required int? storedSize,
  required int? storedMtimeMs,
}) async {
  if (localUri == null || localUri.isEmpty) return false;
  try {
    final file = File.fromUri(Uri.parse(localUri));
    if (!await file.exists()) return false;

    final stat = await file.stat();
    if (storedSize != null && stat.size != storedSize) return false;
    if (storedMtimeMs != null &&
        stat.modified.millisecondsSinceEpoch != storedMtimeMs) {
      return false;
    }
    return true;
  } on Object {
    return false;
  }
}
