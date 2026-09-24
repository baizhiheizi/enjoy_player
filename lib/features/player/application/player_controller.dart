/// Owns [PlaybackSession] state and orchestrates [PlayerEngine] + side services.
library;

import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/platform/linux_platform_availability.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/library/application/library_repository_provider.dart';
import 'package:enjoy_player/features/player/application/completion_loop.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/engine_swap_coordinator.dart';
import 'package:enjoy_player/features/player/application/engines/media_kit/media_kit_player_engine.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_player_engine.dart';
import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:enjoy_player/features/player/application/player_engine_capabilities.dart';
import 'package:enjoy_player/features/player/application/player_engine_rev.dart';
import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';
import 'package:enjoy_player/features/player/application/player_open_coordinator.dart';
import 'package:enjoy_player/features/player/application/player_position_tracker.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/features/player/application/single_flight_gate.dart';
import 'package:enjoy_player/features/player/domain/echo_window.dart';
import 'package:enjoy_player/features/player/domain/open_media_options.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/domain/player_launch_request.dart';
import 'package:enjoy_player/features/player/domain/playable_source.dart';
import 'package:enjoy_player/features/player/domain/transport_decisions.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';
import 'open_media_provider.dart';
import 'playback_session_persister.dart';
import 'player_open_side_effects.dart';
import 'video_poster_capture_service.dart';

part 'player_controller.g.dart';

/// Deterministic end-of-media completion loop (ADR-0044).
///
/// Mirrors the generation-counter + single-flight pattern from
/// [SingleFlightGate]: the transport drives itself off `await`ed completion
/// futures instead of polling the position stream, and every in-flight await
/// captures a generation id so a stale completion from a previous media (or a
/// duplicate `completed` event from mpv) is a no-op.
@Riverpod(keepAlive: true)
class PlayerController extends _$PlayerController implements PlayerOpenScope {
  /// Real engine (null until first open, or [PlayerEngine] tests override).
  /// Presentation and tests reach it directly; the open scope deliberately
  /// does not (issue #750 narrowed it to two swap operations; issue #751 will
  /// revisit engine identity separately).
  PlayerEngine? ownedEngine;

  late final PlayerPositionTracker _positionTracker = PlayerPositionTracker(
    ref: ref,
    getEngine: () => activeEngine,
    getSession: () => state,
    setSession: (next) => state = next,
    currentOpenGeneration: () => _openGate.generation,
  );

  /// The open generation: bumped by [openMedia], [clear] and
  /// [abandonPendingOpen]; every async step of an open captures it at entry
  /// ([openGeneration] / [isOpenStale]) and bails when it has moved on. The
  /// single-flight slot is unused here — see [EngineSwapCoordinator] for the
  /// swap-in-flight latch (issue #720).
  final SingleFlightGate _openGate = SingleFlightGate();

  /// Sole owner of engine-swap choreography (issue #720): install + bump,
  /// surface-detach wait, wedged-engine replacement, open retry ladder, and
  /// the swap-in-flight latch. Mechanics — what every caller agrees on — live
  /// here; *policy* (clear, abandon, default MediaKit allocation, warm-only
  /// when idle) stays in the controller.
  late final EngineSwapCoordinator _engineSwap = EngineSwapCoordinator(
    ref: ref,
    getOwnedEngine: () => ownedEngine,
    setOwnedEngine: (next) => ownedEngine = next,
    getActiveEngine: () => activeEngine,
    currentOpenGeneration: () => _openGate.generation,
    abandonPendingOpen: abandonPendingOpen,
  );

  /// Deterministic end-of-media loop (ADR-0044). Owns the playback
  /// generation counter, the cancelable `completed` await, and the repeat
  /// decision — see [CompletionLoop].
  late final CompletionLoop _completionLoop = CompletionLoop(
    engine: () => activeEngine,
    activeMediaId: () => state?.mediaId,
    isDisposed: () => _disposed,
    repeatMode: () => ref.read(playerPreferencesCtrlProvider).repeatMode,
    echoSnapshot: () {
      final echo = ref.read(echoModeProvider);
      return (active: echo.active, startTimeSeconds: echo.startTimeSeconds);
    },
  );

  bool _disposed = false;

  /// Native (mpv) teardown future, captured so an explicit caller (tests, a
  /// future logout flow) can await disposal. Riverpod's `ref.onDispose` is
  /// synchronous and does NOT await it, so the keepAlive provider must not be
  /// invalidated without coordinating teardown (ADR-0003 / ADR-0015).
  Future<void> _teardown = Future<void>.value();

  Future<void> get teardown => _teardown;

  @override
  int get openGeneration => _openGate.generation;

  @override
  bool isOpenStale(int gen) => _openGate.isStale(gen);

  @override
  PlaybackSession? get session => state;

  @override
  void publishSession(PlaybackSession? next) => state = next;

  @override
  PlayerPositionTracker get positionTracker => _positionTracker;

  /// The single dependency channel of the open scope (issue #750): captured
  /// lazily on first open so headless tests never touch providers they do
  /// not use. The two scheduler closures bind this controller's own `Ref`,
  /// which is what keeps raw `Ref` out of the choreography body.
  @override
  late final PlayerOpenDeps deps = PlayerOpenDeps(
    persister: ref.read(playbackSessionPersisterProvider),
    db: ref.read(appDatabaseProvider),
    preferences: ref.read(playerPreferencesCtrlProvider.notifier),
    echoMode: ref.read(echoModeProvider.notifier),
    blurMode: ref.read(transcriptBlurModeProvider.notifier),
    posterService: ref.read(videoPosterCaptureServiceProvider),
    scheduleOpenSideEffects:
        ({
          required int openGeneration,
          required String mediaId,
          required String dexieTargetType,
        }) => schedulePlayerOpenSideEffects(
          ref,
          openGeneration: openGeneration,
          isStale: () => isOpenStale(openGeneration),
          mediaId: mediaId,
          dexieTargetType: dexieTargetType,
        ),
    scheduleYoutubeMetadata:
        ({
          required int openGeneration,
          required String mediaId,
          required PlayerEngine engine,
        }) => scheduleYoutubeMetadataRefresh(
          ref,
          mediaId: mediaId,
          openGeneration: openGeneration,
          engine: engine,
          currentOpenGeneration: () => this.openGeneration,
          currentSessionMediaId: () => state?.mediaId,
        ),
  );

  /// Engine-swap access for the open scope is exactly the two operations the
  /// choreography uses (issue #750); the swap itself stays owned by
  /// [EngineSwapCoordinator] (issue #720).
  @override
  Future<bool> ensureEngineForPlayableSource({
    required PlayableSource playable,
    required int openGeneration,
  }) => _engineSwap.ensureEngineForPlayableSource(
    playable: playable,
    openGeneration: openGeneration,
  );

  @override
  Future<void> openEngineWithRetry({
    required PlayerEngine engine,
    required PlayableSource playable,
    required int openGeneration,
    required bool swappedAfterInstall,
    required Duration openTimeout,
    required Duration engineCommandTimeout,
  }) => _engineSwap.openEngineWithRetry(
    engine: engine,
    playable: playable,
    openGeneration: openGeneration,
    swappedAfterInstall: swappedAfterInstall,
    openTimeout: openTimeout,
    engineCommandTimeout: engineCommandTimeout,
  );

  @override
  PlayerEngine get activeEngine {
    final testDouble = ref.read(playerEngineTestDoubleProvider);
    if (testDouble != null) return testDouble;
    _ensureDefaultMediaKitEngine();
    return ownedEngine!;
  }

  /// Allocates [MediaKitPlayerEngine] once when local/URL playback needs it.
  /// Kept out of [build] so YouTube-only opens and headless tests avoid
  /// [MediaKit.ensureInitialized] until a non-YouTube engine is required.
  void _ensureDefaultMediaKitEngine() {
    if (ownedEngine != null) return;
    if (ref.read(playerEngineTestDoubleProvider) != null) return;
    ownedEngine = MediaKitPlayerEngine();
    // Host watches [playerEngineRevProvider], not ownedEngine. Defer the bump
    // so we never notify during another provider's build.
    unawaited(
      Future<void>.microtask(() {
        if (_disposed) return;
        ref.read(playerEngineRevProvider.notifier).bump();
      }),
    );
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
  /// tracker (which resets echo enforcement), the completion loop, then the
  /// owned engine. Safe to call more than once.
  Future<void> _disposeResources(PlaybackSessionPersister persister) async {
    if (_disposed) return;
    _disposed = true;
    _completionLoop.bump();
    persister.cancel();
    await _positionTracker.cancel();
    await ownedEngine?.dispose();
  }

  Future<void> relocateAndOpen(String mediaId, XFile picked) async {
    final lib = ref.read(mediaLibraryRepositoryProvider);
    await lib.relocateLocalFile(mediaId: mediaId, picked: picked);
    state = null;
    await openMedia(mediaId);
    ref.invalidate(openMediaActionProvider(mediaId));
    ref.invalidate(
      openMediaLaunchProvider(PlayerLaunchRequest(mediaId: mediaId)),
    );
  }

  Future<void> openMedia(
    String mediaId, {
    OpenMediaOptions options = OpenMediaOptions.defaults,
  }) async {
    if (state?.mediaId == mediaId) {
      // Same media already open — still honor explicit launches that must
      // clear restored echo before the caller seeks.
      if (!options.restoreEcho) {
        ref.read(echoModeProvider.notifier).deactivate();
      }
      // Still bump library updatedAt so Home "Recent media" reflects this open.
      unawaited(
        ref.read(mediaLibraryRepositoryProvider).touchMediaUpdatedAt(mediaId),
      );
      return;
    }

    final gen = _openGate.bump();
    // Marked before the first await so a speculative [warmYoutubeSurface] that
    // lands inside this window sees the open that is already coordinating the
    // engine (issue #657). Latch lives on the swap coordinator (issue #720).
    _engineSwap.markOpenInFlight();
    _completionLoop.bump();

    try {
      await runPlayerOpenGuarded(
        this,
        mediaId,
        options: options,
        onFailureResetSession: () {
          if (!_openGate.isStale(gen)) {
            state = null;
          }
        },
      );
    } finally {
      // Only a still-current open clears the flag — an open superseded by a
      // newer one must not report "idle" while that newer one is still running.
      _engineSwap.clearOpenInFlightIfCurrent(gen);
    }

    // Start the deterministic completion loop for the new playback stint
    // (ADR-0044). Only when the open actually landed (state's mediaId matches
    // and the generation is still current).
    if (!_disposed && !_openGate.isStale(gen) && state?.mediaId == mediaId) {
      _completionLoop.arm();
      // Promote to Home "Recent media" even if playback is still starting.
      unawaited(
        ref.read(mediaLibraryRepositoryProvider).touchMediaUpdatedAt(mediaId),
      );
    }
  }

  Future<void> seekTo(
    Duration target, {
    EchoWindow? echoWindowForSeekClamp,
  }) async {
    // Invalidate any in-flight completion await so a stale `completed` event
    // from mpv (fired before the seek took effect) cannot trigger a stray
    // repeat/advance (ADR-0044 edge case).
    _completionLoop.bump();
    final echo = ref.read(echoModeProvider);
    final seconds = secondsFromDuration(target);
    if (decideSeekRouting(echoActive: echo.active)) {
      await _positionTracker.echoEnforcer.clampAndSeek(
        seconds,
        override: echoWindowForSeekClamp,
      );
    } else {
      await activeEngine.seek(durationFromSeconds(seconds));
    }
    // Re-arm the completion loop for the post-seek playback stint.
    _completionLoop.arm();
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
    // Re-arm the loop in case playback was resumed from a completed state
    // (no-op if the loop is already active).
    _completionLoop.arm();
  }

  Future<void> play() async {
    await activeEngine.play();
    // If the completion loop has ended (e.g. RepeatMode.none and the media
    // completed), start a fresh loop so repeat/stop behavior is active for the
    // new playback stint (ADR-0044).
    _completionLoop.arm();
  }

  Future<void> clear({bool keepVideoSurface = false}) async {
    _completionLoop.bump();
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

    _openGate.bump();
    // Clear invalidates any open still in flight, so drop the flag too — that
    // open's `finally` skips the reset (its generation is stale) and the latch
    // would otherwise disable speculative warming for the rest of the session
    // (issue #657).
    _engineSwap.clearOpenInFlight();

    final engine = activeEngine;

    ref.read(echoModeProvider.notifier).deactivate();
    ref.read(transcriptBlurModeProvider.notifier).deactivate();
    state = null;

    // WebView engines idle and keep their process alive across clear; native
    // engines stop — the policy lives behind the engine seam (issue #595).
    await engine.teardownAfterClear(keepSurfaceMounted: keepVideoSurface);
  }

  void warmYoutubeSurface() {
    if (ref.read(playerEngineTestDoubleProvider) != null) return;
    // ADR-0048: on Linux the YouTube engine has no inappwebview backend and
    // can never mount — do not install or warm it from feed scrolling.
    if (youTubeEngineOptedOutHere) return;
    // Issue #657: warming is best-effort pre-work for a *possible* YouTube
    // open, so it must never disturb a live engine. Disposing MediaKit outside
    // the open path wedges the native mpv event pump (every later open then
    // hangs on the loading skeleton), and swapping `ownedEngine` while an open
    // is in flight replaces the engine that open is about to drive — without
    // generation coordination there is nothing to undo it.
    if (_disposed || state != null || _engineSwap.isOpenInFlight) return;

    final owned = ownedEngine;
    if (owned != null && owned is YoutubePlaybackEngine) {
      owned.warmVideoSurface();
      return;
    }
    if (owned != null) {
      // An idle MediaKit engine (cleared session, parked surface) is still
      // alive. Keep it — only the open path swaps engines, and it does so with
      // generation coordination ([EngineSwapCoordinator]). A speculative warm
      // that disposed mpv here would buy a WebView we may never use and leave
      // the next local open rebuilding against a wedged pump (2026-08-29
      // field report).
      return;
    }
    // Genuinely no engine yet — install the YouTube one. The coordinator's
    // [install] bumps the rev (ADR-0057) so PlayerSurfaceHost keys a stage for
    // the new engine. There is no prior engine to tear down, and this path
    // never calls [EngineSwapCoordinator.discardWithoutAwaiting]: a
    // speculative warm must not be able to dispose an engine even if the
    // guards above rot.
    _engineSwap.install(YoutubePlayerEngine());
    ownedEngine!.warmVideoSurface();
  }

  void abandonPendingOpen() {
    _openGate.bump();
    _completionLoop.bump();
  }

  /// Called by [PlayerMetadataService] after lazy title/thumbnail refresh.
  void applySessionPatch(PlaybackSession patched) {
    if (state?.mediaId != patched.mediaId) return;
    state = patched;
  }
}
