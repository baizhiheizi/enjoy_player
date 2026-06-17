/// YouTube playback via mobile watch WebView + HTML5 `<video>` (ADR-0015).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:media_kit/media_kit.dart' as mk;

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:enjoy_player/features/player/domain/playable_source.dart';
import 'package:enjoy_player/features/player/presentation/widgets/youtube_video_poster.dart';
import 'youtube_page_inject.dart';
import 'youtube_webview_host.dart';
import 'youtube_state_poller.dart';
import 'youtube_webview_bridge.dart';

final _logYoutube = logNamed('YouTubePlayerEngine');

/// See [YoutubeWebViewBridge.watchUri] — not iframe embed.
class YoutubePlayerEngine implements PlayerEngine {
  YoutubePlayerEngine();

  InAppWebViewController? _webController;

  final StreamController<Duration> _positionCtrl =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationCtrl =
      StreamController<Duration>.broadcast();
  final StreamController<bool> _playingCtrl =
      StreamController<bool>.broadcast();
  final StreamController<bool> _bufferingCtrl =
      StreamController<bool>.broadcast();

  /// Preserves [InAppWebView] state when the host moves loading → video stage.
  final GlobalKey webViewHostKey = GlobalKey();

  /// Bumps when mount is requested so loading UI rebuilds.
  final ValueNotifier<int> mountTick = ValueNotifier(0);

  String _videoId = '';
  String? _posterUrl;
  bool _mountRequested = false;
  bool _webViewMounted = false;
  bool _loggedFirstPlaying = false;

  Stopwatch? _initStopwatch;

  /// Exposed for WebView initial URL (see [YoutubeWebViewHost]).
  String get currentVideoId => _videoId;

  String? get posterUrl => _posterUrl;

  bool get webViewMounted => _webViewMounted;

  bool get shouldMountWebView => _mountRequested && !_disposed;

  bool _disposed = false;
  bool _playbackCompleted = false;

  Timer? _pollTimer;
  Timer? _pollKickTimer;
  double? _pendingSeekSeconds;

  /// Last volume applied via [setVolumeNormalized]; re-applied on main playback.
  double _volumeNormalized = 1;

  bool _rejectingNativeFullscreen = false;

  /// Bumped on each explicit watch/idle navigation so stale async loads can bail.
  int _navGeneration = 0;

  /// Poll interval is 250ms; 3 ticks ≈ 750ms of stable `paused` before we trust
  /// the poller over transient DOM noise.
  static const int _kPauseConfirmPollTicks = 3;

  /// [YoutubeStatePoller] can see a transient `paused` sample during DOM
  /// swaps (e.g. after OAuth). Require several ticks before treating it as
  /// user-visible pause so we do not stop polling / flip transport early.
  int _pausedPollStreak = 0;

  bool _playing = false;
  bool _buffering = true;

  Duration _lastPosition = Duration.zero;
  Duration _lastDuration = Duration.zero;

  final Stream<double> _aspectStream = Stream<double>.value(16 / 9);

  @override
  Stream<Duration> get position => _positionCtrl.stream;

  @override
  Stream<Duration> get duration => _durationCtrl.stream;

  @override
  Stream<bool> get playing => _playingCtrl.stream;

  @override
  Stream<bool> get buffering => _bufferingCtrl.stream;

  @override
  Stream<mk.Tracks>? get mkTracksStream => null;

  @override
  bool get supportsVideoPosterCapture => false;

  @override
  ({bool playing, bool buffering}) get transportSnapshot =>
      (playing: _playing, buffering: _buffering);

  @override
  Stream<double> get videoAspectRatioStream => _aspectStream;

  void setPosterUrl(String? url) {
    _posterUrl = url;
  }

  void markOpenTimingStart() {
    _initStopwatch = Stopwatch()..start();
    _loggedFirstPlaying = false;
    _logInitPhase('open_start');
  }

  /// Signals UI to mount the shared [YoutubeWebViewHost].
  void ensureWebViewAttached() {
    if (_disposed) return;
    _mountRequested = true;
    mountTick.value++;
    _logInitPhase('mount_requested');
  }

  /// Single long-lived WebView widget (see [webViewHostKey]).
  Widget buildWebViewHost() {
    return YoutubeWebViewHost(key: webViewHostKey, engine: this);
  }

  @override
  Future<void> open(PlayableSource source) async {
    if (source is! YoutubePlayableSource) {
      throw UnsupportedError(
        'YoutubePlayerEngine requires YoutubePlayableSource',
      );
    }
    _videoId = source.videoId;
    _playbackCompleted = false;
    _emitBuffering(true);
    _emitPlaying(false);
    _emitPosition(Duration.zero);
    _emitDuration(Duration.zero);
    ensureWebViewAttached();
    await _loadCurrentVideoIfAttached();
  }

  @override
  Widget buildVideoStage({
    required BuildContext context,
    required double maxWidth,
    required double maxHeight,
  }) {
    if (maxWidth <= 0 || maxHeight <= 0) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<bool>(
      stream: buffering,
      initialData: _buffering,
      builder: (context, snapshot) {
        final showPoster = snapshot.data ?? _buffering;
        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            if (shouldMountWebView) buildWebViewHost(),
            YoutubeVideoPoster(
              primaryUrl: _posterUrl,
              visible: showPoster,
            ),
          ],
        );
      },
    );
  }

  @override
  Future<void> disableRenderedSubtitles() async {}

  @override
  Future<void> seek(Duration target) async {
    final seconds = target.inMilliseconds / 1000.0;
    await YoutubeWebViewBridge.seekToSeconds(_webController, seconds);
  }

  @override
  Future<void> setRate(double rate) async {
    await YoutubeWebViewBridge.setPlaybackRate(_webController, rate);
  }

  @override
  Future<void> setVolumeNormalized(double volume) async {
    _volumeNormalized = volume.clamp(0, 1);
    await YoutubeWebViewBridge.setVolume(_webController, _volumeNormalized);
  }

  @override
  Future<void> playOrPause() async {
    if (_playing) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Future<void> play() async {
    if (_playbackCompleted) {
      _emitBuffering(true);
      _emitPlaying(false);
      await _loadCurrentVideoIfAttached();
      return;
    }
    await YoutubeWebViewBridge.play(_webController);
  }

  @override
  Future<void> pause() async {
    await YoutubeWebViewBridge.pause(_webController);
  }

  @override
  Future<void> stop() async {
    await YoutubeWebViewBridge.stop(_webController);
    _emitPlaying(false);
    _emitBuffering(false);
    _emitPosition(Duration.zero);
    _playbackCompleted = false;
  }

  /// Stops playback and navigates to `about:blank` while keeping the WebView warm.
  Future<void> idleAfterClear() async {
    _stopPolling();
    _videoId = '';
    _mountRequested = false;
    _playbackCompleted = false;
    _emitPlaying(false);
    _emitBuffering(false);
    _emitPosition(Duration.zero);
    mountTick.value++;
    final navGen = ++_navGeneration;
    final controller = _webController;
    if (controller == null) return;
    await YoutubeWebViewBridge.loadIdlePage(controller);
    if (_navGeneration != navGen || _videoId.isNotEmpty) {
      if (_videoId.isNotEmpty && identical(_webController, controller)) {
        unawaited(_loadCurrentVideoIfAttached());
      }
    }
  }

  @override
  Future<Uint8List?> screenshot({String? format}) async => null;

  @override
  void warmVideoSurface() {
    ensureWebViewAttached();
    // [YoutubeWebViewHost] uses `about:blank` as [initialUrlRequest] while idle;
    // an extra [loadIdlePage] here can finish after [open] and stop playback.
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _mountRequested = false;
    _pollKickTimer?.cancel();
    _pollKickTimer = null;
    _stopPolling();
    mountTick.value++;
    await _positionCtrl.close();
    await _durationCtrl.close();
    await _playingCtrl.close();
    await _bufferingCtrl.close();
  }

  void _emitPosition(Duration d) {
    if (_disposed || _positionCtrl.isClosed) return;
    if (d == _lastPosition) return;
    _lastPosition = d;
    _positionCtrl.add(d);
  }

  void _emitDuration(Duration d) {
    if (_disposed || _durationCtrl.isClosed) return;
    if (d == _lastDuration) return;
    _lastDuration = d;
    _durationCtrl.add(d);
  }

  void _emitPlaying(bool v) {
    if (_disposed || _playingCtrl.isClosed) return;
    if (v == _playing) return;
    _playing = v;
    _playingCtrl.add(v);
    if (v && !_loggedFirstPlaying) {
      _loggedFirstPlaying = true;
      _logInitPhase('first_playing');
    }
  }

  void _emitBuffering(bool v) {
    if (_disposed || _bufferingCtrl.isClosed) return;
    if (v == _buffering) return;
    _buffering = v;
    _bufferingCtrl.add(v);
    if (!v) {
      mountTick.value++;
    }
  }

  void _logInitPhase(String phase) {
    final ms = _initStopwatch?.elapsedMilliseconds;
    _logYoutube.fine(
      'youtube init $phase${ms != null ? ' +${ms}ms' : ''}',
    );
  }

  void onWebViewCreated(
    InAppWebViewController controller, {
    bool initialWatchUrlRequested = false,
  }) {
    _webController = controller;
    _webViewMounted = true;
    _logInitPhase('webview_created');

    controller.addJavaScriptHandler(
      handlerName: 'onAdReload',
      callback: (List<dynamic> args) {
        if (args.isNotEmpty) {
          _pendingSeekSeconds = (args[0] as num?)?.toDouble() ?? 0;
        }
        return null;
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onVideoEvent',
      callback: (List<dynamic> args) {
        if (args.isEmpty) return null;
        final event = args[0] as String;
        switch (event) {
          case 'play':
          case 'playing':
            _pausedPollStreak = 0;
            _playbackCompleted = false;
            _emitPlaying(true);
            _emitBuffering(false);
            _startPolling();
            _applyPendingSeek();
            unawaited(_reapplyVolume());
            break;
          case 'pause':
            // Defer playing=false / stop polling until poller confirms pause.
            _pausedPollStreak = 0;
            break;
          case 'ended':
            _pausedPollStreak = 0;
            _playbackCompleted = true;
            _stopPolling();
            _emitPlaying(false);
            unawaited(YoutubeWebViewBridge.pauseVideoElement(_webController));
            break;
          case 'waiting':
            _emitBuffering(true);
            break;
          case 'canplay':
            if (_buffering) {
              _emitBuffering(false);
            }
            break;
          case 'loadedmetadata':
            _startPolling();
            if (args.length > 1) {
              final dur = (args[1] as num).toDouble();
              if (dur > 0 && dur.isFinite) {
                _emitDuration(Duration(milliseconds: (dur * 1000).round()));
                _applyPendingSeek();
              }
            }
            break;
          case 'error':
            _logYoutube.warning('YouTube video element error');
            _emitBuffering(false);
            break;
          default:
            break;
        }
        return null;
      },
    );

    if (_videoId.isNotEmpty && !initialWatchUrlRequested) {
      unawaited(_loadCurrentVideoIfAttached());
    }
  }

  void onWebViewDisposed(InAppWebViewController? controller) {
    if (identical(_webController, controller)) {
      _webController = null;
      _webViewMounted = false;
      _stopPolling();
      mountTick.value++;
    }
  }

  Future<void> _loadCurrentVideoIfAttached() async {
    final controller = _webController;
    if (controller == null || _videoId.isEmpty) return;
    final videoId = _videoId;
    final navGen = ++_navGeneration;
    try {
      await YoutubeWebViewBridge.loadWatchPage(controller, videoId);
    } on MissingPluginException catch (e, st) {
      // Windows can deallocate the native platform view during route
      // replacement before Dart receives widget disposal. Treat that controller
      // as stale; the next mounted WebView will load [_videoId] via initialUrl.
      if (identical(_webController, controller)) {
        _webController = null;
        _webViewMounted = false;
        _stopPolling();
        mountTick.value++;
      }
      _logYoutube.fine('Ignoring loadUrl on stale YouTube WebView', e, st);
      return;
    }
    if (_navGeneration != navGen || _videoId != videoId) return;
  }

  Future<void> onPageFinished(
    InAppWebViewController controller,
    String? url,
  ) async {
    if (url == null || url == 'about:blank' || url.startsWith('about:')) {
      return;
    }
    _logInitPhase('load_stop');
    await injectYoutubeMobileWatchPage(controller);
    _schedulePollKick();
  }

  void _schedulePollKick() {
    _pollKickTimer?.cancel();
    _pollKickTimer = Timer(const Duration(milliseconds: 500), () {
      _pollKickTimer = null;
      if (!_disposed) _startPolling();
    });
  }

  Future<void> _reapplyVolume() async {
    await YoutubeWebViewBridge.setVolume(_webController, _volumeNormalized);
  }

  Future<void> exitNativeFullscreen(InAppWebViewController controller) async {
    if (_rejectingNativeFullscreen) return;
    _rejectingNativeFullscreen = true;
    try {
      // JS inline attrs only — closeAllMediaPresentations() stops playback.
      await YoutubeWebViewBridge.forceInlinePlayback(controller);
    } catch (e, st) {
      _logYoutube.fine('Failed to force inline playback', e, st);
    } finally {
      _rejectingNativeFullscreen = false;
    }
  }

  Future<void> onNativeFullscreenExit(
    InAppWebViewController controller,
  ) async {
    await YoutubeWebViewBridge.forceInlinePlayback(controller);
    if (_playing && !_playbackCompleted) {
      await YoutubeWebViewBridge.play(controller);
    }
  }

  void _applyPendingSeek() {
    final secs = _pendingSeekSeconds;
    if (secs == null || secs <= 0) return;
    _pendingSeekSeconds = null;
    unawaited(seek(Duration(milliseconds: (secs * 1000).round())));
  }

  void _startPolling() {
    if (_pollTimer != null) return;
    _pausedPollStreak = 0;
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _pollTick(),
    );
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollTick() async {
    await YoutubeStatePoller.poll(
      disposed: _disposed,
      web: _webController,
      onResult:
          ({
            required Duration position,
            Duration? newDuration,
            required bool jsPaused,
            required bool jsEnded,
          }) {
            if (_disposed) return;
            _emitPosition(position);
            if (newDuration != null &&
                newDuration > Duration.zero &&
                newDuration != _lastDuration) {
              _emitDuration(newDuration);
            }
            if (jsEnded && !_playbackCompleted) {
              _pausedPollStreak = 0;
              _playbackCompleted = true;
              _stopPolling();
              _emitPlaying(false);
            } else if (jsPaused && _playing && !jsEnded) {
              _pausedPollStreak++;
              if (_pausedPollStreak >= _kPauseConfirmPollTicks) {
                _pausedPollStreak = 0;
                _emitPlaying(false);
                _stopPolling();
              }
            } else {
              _pausedPollStreak = 0;
              if (!jsPaused && !jsEnded) {
                _playbackCompleted = false;
                _emitPlaying(true);
                if (_buffering) {
                  _emitBuffering(false);
                }
              }
            }
          },
    );
  }
}
