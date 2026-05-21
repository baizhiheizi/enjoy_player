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
import 'youtube_page_inject.dart';
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

  String _videoId = '';

  /// Exposed for WebView initial URL (same library hosts [_YoutubeWebViewHost]).
  String get currentVideoId => _videoId;

  bool _disposed = false;
  bool _playbackCompleted = false;

  Timer? _pollTimer;
  double? _pendingSeekSeconds;

  bool _rejectingNativeFullscreen = false;

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
    // Do not key by [_videoId]: changing the key disposes the old [InAppWebView]
    // while [open] still holds its controller and calls [loadUrl] →
    // MissingPluginException. One WebView instance; navigate via [loadWatchPage].
    return _YoutubeWebViewHost(engine: this);
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
    await YoutubeWebViewBridge.setVolume(_webController, volume.clamp(0, 1));
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

  @override
  Future<Uint8List?> screenshot({String? format}) async => null;

  @override
  void warmVideoSurface() {}

  @override
  Future<void> dispose() async {
    _disposed = true;
    _stopPolling();
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
  }

  void _emitBuffering(bool v) {
    if (_disposed || _bufferingCtrl.isClosed) return;
    if (v == _buffering) return;
    _buffering = v;
    _bufferingCtrl.add(v);
  }

  void _onWebViewCreated(InAppWebViewController controller) {
    _webController = controller;

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
            break;
          case 'pause':
            _pausedPollStreak = 0;
            _emitPlaying(false);
            _stopPolling();
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
  }

  void _onWebViewDisposed(InAppWebViewController? controller) {
    if (identical(_webController, controller)) {
      _webController = null;
      _stopPolling();
    }
  }

  Future<void> _loadCurrentVideoIfAttached() async {
    final controller = _webController;
    if (controller == null || _videoId.isEmpty) return;
    try {
      await YoutubeWebViewBridge.loadWatchPage(controller, _videoId);
    } on MissingPluginException catch (e, st) {
      // Windows can deallocate the native platform view during route
      // replacement before Dart receives widget disposal. Treat that controller
      // as stale; the next mounted WebView will load [_videoId] via initialUrl.
      if (identical(_webController, controller)) {
        _webController = null;
        _stopPolling();
      }
      _logYoutube.fine('Ignoring loadUrl on stale YouTube WebView', e, st);
    }
  }

  Future<void> _onPageFinished(InAppWebViewController controller) async {
    await injectYoutubeMobileWatchPage(controller);
  }

  Future<void> _exitNativeFullscreen(InAppWebViewController controller) async {
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

  Future<void> _onNativeFullscreenExit(
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
            }
          },
    );
  }
}

class _YoutubeWebViewHost extends StatefulWidget {
  const _YoutubeWebViewHost({required this.engine});

  final YoutubePlayerEngine engine;

  @override
  State<_YoutubeWebViewHost> createState() => _YoutubeWebViewHostState();
}

class _YoutubeWebViewHostState extends State<_YoutubeWebViewHost> {
  InAppWebViewController? _controller;

  @override
  void dispose() {
    widget.engine._onWebViewDisposed(_controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.engine;
    final vid = e.currentVideoId;
    if (vid.isEmpty) {
      return const ColoredBox(color: Colors.black);
    }

    final iosInlinePlayback = defaultTargetPlatform == TargetPlatform.iOS;

    return InAppWebView(
      initialSettings: YoutubeWebViewSettings.forPlayer(),
      onWebViewCreated: (controller) {
        _controller = controller;
        e._onWebViewCreated(controller);
      },
      onEnterFullscreen: iosInlinePlayback
          ? (controller) {
              unawaited(e._exitNativeFullscreen(controller));
            }
          : null,
      onExitFullscreen: iosInlinePlayback
          ? (controller) {
              unawaited(e._onNativeFullscreenExit(controller));
            }
          : null,
      onLoadStop: (controller, url) async {
        await e._onPageFinished(controller);
      },
      shouldOverrideUrlLoading: (controller, action) async {
        final url = action.request.url?.toString() ?? '';
        if (url.contains('v=$vid') || url.contains('/$vid')) {
          return NavigationActionPolicy.ALLOW;
        }
        if (url.contains('consent.youtube.com') ||
            url.contains('accounts.google.com') ||
            url.contains('myaccount.google.com') ||
            url.contains('gstatic.com') ||
            url.contains('googleapis.com')) {
          return NavigationActionPolicy.ALLOW;
        }
        return NavigationActionPolicy.CANCEL;
      },
      initialUrlRequest: URLRequest(url: YoutubeWebViewBridge.watchUri(vid)),
    );
  }
}
