/// Copies a remote row into local Drift so it appears in the Library.
library;

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/media_registry.dart';
import 'package:enjoy_player/features/cloud/domain/remote_library_item.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/sync/data/sync_serializers.dart';

class CloudAddToLibrary {
  CloudAddToLibrary(this._db);

  final AppDatabase _db;

  Future<bool> isInLibrary(RemoteLibraryItem item) {
    final registry = MediaRegistry(_db);
    return item.isVideo
        ? registry.existsVideoById(item.id)
        : registry.existsAudioById(item.id);
  }

  Stream<Set<String>> watchLibraryIds({required bool isVideo}) {
    final registry = MediaRegistry(_db);
    return registry.watchAllIds(isVideo ? MediaKind.video : MediaKind.audio);
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
