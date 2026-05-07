/// Owns [PlaybackSession] state and orchestrates [PlayerEngine] + side services.
library;

import 'dart:async';
import 'dart:io';

import 'package:media_kit_video/media_kit_video.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/app_database_provider.dart';
import '../domain/echo_window.dart';
import '../domain/playback_session.dart';
import 'echo_mode_provider.dart';
import 'embedded_track_sync.dart';
import 'playback_session_persister.dart';
import 'player_engine.dart';
import 'player_engine_provider.dart';
import 'player_preferences_provider.dart';

part 'player_controller.g.dart';

@Riverpod(keepAlive: true)
class PlayerController extends _$PlayerController {
  VideoController? _videoController;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  /// Incremented on each [openMedia] call; stale async work bails out.
  int _openGeneration = 0;

  PlayerEngine get engine => ref.read(playerEngineProvider);

  /// Bound to [engine.player]; created once (ADR-0003).
  VideoController get videoController {
    final e = engine;
    return _videoController ??= VideoController(
      e.player,
      configuration:
          Platform.isWindows
              ? const VideoControllerConfiguration(width: 1920, height: 1080)
              : const VideoControllerConfiguration(),
    );
  }

  @override
  PlaybackSession? build() {
    ref.watch(playerEngineProvider);

    ref.onDispose(() async {
      ref.read(playbackSessionPersisterProvider).cancel();
      await ref.read(embeddedTrackSyncProvider).cancel();
      await _positionSub?.cancel();
      await _durationSub?.cancel();
      _positionSub = null;
      _durationSub = null;
    });
    return null;
  }

  Future<void> openMedia(String mediaId) async {
    final gen = ++_openGeneration;

    final db = ref.read(appDatabaseProvider);
    final row = await db.mediaDao.getById(mediaId);
    if (row == null) return;

    // Bind video output before first decode on Windows (see media_kit_video notes).
    // Audio-only paths skip this so unit tests and headless runs avoid native libmpv.
    if (Platform.isWindows && row.kind == 'video') {
      videoController;
    }

    await _positionSub?.cancel();
    await _durationSub?.cancel();
    _positionSub = null;
    _durationSub = null;

    await engine.openUri(row.sourceUri);
    if (gen != _openGeneration) return;

    unawaited(
      ref.read(embeddedTrackSyncProvider).startForMedia(
        mediaId: mediaId,
        sourceUri: row.sourceUri,
      ),
    );

    await ref.read(playerPreferencesCtrlProvider.notifier).applyCurrentToEngine();
    if (gen != _openGeneration) return;

    final persisted = await db.sessionDao.getForMedia(mediaId);
    final posMs = persisted?.positionMs ?? 0;
    if (posMs > 0) {
      await engine.seek(Duration(milliseconds: posMs));
    }
    if (gen != _openGeneration) return;

    if (persisted != null && persisted.echoActive) {
      ref
          .read(echoModeProvider.notifier)
          .restoreFromSession(
            startLine: persisted.echoStartLine,
            endLine: persisted.echoEndLine,
            echoStartMs: persisted.echoStartMs,
            echoEndMs: persisted.echoEndMs,
          );
    } else {
      ref.read(echoModeProvider.notifier).deactivate();
    }

    final now = DateTime.now();
    state = PlaybackSession(
      mediaId: row.id,
      mediaType: row.kind,
      mediaTitle: row.title,
      thumbnailUrl: row.thumbnailPath,
      durationSeconds:
          row.durationMs > 0 ? row.durationMs / 1000.0 : posMs / 1000.0,
      currentTimeSeconds: posMs / 1000.0,
      currentSegmentIndex: persisted?.currentSegmentIndex ?? -1,
      language: row.language,
      startedAt: now,
      lastActiveAt: now,
    );

    if (gen != _openGeneration) return;
    _subscribeStreams(mediaId, row, gen);
  }

  void _subscribeStreams(String mediaId, MediaRow row, int gen) {
    _positionSub = engine.position.listen((pos) {
      if (gen != _openGeneration) return;
      final seconds = pos.inMilliseconds / 1000.0;
      unawaited(_applyEcho(seconds));
      state = state?.copyWith(
        currentTimeSeconds: seconds,
        lastActiveAt: DateTime.now(),
      );
      final s = state;
      if (s != null) {
        ref.read(playbackSessionPersisterProvider).schedule(
          mediaId: mediaId,
          session: s,
          echo: ref.read(echoModeProvider),
        );
      }
    });

    _durationSub = engine.duration.listen((d) async {
      if (gen != _openGeneration) return;
      if (d <= Duration.zero) return;
      final ms = d.inMilliseconds;
      state = state?.copyWith(durationSeconds: ms / 1000.0);
      final db = ref.read(appDatabaseProvider);
      if (row.durationMs == 0) {
        await db.mediaDao.insertRow(
          row.copyWith(durationMs: ms, updatedAt: DateTime.now()),
        );
      }
    });
  }

  Future<void> _applyEcho(double positionSeconds) async {
    final echo = ref.read(echoModeProvider);
    if (!echo.active) return;
    final dur = state?.durationSeconds;
    final window = normalizeEchoWindow((
      active: true,
      startTimeSeconds: echo.startTimeSeconds,
      endTimeSeconds: echo.endTimeSeconds,
      durationSeconds: dur != null && dur > 0 ? dur : null,
    ));
    if (window == null) return;
    final decision = decideEchoPlaybackTime(positionSeconds, window);
    switch (decision) {
      case EchoOk():
        return;
      case EchoClamp(:final timeSeconds):
      case EchoLoop(:final timeSeconds):
        await engine.seek(
          Duration(milliseconds: (timeSeconds * 1000).round()),
        );
    }
  }

  Future<void> seekTo(Duration target) async {
    final echo = ref.read(echoModeProvider);
    var seconds = target.inMilliseconds / 1000.0;
    if (echo.active) {
      final dur = state?.durationSeconds;
      final window = normalizeEchoWindow((
        active: true,
        startTimeSeconds: echo.startTimeSeconds,
        endTimeSeconds: echo.endTimeSeconds,
        durationSeconds: dur != null && dur > 0 ? dur : null,
      ));
      if (window != null) {
        seconds = clampSeekTimeToEchoWindow(seconds, window);
      }
    }
    await engine.seek(Duration(milliseconds: (seconds * 1000).round()));
  }

  Future<void> seekToSeconds(double seconds) async {
    await seekTo(Duration(milliseconds: (seconds * 1000).round()));
  }

  Future<void> togglePlay() async {
    await engine.playOrPause();
  }

  Future<void> play() async {
    await engine.play();
  }

  Future<void> clear() async {
    ref.read(playbackSessionPersisterProvider).cancel();
    await ref.read(embeddedTrackSyncProvider).cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    _positionSub = null;
    _durationSub = null;
    await engine.stop();
    ref.read(echoModeProvider.notifier).deactivate();
    state = null;
  }
}
