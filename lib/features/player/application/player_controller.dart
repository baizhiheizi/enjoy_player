/// Owns [PlaybackSession] state and orchestrates [PlayerEngine] + side services.
library;

import 'dart:async';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/library/application/library_repository_provider.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/player/domain/echo_window.dart';
import 'package:enjoy_player/features/player/domain/media_relocate_exception.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'open_media_provider.dart';
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

  /// Last emitted UI bucket for raw [engine.position] ticks (see [_subscribeStreams]).
  int? _lastPositionEmitBucket;

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

    final persister = ref.read(playbackSessionPersisterProvider);

    ref.onDispose(() async {
      persister.cancel();
      await _positionSub?.cancel();
      await _durationSub?.cancel();
      _positionSub = null;
      _durationSub = null;
    });
    return null;
  }

  bool _localUriPlayable(String? uri) {
    if (uri == null || uri.isEmpty) return false;
    try {
      return File.fromUri(Uri.parse(uri)).existsSync();
    } on Object {
      return false;
    }
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

    final db = ref.read(appDatabaseProvider);
    final video = await db.videoDao.getById(mediaId);
    final audio = video == null ? await db.audioDao.getById(mediaId) : null;
    if (video == null && audio == null) return;

    final kind = video != null ? MediaKind.video : MediaKind.audio;
    final dexie = kind.dexieTargetType;
    final title = video?.title ?? audio!.title;

    final netUri = video?.mediaUrl ?? audio?.mediaUrl;
    final String sourceUri;
    if (netUri != null && netUri.isNotEmpty) {
      sourceUri = netUri;
    } else {
      final local = video?.localUri ?? audio?.localUri;
      if (_localUriPlayable(local)) {
        sourceUri = local!;
      } else {
        final fingerprint = video?.md5 ?? audio?.md5;
        if (fingerprint != null && fingerprint.isNotEmpty) {
          throw MediaNeedsRelocateException(
            mediaId: mediaId,
            kind: kind,
            title: title,
            expectedHash: fingerprint,
            expectedSize: video?.size ?? audio?.size,
          );
        }
        sourceUri = '';
      }
    }
    final thumb = video?.thumbnailUrl ?? audio?.thumbnailUrl;
    final language = video?.language ?? audio!.language;
    final durationSec = video?.durationSeconds ?? audio!.durationSeconds;

    // Bind video output before first decode on Windows (see media_kit_video notes).
    // Audio-only paths skip this so unit tests and headless runs avoid native libmpv.
    if (Platform.isWindows && kind == MediaKind.video) {
      videoController;
    }

    await _positionSub?.cancel();
    await _durationSub?.cancel();
    _positionSub = null;
    _durationSub = null;

    await engine.openUri(sourceUri);
    if (gen != _openGeneration) return;

    await engine.disableRenderedSubtitles();
    if (gen != _openGeneration) return;

    unawaited(
      ref.read(transcriptRepositoryProvider).fetchCloudTranscripts(mediaId),
    );

    final auth = ref.read(authCtrlProvider).valueOrNull;
    if (auth is AuthSignedIn) {
      unawaited(
        ref.read(recordingTargetSyncServiceProvider).pullRecordingsForTarget(
              targetType: dexie,
              targetId: mediaId,
            ),
      );
    }

    await ref.read(playerPreferencesCtrlProvider.notifier).applyCurrentToEngine();
    if (gen != _openGeneration) return;

    final persisted = await db.echoSessionDao.getLatestForTarget(dexie, mediaId);
    final posMs = persisted?.currentTimeMs ?? 0;
    if (posMs > 0) {
      await engine.seek(Duration(milliseconds: posMs));
    }
    if (gen != _openGeneration) return;

    if (persisted != null && persisted.echoActive) {
      ref.read(echoModeProvider.notifier).restoreFromSession(
        startLine: persisted.echoStartLine,
        endLine: persisted.echoEndLine,
        echoStartMs: persisted.echoStartMs ?? 0,
        echoEndMs: persisted.echoEndMs ?? 0,
      );
    } else {
      ref.read(echoModeProvider.notifier).deactivate();
    }

    final now = DateTime.now();
    state = PlaybackSession(
      mediaId: mediaId,
      dexieTargetType: dexie,
      mediaType: kind.storageValue,
      mediaTitle: title,
      thumbnailUrl: thumb,
      durationSeconds:
          durationSec > 0 ? durationSec.toDouble() : posMs / 1000.0,
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
    // Raw mpv position can arrive very often (notably streaming). Updating
    // [PlaybackSession] on every tick rebuilds all [playerControllerProvider]
    // listeners and can overwhelm the Windows semantics bridge — same motivation
    // as [displayPositionProvider]'s 200ms quantization.
    const positionBucketMs = 400;
    _positionSub = engine.position.listen((pos) {
      if (gen != _openGeneration) return;
      final seconds = pos.inMilliseconds / 1000.0;
      unawaited(_applyEcho(seconds));

      final bucket = pos.inMilliseconds ~/ positionBucketMs;
      final prevSec = state?.currentTimeSeconds;
      final likelySeek =
          prevSec != null && (seconds - prevSec).abs() > 0.35;
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
        ref.read(playbackSessionPersisterProvider).schedule(
          mediaId: mediaId,
          dexieTargetType: dexieTargetType,
          session: s,
        );
      }
    });

    _durationSub = engine.duration.listen((d) async {
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
      if (kind == MediaKind.video && video != null && video.durationSeconds == 0) {
        await db.videoDao.insertRow(
          video.copyWith(
            durationSeconds: sec,
            updatedAt: DateTime.now(),
          ),
        );
      } else if (kind == MediaKind.audio && audio != null && audio.durationSeconds == 0) {
        await db.audioDao.insertRow(
          audio.copyWith(
            durationSeconds: sec,
            updatedAt: DateTime.now(),
          ),
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
        await engine.seek(
          Duration(milliseconds: (timeSeconds * 1000).round()),
        );
      case EchoPauseAndRewind(:final timeSeconds):
        await engine.pause();
        await engine.seek(
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
      final startT =
          echoWindowForSeekClamp?.start ?? echo.startTimeSeconds;
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
    await engine.seek(Duration(milliseconds: (seconds * 1000).round()));
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
    await engine.playOrPause();
  }

  Future<void> play() async {
    await engine.play();
  }

  Future<void> clear() async {
    ref.read(playbackSessionPersisterProvider).cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    _positionSub = null;
    _durationSub = null;
    _lastPositionEmitBucket = null;
    await engine.stop();
    ref.read(echoModeProvider.notifier).deactivate();
    state = null;
  }
}
