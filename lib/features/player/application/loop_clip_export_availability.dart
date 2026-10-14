/// Whether the ⋯ More menu's "Export the loop as a clip…" entry is enabled:
/// an Echo loop must be active and the open media must resolve to a direct
/// source FFmpeg can read (a local file or a direct media URL — a YouTube
/// row has none and stays disabled).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/media_target_resolver.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';

final loopClipExportAvailableProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, mediaId) async {
      final echoActive = ref.watch(
        echoModeProvider.select((echo) => echo.active),
      );
      if (!echoActive) return false;
      final db = ref.watch(appDatabaseProvider);
      return await resolvePlayableSourceUri(db, mediaId) != null;
    });
