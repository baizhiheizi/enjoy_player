/// Copies a remote row into local Drift so it appears in the Library.
library;

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/media_registry.dart';
import 'package:enjoy_player/features/cloud/domain/remote_library_item.dart';
import 'package:enjoy_player/features/sync/data/sync_serializers.dart';

class CloudAddToLibrary {
  CloudAddToLibrary(this._db);

  final AppDatabase _db;

  Future<bool> isInLibrary(RemoteLibraryItem item) async {
    final registry = MediaRegistry(_db);
    if (item.isVideo) {
      return (await registry.getVideoById(item.id)) != null;
    }
    return (await registry.getAudioById(item.id)) != null;
  }

  /// Inserts metadata from the remote payload (`localUri` null; `mediaUrl` kept when set).
  Future<void> add(RemoteLibraryItem item) async {
    final registry = MediaRegistry(_db);
    if (item.isVideo) {
      await registry.upsertVideo(videoRowFromServerJson(item.rawJson));
      return;
    }
    await registry.upsertAudio(audioRowFromServerJson(item.rawJson));
  }
}
