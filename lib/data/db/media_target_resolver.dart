/// Resolve weapp-style `TargetType` from a library item id (video vs audio row).
library;

import 'dart:io';

import 'app_database.dart';

Future<String?> dexieTargetTypeForId(AppDatabase db, String id) async {
  if (await db.videoDao.getById(id) != null) return 'Video';
  if (await db.audioDao.getById(id) != null) return 'Audio';
  return null;
}

bool _localUriPlayable(String? uri) {
  if (uri == null || uri.isEmpty) return false;
  try {
    return File.fromUri(Uri.parse(uri)).existsSync();
  } on Object {
    return false;
  }
}

/// Same resolution as [PlayerController.openMedia] — for subtitle extraction, etc.
Future<String?> resolvePlayableSourceUri(AppDatabase db, String mediaId) async {
  final video = await db.videoDao.getById(mediaId);
  final audio = video == null ? await db.audioDao.getById(mediaId) : null;
  if (video == null && audio == null) return null;

  final netUri = video?.mediaUrl ?? audio?.mediaUrl;
  if (netUri != null && netUri.isNotEmpty) {
    return netUri;
  }
  final local = video?.localUri ?? audio?.localUri;
  if (_localUriPlayable(local)) {
    return local;
  }
  return null;
}
