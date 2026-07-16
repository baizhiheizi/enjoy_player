/// Heuristics for linking vs copying local media into app storage.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// True when [absolutePath] is a durable filesystem path suitable for storing
/// as `localUri` without copying into app `media/`.
///
/// Rejects empty paths, missing files, and paths under OS temp/cache (typical
/// ephemeral picker caches on mobile). See research D1–D2.
Future<bool> canLinkExternally(String absolutePath) async {
  if (absolutePath.isEmpty) return false;
  if (!p.isAbsolute(absolutePath)) return false;

  final file = File(absolutePath);
  if (!await file.exists()) return false;

  final normalized = p.normalize(absolutePath);
  final ephemeralRoots = await _ephemeralRoots();
  for (final root in ephemeralRoots) {
    if (_isUnderOrEqual(root, normalized)) return false;
  }
  return true;
}

/// True when [pathOrFileUri] resolves under `{documents}/media/`.
Future<bool> isAppManagedMediaPath(String pathOrFileUri) async {
  if (pathOrFileUri.isEmpty) return false;
  try {
    final absolute = _absolutePathFrom(pathOrFileUri);
    if (absolute == null) return false;
    final docs = await getApplicationDocumentsDirectory();
    final mediaDir = p.normalize(p.join(docs.path, 'media'));
    return _isUnderOrEqual(mediaDir, p.normalize(absolute));
  } on Object {
    return false;
  }
}

/// App documents `media/` directory path (creates nothing).
Future<String> appManagedMediaDirectoryPath() async {
  final docs = await getApplicationDocumentsDirectory();
  return p.join(docs.path, 'media');
}

Future<List<String>> _ephemeralRoots() async {
  final roots = <String>[];
  try {
    roots.add(p.normalize((await getTemporaryDirectory()).path));
  } on Object {
    // Ignore — platform may not expose temp in some test doubles.
  }
  try {
    final cache = await getApplicationCacheDirectory();
    roots.add(p.normalize(cache.path));
  } on Object {
    // getApplicationCacheDirectory may be unimplemented on some platforms.
  }
  return roots;
}

String? _absolutePathFrom(String pathOrFileUri) {
  if (pathOrFileUri.startsWith('file:')) {
    return File.fromUri(Uri.parse(pathOrFileUri)).path;
  }
  return pathOrFileUri;
}

bool _isUnderOrEqual(String root, String candidate) {
  final r = p.normalize(root);
  final c = p.normalize(candidate);
  if (p.equals(r, c)) return true;
  return p.isWithin(r, c);
}
