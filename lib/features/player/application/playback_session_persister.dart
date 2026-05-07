/// Debounced persistence of playback position + echo fields to [SessionDao].
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/app_database_provider.dart';
import '../domain/playback_session.dart';
import 'echo_mode_provider.dart';

class PlaybackSessionPersister {
  PlaybackSessionPersister(this._ref);

  final Ref _ref;
  Timer? _debounce;

  /// Schedules a write using the latest [session] + [echo] snapshot.
  void schedule({
    required String mediaId,
    required PlaybackSession session,
    required EchoState echo,
  }) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      final db = _ref.read(appDatabaseProvider);
      final existing = await db.sessionDao.getForMedia(mediaId);
      await db.sessionDao.upsert(
        PlaybackSessionRow(
          mediaId: mediaId,
          positionMs: (session.currentTimeSeconds * 1000).round(),
          currentSegmentIndex: session.currentSegmentIndex,
          echoActive: echo.active,
          echoStartLine: echo.startLineIndex,
          echoEndLine: echo.endLineIndex,
          echoStartMs: (echo.startTimeSeconds * 1000).round(),
          echoEndMs: (echo.endTimeSeconds * 1000).round(),
          primaryTranscriptId: existing?.primaryTranscriptId,
          secondaryTranscriptId: existing?.secondaryTranscriptId,
          lastActiveAt: DateTime.now(),
        ),
      );
    });
  }

  void cancel() {
    _debounce?.cancel();
    _debounce = null;
  }

  void dispose() => cancel();
}

final playbackSessionPersisterProvider = Provider<PlaybackSessionPersister>((ref) {
  final p = PlaybackSessionPersister(ref);
  ref.onDispose(p.dispose);
  return p;
});
