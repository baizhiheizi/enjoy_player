/// Owns [PlaybackSession] state and orchestrates [PlayerEngine] + side services.
library;

import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/features/library/application/library_repository_provider.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_player_engine.dart';
import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:enjoy_player/features/player/application/player_engine_rev.dart';
import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';
import 'package:enjoy_player/features/player/application/player_open_coordinator.dart';
import 'package:enjoy_player/features/player/application/player_position_tracker.dart';
import 'package:enjoy_player/features/player/domain/echo_window.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/domain/transport_decisions.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';
import 'open_media_provider.dart';
import 'playback_session_persister.dart';
import 'player_preferences_provider.dart';

part 'player_controller.g.dart';

@Riverpod(keepAlive: true)
class PlayerController extends _$PlayerController implements PlayerOpenHost {
  /// Real engine (null until first open, or [PlayerEngine] tests override).
  PlayerEngine? _ownedEngine;

  late final PlayerPositionTracker _positionTracker = PlayerPositionTracker(
    ref: ref,
    getEngine: () => activeEngine,
    getSession: () => state,
    setSession: (next) => state = next,
    currentOpenGeneration: () => _openGeneration,
  );

  /// Incremented on each [openMedia] call; stale async work bails out.
  int _openGeneration = 0;

  bool _disposed = false;

  /// Native (mpv) teardown future, captured so an explicit caller (tests, a
  /// future logout flow) can await disposal. Riverpod's `ref.onDispose` is
  /// synchronous and does NOT await it, so the keepAlive provider must not be
  /// invalidated without coordinating teardown (ADR-0003 / ADR-0015).
  Future<void> _teardown = Future<void>.value();

  Future<void> get teardown => _teardown;

  @override
  int get openGeneration => _openGeneration;

  @override
  bool isOpenStale(int gen) => gen != _openGeneration;

  @override
  PlayerEngine? get ownedEngine => _ownedEngine;

  @override
  set ownedEngine(PlayerEngine? engine) => _ownedEngine = engine;

  @override
  PlaybackSession? get session => state;

  @override
  set session(PlaybackSession? next) => state = next;

  @override
  PlayerPositionTracker get positionTracker => _positionTracker;

  @override
  PlayerEngine get activeEngine {
    final testDouble = ref.read(playerEngineTestDoubleProvider);
    if (testDouble != null) return testDouble;
    _ensureDefaultMediaKitEngine();
    return _ownedEngine!;
  }

  /// Allocates [MediaKitPlayerEngine] once when local/URL playback needs it.
  /// Kept out of [build] so YouTube-only opens and headless tests avoid
  /// [MediaKit.ensureInitialized] until a non-YouTube engine is required.
  void _ensureDefaultMediaKitEngine() {
    if (_ownedEngine != null) return;
    if (ref.read(playerEngineTestDoubleProvider) != null) return;
    _ownedEngine = MediaKitPlayerEngine();
  }

  PlayerEngine get engine => activeEngine;

  @override
  PlaybackSession? build() {
    // Captured here (not read inside onDispose) — Riverpod forbids Ref use
    // during life-cycles.
    final persister = ref.read(playbackSessionPersisterProvider);
    ref.onDispose(() {
      // Captured so [teardown] can be awaited; Riverpod itself does not await
      // onDispose, but the [_disposed] guard makes re-entrant disposal a no-op
      // and the sequenced awaits keep mpv teardown off the hot path.
      _teardown = _disposeResources(persister);
    });

    return null;
  }

  /// Sequenced, reentrancy-guarded teardown: cancel persistence, the position
  /// tracker (which resets echo enforcement), then the owned engine. Safe to
  /// call more than once.
  Future<void> _disposeResources(PlaybackSessionPersister persister) async {
    if (_disposed) return;
    _disposed = true;
    persister.cancel();
    await _positionTracker.cancel();
    await _ownedEngine?.dispose();
  }

  Future<void> relocateAndOpen(String mediaId, XFile picked) async {
    final lib = ref.read(mediaLibraryRepositoryProvider);
    await lib.relocateLocalFile(mediaId: mediaId, picked: picked);
    state = null;
    await openMedia(mediaId);
    ref.invalidate(openMediaActionProvider(mediaId));
  }

  Future<void> openMedia(String mediaId) async {
    if (state?.mediaId == mediaId) return;

    final gen = ++_openGeneration;

    await runPlayerOpenGuarded(
      this,
      ref,
      mediaId,
      onFailureResetSession: () {
        if (gen == _openGeneration) {
          state = null;
        }
      },
    );
  }

  Future<void> seekTo(
    Duration target, {
    EchoWindow? echoWindowForSeekClamp,
  }) async {
    final echo = ref.read(echoModeProvider);
    final seconds = secondsFromDuration(target);
    final routing = decideSeekRouting(echoActive: echo.active);
    switch (routing) {
      case SeekThroughEcho():
        await _positionTracker.echoEnforcer.clampAndSeek(
          seconds,
          override: echoWindowForSeekClamp,
        );
      case SeekDirect():
        await activeEngine.seek(durationFromSeconds(seconds));
    }
  }

  Future<void> seekToSeconds(
    double seconds, {
    EchoWindow? echoWindowForSeekClamp,
  }) async {
    await seekTo(
      durationFromSeconds(seconds),
      echoWindowForSeekClamp: echoWindowForSeekClamp,
    );
  }

  Future<void> togglePlay() async {
    await activeEngine.playOrPause();
  }

  Future<void> play() async {
    await activeEngine.play();
  }

  Future<void> clear() async {
    await _positionTracker.cancel();

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

    _openGeneration++;

    final engine = activeEngine;
    final ownedEngine = _ownedEngine;
    final isYoutubeEngine =
        ref.read(playerEngineTestDoubleProvider) == null &&
        ownedEngine is YoutubePlayerEngine;

    ref.read(echoModeProvider.notifier).deactivate();
    ref.read(transcriptBlurModeProvider.notifier).deactivate();
    state = null;

    final teardown = decideTeardownPath(isYoutubeEngine: isYoutubeEngine);
    final ytEngine = ownedEngine is YoutubePlayerEngine ? ownedEngine : null;
    switch (teardown) {
      case TeardownIdle():
        await ytEngine!.idleAfterClear();
      case TeardownStop():
        await engine.stop();
    }
  }

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
    _ownedEngine = YoutubePlayerEngine(
      repeatMode: () => ref.read(playerPreferencesCtrlProvider).repeatMode,
    );
    ref.read(playerEngineRevProvider.notifier).bump();
    _ownedEngine!.warmVideoSurface();
  }

  void abandonPendingOpen() {
    _openGeneration++;
  }

  /// Called by [PlayerMetadataNotifier] after lazy title/thumbnail refresh.
  void applySessionPatch(PlaybackSession patched) {
    if (state?.mediaId != patched.mediaId) return;
    state = patched;
  }
}
