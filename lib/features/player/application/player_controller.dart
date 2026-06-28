/// Owns [PlaybackSession] state and orchestrates [PlayerEngine] + side services.
library;

import 'dart:async';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/library/application/library_repository_provider.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/player/domain/echo_window.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_player_engine.dart';
import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:enjoy_player/features/player/application/playback_open_resolver.dart';
import 'package:enjoy_player/features/player/application/player_engine_binding.dart';
import 'package:enjoy_player/features/player/application/player_engine_rev.dart';
import 'package:enjoy_player/features/player/application/player_open_side_effects.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/features/player/application/position_buckets.dart';
import 'package:enjoy_player/features/player/application/video_poster_capture_service.dart';
import 'package:enjoy_player/features/player/domain/playable_source.dart';
import 'open_media_provider.dart';
import 'playback_session_persister.dart';
import 'player_engine_test_double_provider.dart';

part 'player_controller.g.dart';

final _openMediaLog = logNamed('PlayerController.openMedia');

@Riverpod(keepAlive: true)
class PlayerController extends _$PlayerController {
  /// Real engine (null until first open, or [PlayerEngine] tests override).
  PlayerEngine? _ownedEngine;

  /// Active playback backend: test double, or lazily created [MediaKitPlayerEngine] / [YoutubePlayerEngine].
  PlayerEngine get _activeEngine {
    final testDouble = ref.read(playerEngineTestDoubleProvider);
    if (testDouble != null) return testDouble;
    _ownedEngine ??= MediaKitPlayerEngine();
    return _ownedEngine!;
  }

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  /// Last emitted UI bucket for raw [engine.position] ticks (see [_subscribeStreams]).
  int? _lastPositionEmitBucket;

  /// Last bucket used for echo clamping (see [_subscribeStreams]).
  int? _lastEchoApplyBucket;

  /// Incremented on each [openMedia] call; stale async work bails out.
  int _openGeneration = 0;

  int get openGeneration => _openGeneration;

  PlayerEngine get engine => _activeEngine;

  @override
  PlaybackSession? build() {
    final persister = ref.read(playbackSessionPersisterProvider);

    ref.onDispose(() async {
      persister.cancel();
      await _positionSub?.cancel();
      await _durationSub?.cancel();
      _positionSub = null;
      _durationSub = null;
      await _ownedEngine?.dispose();
    });
    return null;
  }

  Future<void> relocateAndOpen(String mediaId, XFile picked) async {
    final lib = ref.read(mediaLibraryRepositoryProvider);
    await lib.relocateLocalFile(mediaId: mediaId, picked: picked);
    state = null;
    await openMedia(mediaId);
    ref.invalidate(openMediaActionProvider(mediaId));
  }

  Future<void> openMedia(String mediaId) async {
    // Re-entering `/player/:id` while this media is already active — skip reload.
    if (state?.mediaId == mediaId) return;

    final gen = ++_openGeneration;

    try {
      final db = ref.read(appDatabaseProvider);
      final resolved = await resolvePlaybackOpen(db, mediaId);
      if (resolved == null) return;
      if (gen != _openGeneration) return;

      final video = resolved.video;
      final audio = resolved.audio;
      final kind = resolved.kind;
      final dexie = resolved.dexieTargetType;
      final title = resolved.title;
      final playable = resolved.playable;

      schedulePlayerOpenSideEffects(
        ref,
        openGeneration: gen,
        isStale: () => _openGeneration != gen,
        mediaId: mediaId,
        dexieTargetType: dexie,
      );

      await ensureEngineForPlayableSource(
        ref,
        playable: playable,
        getOwnedEngine: () => _ownedEngine,
        setOwnedEngine: (e) => _ownedEngine = e,
      );
      if (gen != _openGeneration) return;

      final engine = _activeEngine;

      final thumb = resolved.thumbnailUrl;
      final language = resolved.language;
      final durationSec = resolved.durationSeconds;

      if (playable is YoutubePlayableSource && engine is YoutubePlayerEngine) {
        engine.markOpenTimingStart();
        engine.setPosterUrl(
          _youtubePosterUrl(
            thumbnailPath: thumb,
            videoId: playable.videoId,
            mediaUrl: video?.mediaUrl,
          ),
        );
        engine.ensureWebViewAttached();
      }

      // Bind video output before first decode on Windows/macOS (see media_kit_video notes).
      // Audio-only paths skip this so unit tests and headless runs avoid native libmpv.
      if (kind == MediaKind.video &&
          engine is MediaKitPlayerEngine &&
          (Platform.isWindows || Platform.isMacOS)) {
        engine.warmVideoSurface();
      }

      await _positionSub?.cancel();
      await _durationSub?.cancel();
      _positionSub = null;
      _durationSub = null;

      await engine.open(playable);
      if (gen != _openGeneration) return;

      if (engine.supportsSubtitleDisabling) {
        await engine.disableRenderedSubtitles();
        if (gen != _openGeneration) return;
      }

      await ref
          .read(playerPreferencesCtrlProvider.notifier)
          .applyCurrentToEngine();
      if (gen != _openGeneration) return;

      final persisted = await db.echoSessionDao.getLatestForTarget(
        dexie,
        mediaId,
      );
      if (gen != _openGeneration) return;

      final posMs = persisted?.currentTimeMs ?? 0;
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
              echoStartMs: persisted.echoStartMs ?? 0,
              echoEndMs: persisted.echoEndMs ?? 0,
            );
      } else {
        ref.read(echoModeProvider.notifier).deactivate();
      }
      if (gen != _openGeneration) return;

      final now = DateTime.now();
      state = PlaybackSession(
        mediaId: mediaId,
        dexieTargetType: dexie,
        mediaType: kind.storageValue,
        mediaTitle: title,
        thumbnailUrl: thumb,
        durationSeconds: durationSec > 0
            ? durationSec.toDouble()
            : posMs / 1000.0,
        currentTimeSeconds: posMs / 1000.0,
        currentSegmentIndex: persisted?.currentSegmentIndex ?? -1,
        language: language,
        startedAt: now,
        lastActiveAt: now,
      );

      if (gen != _openGeneration) return;
      _subscribeStreams(
        mediaId: mediaId,
        dexieTargetType: dexie,
        kind: kind,
        video: video,
        audio: audio,
        gen: gen,
      );

      if (playable is YoutubePlayableSource) {
        scheduleYoutubeMetadataRefresh(
          ref,
          mediaId: mediaId,
          openGeneration: gen,
        );
      }

      if (kind == MediaKind.video &&
          video != null &&
          engine.supportsVideoPosterCapture) {
        ref
            .read(videoPosterCaptureServiceProvider)
            .scheduleCapture(
              mediaId: mediaId,
              video: video,
              restoredPositionMs: posMs,
              gen: gen,
              currentOpenGeneration: () => _openGeneration,
              currentSessionMediaId: () => state?.mediaId,
              sessionDurationSeconds: () => state?.durationSeconds,
              activeEngine: engine,
              onSessionThumbnail: (path) {
                state = state?.copyWith(thumbnailUrl: path);
              },
            );
      }
    } on Object catch (e, st) {
      if (gen == _openGeneration) {
        state = null;
      }
      _openMediaLog.severe('openMedia failed for $mediaId', e, st);
      rethrow;
    }
  }

  void _subscribeStreams({
    required String mediaId,
    required String dexieTargetType,
    required MediaKind kind,
    required VideoRow? video,
    required AudioRow? audio,
    required int gen,
  }) {
    _lastPositionEmitBucket = null;
    _lastEchoApplyBucket = null;
    // Raw mpv position can arrive very often (notably streaming). Updating
    // [PlaybackSession] on every tick rebuilds all [playerControllerProvider]
    // listeners and can overwhelm the Windows semantics bridge — same motivation
    // as [displayPositionProvider]'s quantization.
    const positionBucketMs = kPositionBucketEchoApplyMs;
    _positionSub = _activeEngine.position.listen(
      (pos) {
        if (gen != _openGeneration) return;
        final seconds = pos.inMilliseconds / 1000.0;

        final bucket = pos.inMilliseconds ~/ positionBucketMs;
        final prevSec = state?.currentTimeSeconds;
        final likelySeek = prevSec != null && (seconds - prevSec).abs() > 0.35;
        if (likelySeek || bucket != _lastEchoApplyBucket) {
          _lastEchoApplyBucket = bucket;
          unawaited(_applyEcho(seconds));
        }

        if (!likelySeek && bucket == _lastPositionEmitBucket) {
          return;
        }
        _lastPositionEmitBucket = bucket;

        state = state?.copyWith(
          currentTimeSeconds: seconds,
          lastActiveAt: DateTime.now(),
        );
        final s = state;
        if (s != null) {
          ref
              .read(playbackSessionPersisterProvider)
              .schedule(
                mediaId: mediaId,
                dexieTargetType: dexieTargetType,
                session: s,
              );
        }
      },
      onError: (Object e, StackTrace st) {
        _openMediaLog.warning('engine position stream errored', e, st);
      },
    );

    _durationSub = _activeEngine.duration.listen(
      (d) async {
        if (gen != _openGeneration) return;
        if (d <= Duration.zero) return;
        final newSec = d.inMilliseconds / 1000.0;
        final prevSec = state?.durationSeconds;
        if (prevSec != null && (newSec - prevSec).abs() < 0.001) {
          return;
        }
        final sec = d.inMilliseconds ~/ 1000;
        state = state?.copyWith(durationSeconds: newSec);
        final db = ref.read(appDatabaseProvider);
        if (kind == MediaKind.video &&
            video != null &&
            video.durationSeconds == 0) {
          await db.videoDao.insertRow(
            video.copyWith(durationSeconds: sec, updatedAt: DateTime.now()),
          );
        } else if (kind == MediaKind.audio &&
            audio != null &&
            audio.durationSeconds == 0) {
          await db.audioDao.insertRow(
            audio.copyWith(durationSeconds: sec, updatedAt: DateTime.now()),
          );
        }
      },
      onError: (Object e, StackTrace st) {
        _openMediaLog.warning('engine duration stream errored', e, st);
      },
    );
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
        await _activeEngine.seek(
          Duration(milliseconds: (timeSeconds * 1000).round()),
        );
      case EchoPauseAndRewind(:final timeSeconds):
        await _activeEngine.pause();
        await _activeEngine.seek(
          Duration(milliseconds: (timeSeconds * 1000).round()),
        );
    }
  }

  Future<void> seekTo(
    Duration target, {

    /// When set while echo is active, used for seek clamping instead of reading
    /// [echoModeProvider] (avoids clamping to the previous segment on the same
    /// stack as [EchoMode.activate]).
    ({double start, double end})? echoWindowForSeekClamp,
  }) async {
    final echo = ref.read(echoModeProvider);
    var seconds = target.inMilliseconds / 1000.0;
    if (echo.active) {
      final dur = state?.durationSeconds;
      final startT = echoWindowForSeekClamp?.start ?? echo.startTimeSeconds;
      final endT = echoWindowForSeekClamp?.end ?? echo.endTimeSeconds;
      final window = normalizeEchoWindow((
        active: true,
        startTimeSeconds: startT,
        endTimeSeconds: endT,
        durationSeconds: dur != null && dur > 0 ? dur : null,
      ));
      if (window != null) {
        seconds = clampSeekTimeToEchoWindow(seconds, window);
      }
    }
    await _activeEngine.seek(Duration(milliseconds: (seconds * 1000).round()));
  }

  Future<void> seekToSeconds(
    double seconds, {
    ({double start, double end})? echoWindowForSeekClamp,
  }) async {
    await seekTo(
      Duration(milliseconds: (seconds * 1000).round()),
      echoWindowForSeekClamp: echoWindowForSeekClamp,
    );
  }

  Future<void> togglePlay() async {
    await _activeEngine.playOrPause();
  }

  Future<void> play() async {
    await _activeEngine.play();
  }

  Future<void> clear() async {
    final positionSub = _positionSub;
    final durationSub = _durationSub;
    _positionSub = null;
    _durationSub = null;
    _lastPositionEmitBucket = null;
    _lastEchoApplyBucket = null;

    // Capture the current session + ids before [state = null] so the persister
    // can flush the last 450 ms of position updates to Drift.
    final current = state;
    final persister = ref.read(playbackSessionPersisterProvider);
    if (current != null) {
      await persister.flush(
        mediaId: current.mediaId,
        dexieTargetType: current.dexieTargetType,
        session: current,
      );
    } else {
      persister.cancel();
    }

    // Drop in-flight [openMedia] work so a dismissed YouTube open cannot
    // resurrect session state or swap engines after the user opens local media.
    _openGeneration++;

    final engine = _activeEngine;
    final ownedEngine = _ownedEngine;
    final isYoutubeEngine =
        ref.read(playerEngineTestDoubleProvider) == null &&
        ownedEngine is YoutubePlayerEngine;

    // Remove session synchronously so [Dismissible] transport unmounts before
    // async engine teardown (swipe-to-dismiss during load/buffer).
    ref.read(echoModeProvider.notifier).deactivate();
    state = null;

    await positionSub?.cancel();
    await durationSub?.cancel();

    if (isYoutubeEngine) {
      await ownedEngine.idleAfterClear();
    } else {
      await engine.stop();
    }
  }

  /// Pre-spawns the YouTube WebView process before navigating to the player.
  void warmYoutubeSurface() {
    if (ref.read(playerEngineTestDoubleProvider) != null) return;
    final owned = _ownedEngine;
    if (owned is YoutubePlayerEngine) {
      owned.warmVideoSurface();
      return;
    }
    if (owned != null) {
      unawaited(owned.dispose());
    }
    _ownedEngine = YoutubePlayerEngine();
    ref.read(playerEngineRevProvider.notifier).bump();
    _ownedEngine!.warmVideoSurface();
  }

  String? _youtubePosterUrl({
    required String? thumbnailPath,
    required String videoId,
    required String? mediaUrl,
  }) {
    return remoteThumbnailForCard(
      thumbnailPath,
      youtubeVideoId: videoId,
      mediaUrl: mediaUrl,
    );
  }

  /// Cancels an in-flight [openMedia] before [PlaybackSession] is published.
  void abandonPendingOpen() {
    _openGeneration++;
  }

  void patchSessionMetadataIfCurrent({
    required String mediaId,
    required int openGeneration,
    required String title,
    String? thumbnailUrl,
  }) {
    if (_openGeneration != openGeneration) return;
    if (state?.mediaId != mediaId) return;
    state = state?.copyWith(
      mediaTitle: title,
      thumbnailUrl: thumbnailUrl ?? state?.thumbnailUrl,
    );
  }
}
