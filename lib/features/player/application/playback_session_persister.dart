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

  /// Schedules a write using [session] for timing fields and **fresh** echo state
  /// at flush time (avoids echo segment reverting in DB when debounce captures a
  /// snapshot from before [EchoMode.activate], e.g. after tapping another cue).
  void schedule({
    required String mediaId,
    required String dexieTargetType,
    required PlaybackSession session,
  }) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      _debounce = null;
      await _flush(mediaId: mediaId, dexieTargetType: dexieTargetType, session: session);
    });
  }

  /// Flushes any pending debounced write synchronously (best-effort).
  ///
  /// [PlayerController.clear] calls this before [cancel] so swipe-to-dismiss
  /// does not lose the last 450 ms of position updates.
  Future<void> flush({
    required String mediaId,
    required String dexieTargetType,
    required PlaybackSession session,
  }) async {
    final timer = _debounce;
    if (timer == null) return;
    timer.cancel();
    _debounce = null;
    await _flush(mediaId: mediaId, dexieTargetType: dexieTargetType, session: session);
  }

  Future<void> _flush({
    required String mediaId,
    required String dexieTargetType,
    required PlaybackSession session,
  }) async {
    final echo = _ref.read(echoModeProvider);
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
  }

  void cancel() {
    _debounce?.cancel();
    _debounce = null;
  }

  void dispose() => cancel();
}

final playbackSessionPersisterProvider = Provider<PlaybackSessionPersister>((
  ref,
) {
  final p = PlaybackSessionPersister(ref);
  ref.onDispose(p.dispose);
  return p;
});
