/// Looks up [VideoRow] for a media id (video items only — audio returns null).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/media_registry.dart';

final videoRowForMediaProvider = FutureProvider.family<VideoRow?, String>((
  ref,
  mediaId,
) async {
  final db = ref.read(appDatabaseProvider);
  return MediaRegistry(db).getVideoById(mediaId);
});
