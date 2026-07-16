/// YouTube playback via mobile watch WebView + HTML5 `<video>` (ADR-0015).
library;

import 'dart:async';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:media_kit/media_kit.dart' as mk;

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/platform/linux_platform_availability.dart';
import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:enjoy_player/features/player/domain/playable_source.dart';
import 'package:enjoy_player/features/player/domain/player_settings.dart';
import 'package:enjoy_player/features/player/domain/transport_decisions.dart';
import 'package:enjoy_player/features/player/presentation/widgets/youtube_video_poster.dart';
import 'youtube_session.dart';
import 'youtube_webview_controller.dart';
import 'youtube_webview_host.dart';
import 'youtube_webview_bridge.dart';

final _logYoutube = logNamed('YouTubePlayerEngine');

/// See [YoutubeWebViewBridge.watchUri] — not iframe embed.
class YoutubePlayerEngine implements PlayerEngine {
  YoutubePlayerEngine({this.repeatMode}) : _session = YoutubeSession() {
    _webView = YoutubeWebViewController(
      session: _session,
      onStallRecovery: () => _webView.recoverStalledPlayback(),
      onLogInitPhase: (phase) => _session.logInitPhase(phase, _logYoutube.info),
      repeatMode: repeatMode,
      onMediaEnd: _onMediaLoop,
    );
  }

  /// Resolve the current [RepeatMode] at media-end time so the poll loop can
  /// decide whether to stop, loop, or segment-loop.
  final RepeatMode Function()? repeatMode;

  void _onMediaLoop() {
    _webView.prepareWatchReload(resetFirstPlaying: true);
    _session.emitBuffering(true);
    _session.emitPlaying(false);
    unawaited(_webView.loadCurrentVideoIfAttached());
  }

  final YoutubeSession _session;
  late final YoutubeWebViewController _webView;

  GlobalKey get webViewHostKey => _session.webViewHostKey;
  ValueNotifier<int> get mountTick => _session.mountTick;
  String get currentVideoId => _session.videoId;
  String? get posterUrl => _session.posterUrl;
  bool get webViewMounted => _session.webViewMounted;
  bool get shouldMountWebView => _session.shouldMountWebView;
  bool get tapToPlayHintActive => _session.tapToPlayHintActive;

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
  Stream<mk.Tracks>? get mkTracksStream => null;

  @override
  bool get supportsVideoPosterCapture => false;

  @override
  bool get supportsSubtitleDisabling => false;

  @override
  ({bool playing, bool buffering}) get transportSnapshot =>
      _session.transportSnapshot;

  @override
  Stream<double> get videoAspectRatioStream => _session.aspectStream;

  void setPosterUrl(String? url) => _session.setPosterUrl(url);

  /// Clears the internal [YoutubeSession.playbackCompleted] flag so the next
  /// [play] call drives the `<video>` directly instead of reloading the watch
  /// page. Used by the deterministic completion loop (ADR-0044) to seek + play
  /// from an arbitrary position after end-of-media.
  void resetCompletionFlag() => _session.playbackCompleted = false;

  void markOpenTimingStart() => _webView.markOpenTimingStart();

  void ensureWebViewAttached() {
    _session.requestMount();
    _logInitPhase('mount_requested');
  }

  Widget buildWebViewHost() {
    return YoutubeWebViewHost(key: _session.webViewHostKey, engine: this);
  }

  @override
  Future<void> open(PlayableSource source) async {
    if (!youtubeEngineAvailableOnLinux &&
        defaultTargetPlatform == TargetPlatform.linux) {
      throw UnsupportedError(
        'YouTube is not yet available on Linux — coming soon '
        '(ADR-0048, R1 / R6: webview2gtk-4.0 dependency).',
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
      initialData: _session.buffering,
      builder: (context, snapshot) {
        final showPoster = snapshot.data ?? _session.buffering;
        return ValueListenableBuilder<int>(
          valueListenable: mountTick,
          builder: (context, _, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Colors.black),
                if (shouldMountWebView) buildWebViewHost(),
                if (_session.tapToPlayHintActive && !showPoster)
                  const _YoutubeTapToPlayHint(),
                YoutubeVideoPoster(
                  primaryUrl: _session.posterUrl,
                  visible: showPoster,
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Future<void> disableRenderedSubtitles() async {}

  @override
  Future<void> seek(Duration target) async {
    await YoutubeWebViewBridge.seekToSeconds(
      _webView.webController,
      target.inMilliseconds / 1000.0,
    );
  }

  @override
  Future<void> setRate(double rate) async {
    await YoutubeWebViewBridge.setPlaybackRate(_webView.webController, rate);
  }

  @override
  Future<void> setVolumeNormalized(double volume) async {
    _session.volumeNormalized = volume.clamp(0, 1);
    await YoutubeWebViewBridge.setVolume(
      _webView.webController,
      _session.volumeNormalized,
    );
  }

  @override
  Future<void> playOrPause() async {
    if (_session.playing) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Future<void> play() async {
    final restart = decideYouTubePlayRestart(
      playbackCompleted: _session.playbackCompleted,
    );
    switch (restart) {
      case RestartFromBeginning():
        _webView.prepareWatchReload(resetFirstPlaying: true);
        _session.emitBuffering(true);
        _session.emitPlaying(false);
        await _webView.loadCurrentVideoIfAttached();
      case ResumePlayback():
        final controller = _webView.webController;
        if (controller == null) {
          _logYoutube.warning(
            'youtube play ignored without WebView vid=${_session.videoId}',
          );
          return;
        }
        _logYoutube.fine(
          'youtube play command vid=${_session.videoId} '
          'buffering=${_session.buffering}',
        );
        try {
          await YoutubeWebViewBridge.play(controller);
        } on Object catch (error, stackTrace) {
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
    _logYoutube.fine('youtube pause command vid=${_session.videoId}');
    try {
      await YoutubeWebViewBridge.pause(_webView.webController);
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
    await YoutubeWebViewBridge.stop(_webView.webController);
    _session.emitPlaying(false);
    _session.emitBuffering(false);
    _session.emitPosition(Duration.zero);
    _session.playbackCompleted = false;
  }

  Future<void> idleAfterClear() => _webView.idleAfterClear();

  @override
  Future<Uint8List?> screenshot({String? format}) async => null;

  @override
  void warmVideoSurface() => ensureWebViewAttached();

  @override
  Future<void> dispose() async {
    await _webView.dispose();
    await _session.closeStreams();
  }

  Future<void> onSignInNavigationBlocked(InAppWebViewController controller) =>
      _webView.onSignInNavigationBlocked(controller);

  void onWebResourceHttpError({
    required String? url,
    required int? statusCode,
    required bool isForMainFrame,
  }) {
    if (!isForMainFrame) return;
    _logYoutube.warning('youtube main-frame HTTP $statusCode url=${url ?? ''}');
  }

  void onWebResourceLoadError({
    required String url,
    required String description,
  }) {
    _logYoutube.warning('youtube load error url=$url msg=$description');
  }

  Future<void> onWebViewProcessTerminated() =>
      _webView.onWebViewProcessTerminated();

  void onWebViewCreated(
    InAppWebViewController controller, {
    bool initialWatchUrlRequested = false,
  }) {
    _webView.onWebViewCreated(
      controller,
      initialWatchUrlRequested: initialWatchUrlRequested,
    );
  }

  void onWebViewDisposed(InAppWebViewController? controller) {
    _webView.onWebViewDisposed(controller);
  }

  Future<void> onPageFinished(InAppWebViewController controller, String? url) =>
      _webView.onPageFinished(controller, url);

  Future<void> exitNativeFullscreen(InAppWebViewController controller) =>
      _webView.exitNativeFullscreen(controller);

  Future<void> onNativeFullscreenExit(InAppWebViewController controller) =>
      _webView.onNativeFullscreenExit(controller);

  void _logInitPhase(String phase) {
    _session.logInitPhase(phase, (m) => _logYoutube.fine(m));
  }
}

class _YoutubeTapToPlayHint extends StatelessWidget {
  const _YoutubeTapToPlayHint();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      ignoring: true,
      child: ColoredBox(
        color: Colors.black45,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_circle_outline, size: 64, color: Colors.white70),
              SizedBox(height: 12),
              Text(
                'Tap to play',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
