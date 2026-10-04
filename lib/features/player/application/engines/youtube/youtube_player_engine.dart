/// YouTube playback via mobile watch WebView + HTML5 `<video>` (ADR-0015).
library;

import 'dart:async';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/platform/linux_platform_availability.dart';
import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:enjoy_player/features/player/application/player_engine_capabilities.dart';
import 'package:enjoy_player/features/player/domain/playable_source.dart';
import 'package:enjoy_player/features/player/domain/transport_decisions.dart';
import 'package:enjoy_player/features/player/domain/youtube_playback_unavailable_exception.dart';
import 'youtube_play_retry_policy.dart';
import 'youtube_session.dart';
import 'youtube_webview_controller.dart';
import 'youtube_webview_bridge.dart';

final _logYoutube = logNamed('YouTubePlayerEngine');

/// See [YoutubeWebViewBridge.watchUri] — not iframe embed.
///
/// Also implements [PlayerEngineMetadata]: YouTube is the only engine with a
/// loading poster, a source identity, and open-time init instrumentation.
class YoutubePlayerEngine
    implements PlayerEngine, PlayerEngineMetadata, YoutubePlaybackEngine {
  /// [session] is injectable so tests can drive the mount signal without a
  /// WebView backend. [availability] is the resolved runtime decision
  /// (specs/047); it defaults to the process snapshot when known, else to
  /// available — production constructors always pass it explicitly.
  YoutubePlayerEngine({
    YoutubeSession? session,
    YouTubeAvailability? availability,
  }) : _session = session ?? YoutubeSession(),
       _availability =
           availability ??
           resolvedYouTubeAvailability ??
           const YouTubeAvailable() {
    _webView = YoutubeWebViewController(
      session: _session,
      onStallRecovery: () => _webView.recoverStalledPlayback(),
      onLogInitPhase: (phase) => _session.logInitPhase(phase, _logYoutube.info),
    );
  }

  final YoutubeSession _session;
  final YouTubeAvailability _availability;

  /// The runtime availability decision this engine was constructed with.
  YouTubeAvailability get availability => _availability;

  /// Last logged video-stage size (park/unpark marker — see
  /// [noteStageViewportSize]).
  double? _lastStageSizeWidth;
  double? _lastStageSizeHeight;
  late final YoutubeWebViewController _webView;

  /// Session state the video stage renders from (poster + mount latches,
  /// buffering snapshot, WebView host key). The stage lives in the
  /// presentation layer (issue #664); this is its non-widget input.
  YoutubeSession get session => _session;

  /// WebView lifecycle owner the video stage mounts (one per engine,
  /// ADR-0015).
  YoutubeWebViewController get webViewLifecycle => _webView;

  /// Notifies the engine that its video stage laid out at [width]×[height].
  ///
  /// Diagnostic marker + focus re-assert when the stage size actually
  /// changes. ADR-0066 parks overlays off-corner; YouTube keeps its last
  /// on-screen size (a 320×180 shrink was the play-then-pause stimulus —
  /// m.youtube.com treats 320 px as a compact-player breakpoint and flushes
  /// ABR). A remaining size change is therefore a real layout jump
  /// (rotation / split). Parking can still clear view focus (the plugin
  /// exposes no requestFocus); re-assert the pinned page focus. Idempotent,
  /// no-op without a live controller.
  void noteStageViewportSize({required double width, required double height}) {
    if (width == _lastStageSizeWidth && height == _lastStageSizeHeight) return;
    _lastStageSizeWidth = width;
    _lastStageSizeHeight = height;
    _logYoutube.fine(
      'youtube stage size ${width.round()}x${height.round()} '
      'vid=${_session.videoId}',
    );
    unawaited(YoutubeWebViewBridge.refocusWindow(_webView.jsChannel));
  }

  @override
  String get currentVideoId => _session.videoId;

  @override
  String? get posterUrl => _session.posterUrl;

  /// This engine *is* its metadata capability.
  @override
  PlayerEngineMetadata get metadata => this;

  @override
  Stream<Duration> get position => _session.position;

  @override
  Stream<Duration> get duration => _session.duration;

  @override
  Stream<bool> get playing => _session.playingStream;

  @override
  Stream<bool> get buffering => _session.bufferingStream;

  @override
  Stream<void> get completed => _session.completed;

  @override
  bool get keepSurfaceWhenParked => true;

  @override
  ({bool playing, bool buffering}) get transportSnapshot =>
      _session.transportSnapshot;

  @override
  void setPosterUrl(String? url) => _session.setPosterUrl(url);

  /// Clears the session's end-of-media latch so the next
  /// [play] call drives the `<video>` directly instead of reloading the watch
  /// page. Used by the deterministic completion loop (ADR-0044) to seek + play
  /// from an arbitrary position after end-of-media.
  @override
  void resetCompletionFlag() => _session.resetCompletionFlag();

  @override
  void markOpenTimingStart() => _webView.markOpenTimingStart();

  void _ensureWebViewAttached() {
    if (!_availability.canPlay) return;
    _session.requestMount();
    _logInitPhase('mount_requested');
  }

  /// Completes when the WebView is mounted or [timeout] elapses.
  ///
  /// The mount is signalled by [YoutubeSession.noteWebViewMounted] (push from
  /// `onWebViewCreated`), so waiting costs no periodic timer on the UI thread
  /// — the 40 ms flag-poll used to sit on the `awaitSurfaceReady` critical
  /// path of every open (issue #661). [timeout] only bounds a surface that
  /// never mounts; the answer is still read off the session flag, exactly as
  /// before.
  Future<bool> _awaitWebViewMounted({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (!_availability.canPlay) return false;
    _ensureWebViewAttached();
    if (_session.webViewMounted) return true;
    await _session.awaitWebViewMounted().timeout(timeout, onTimeout: () {});
    return _session.webViewMounted;
  }

  @override
  Future<void> awaitSurfaceReady() => _awaitWebViewMounted().then((_) {});

  @override
  Future<void> awaitSurfaceDetached() => _session.awaitSurfaceDetached();

  @override
  void prepareNativeBackend() {}

  @override
  Future<void> teardownAfterClear({required bool keepSurfaceMounted}) =>
      _webView.idleAfterClear(keepMounted: keepSurfaceMounted);

  @override
  Future<void> open(PlayableSource source) async {
    final unavailable = switch (_availability) {
      final YouTubeUnavailable u => u,
      _ => null,
    };
    if (unavailable != null) {
      throw YouTubePlaybackUnavailableException.fromAvailability(
        unavailable,
        videoId: source is YoutubePlayableSource ? source.videoId : '',
      );
    }
    if (source is! YoutubePlayableSource) {
      throw UnsupportedError(
        'YoutubePlayerEngine requires YoutubePlayableSource',
      );
    }
    _webView.prepareWatchReload(resetFirstPlaying: true);
    _session.resetForOpen(source.videoId);
    _session.requestMount();
    if (!_session.awaitingColdInitialNavigation) {
      await _webView.loadCurrentVideoIfAttached();
    }
  }

  @override
  Future<void> seek(Duration target) async {
    await YoutubeWebViewBridge.seekToSeconds(
      _webView.jsChannel,
      target.inMilliseconds / 1000.0,
    );
  }

  @override
  Future<void> setRate(double rate) async {
    await YoutubeWebViewBridge.setPlaybackRate(_webView.jsChannel, rate);
  }

  @override
  Future<void> setVolumeNormalized(double volume) async {
    final applied = _session.storeVolumeNormalized(volume);
    await YoutubeWebViewBridge.setVolume(_webView.jsChannel, applied);
  }

  @override
  Future<void> playOrPause() async {
    final restart = decideYouTubePlayRestart(
      playbackCompleted: _session.playbackCompleted,
    );
    if (restart) {
      await play();
    } else {
      final controller = _webView.jsChannel;
      if (controller == null) {
        _logYoutube.warning(
          'youtube playOrPause ignored without WebView '
          'vid=${_session.videoId}',
        );
        return;
      }
      _webView.onExplicitPlayAttempt();
      _logYoutube.fine(
        'youtube playOrPause command vid=${_session.videoId} '
        'sessionPlaying=${_session.playing} '
        'buffering=${_session.buffering}',
      );
      try {
        final domDirection = await YoutubeWebViewBridge.playOrPause(controller);
        switch (_session.playRetry.classifyTransportToggle(
          domDirection: domDirection,
        )) {
          case ArmRetryBudget():
            _session.beginUserPlay();
          case ConsumeRetryBudget():
            _session.noteUserPauseCommand();
          case LeaveRetryBudget():
            break;
        }
        if (domDirection != null) {
          _logYoutube.fine(
            'youtube playOrPause direction=$domDirection '
            'vid=${_session.videoId}',
          );
        }
      } on Object catch (error, stackTrace) {
        _session.noteCommandFailed();
        _logYoutube.warning(
          'youtube playOrPause command failed vid=${_session.videoId}',
          error,
          stackTrace,
        );
      }
    }
  }

  @override
  Future<void> play() async {
    final restart = decideYouTubePlayRestart(
      playbackCompleted: _session.playbackCompleted,
    );
    if (restart) {
      _webView.prepareWatchReload(resetFirstPlaying: true);
      _webView.onExplicitPlayAttempt();
      _session.beginPlayAfterEnd();
      await _webView.loadCurrentVideoIfAttached();
    } else {
      final controller = _webView.jsChannel;
      if (controller == null) {
        _logYoutube.warning(
          'youtube play ignored without WebView vid=${_session.videoId}',
        );
        return;
      }
      _webView.onExplicitPlayAttempt();
      _session.beginUserPlay();
      _logYoutube.fine(
        'youtube play command vid=${_session.videoId} '
        'buffering=${_session.buffering} '
        'explicitPlay=${_session.explicitPlayAttempted}',
      );
      try {
        await YoutubeWebViewBridge.play(controller);
      } on Object catch (error, stackTrace) {
        _session.noteCommandFailed();
        _logYoutube.warning(
          'youtube play command failed vid=${_session.videoId}',
          error,
          stackTrace,
        );
      }
    }
  }

  @override
  Future<void> pause() async {
    _session.noteUserPauseCommand();
    _logYoutube.fine('youtube pause command vid=${_session.videoId}');
    try {
      await YoutubeWebViewBridge.pause(_webView.jsChannel);
    } on Object catch (error, stackTrace) {
      _logYoutube.warning(
        'youtube pause command failed vid=${_session.videoId}',
        error,
        stackTrace,
      );
    }
  }

  @override
  Future<void> stop() async {
    _session.stopPlayback();
    await YoutubeWebViewBridge.stop(_webView.jsChannel);
  }

  @override
  void warmVideoSurface() => _ensureWebViewAttached();

  @override
  Future<void> dispose() async {
    await _webView.dispose();
    await _session.closeStreams();
  }

  void _logInitPhase(String phase) {
    _session.logInitPhase(phase, (m) => _logYoutube.fine(m));
  }
}
