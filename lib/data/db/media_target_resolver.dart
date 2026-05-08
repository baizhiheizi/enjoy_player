/// Resolve weapp-style `TargetType` from a library item id (video vs audio row).
library;

import 'app_database.dart';

Future<String?> dexieTargetTypeForId(AppDatabase db, String id) async {
  if (await db.videoDao.getById(id) != null) return 'Video';
  if (await db.audioDao.getById(id) != null) return 'Audio';
  return null;
}
