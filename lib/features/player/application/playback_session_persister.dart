/// Debounced persistence of playback position + echo fields to [EchoSessionDao].
library;

import 'dart:async';

import 'package:drift/drift.dart';
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
    required String dexieTargetType,
    required PlaybackSession session,
    required EchoState echo,
  }) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      final db = _ref.read(appDatabaseProvider);
      final existing = await db.echoSessionDao.getOrCreateLatestForTarget(
        dexieTargetType,
        mediaId,
      );
      final now = DateTime.now();
      await db.echoSessionDao.upsert(
        existing.copyWith(
          currentTimeMs: (session.currentTimeSeconds * 1000).round(),
          currentSegmentIndex: session.currentSegmentIndex,
          echoActive: echo.active,
          echoStartLine: echo.startLineIndex,
          echoEndLine: echo.endLineIndex,
          echoStartMs: echo.active
              ? Value((echo.startTimeSeconds * 1000).round())
              : const Value(null),
          echoEndMs: echo.active
              ? Value((echo.endTimeSeconds * 1000).round())
              : const Value(null),
          lastActiveAt: now,
          updatedAt: now,
          transcriptId: const Value.absent(),
          secondaryTranscriptId: const Value.absent(),
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
