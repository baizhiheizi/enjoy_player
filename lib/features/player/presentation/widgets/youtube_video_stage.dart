/// YouTube half of the surface host slot: WebView host + poster overlays.
library;

import 'dart:math' as math;
import 'dart:ui' show ImageByteFormat;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/player/application/engines/youtube/youtube_frame_watchdog.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_player_engine.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_webview_host.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/presentation/widgets/youtube_video_poster.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Video stage mounted for a [YoutubePlayerEngine].
///
/// Moved out of the engine (issue #664): an application service must not build
/// widgets. The engine publishes the non-widget inputs this stage reads —
/// [YoutubePlayerEngine.session] and [YoutubePlayerEngine.webViewLifecycle] —
/// and is told about stage layout through
/// [YoutubePlayerEngine.noteStageViewportSize] so the focus policy stays with
/// the transport code.
class YoutubeVideoStage extends ConsumerWidget {
  const YoutubeVideoStage({
    super.key,
    required this.engine,
    required this.maxWidth,
    required this.maxHeight,
  });

  final YoutubePlayerEngine engine;
  final double maxWidth;
  final double maxHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (maxWidth <= 0 || maxHeight <= 0) {
      return const SizedBox.shrink();
    }
    engine.noteStageViewportSize(width: maxWidth, height: maxHeight);

    final session = engine.session;
    return ValueListenableBuilder<int>(
      valueListenable: session.mountTick,
      builder: (context, _, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            if (engine.availability.canPlay && session.shouldMountWebView)
              _FrameWatchdogLayer(
                engine: engine,
                onStalled: () => ref
                    .read(playerControllerProvider.notifier)
                    .restartWithSoftwareGl(),
                child: _webViewHost(),
              ),
            _StageBufferingLeaf(engine: engine),
          ],
        );
      },
    );
  }

  Widget _webViewHost() {
    return YoutubeWebViewHost(
      key: engine.session.webViewHostKey,
      controller: engine.webViewLifecycle,
      currentVideoId: () => engine.session.videoId,
    );
  }
}

/// Samples the webview texture through a [RepaintBoundary] and hands the
/// luminance pairs to the [YoutubeFrameWatchdog] (specs/047 T047): a playing
/// video whose texture stays near-black and static is the hardware
/// frame-export stall, and the verdict triggers the software-GL rebuild.
class _FrameWatchdogLayer extends StatefulWidget {
  const _FrameWatchdogLayer({
    required this.engine,
    required this.onStalled,
    required this.child,
  });

  final YoutubePlayerEngine engine;
  final VoidCallback onStalled;
  final Widget child;

  @override
  State<_FrameWatchdogLayer> createState() => _FrameWatchdogLayerState();
}

class _FrameWatchdogLayerState extends State<_FrameWatchdogLayer> {
  final GlobalKey _boundaryKey = GlobalKey();
  YoutubeFrameWatchdog? _watchdog;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStart());
  }

  @override
  void didUpdateWidget(_FrameWatchdogLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_watchdog == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStart());
    }
  }

  void _maybeStart() {
    if (!mounted || _watchdog != null) return;
    if (!widget.engine.availability.canPlay) return;
    if (!widget.engine.session.loggedFirstPlaying) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStart());
      return;
    }
    _watchdog = YoutubeFrameWatchdog(
      sampleProvider: _takeSample,
      playingCheck: () => widget.engine.session.playing,
      stalledCallback: widget.onStalled,
    )..start();
  }

  Future<FrameSample?> _takeSample() async {
    final boundary = _boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary ||
        !boundary.hasSize ||
        boundary.debugNeedsPaint) {
      return null;
    }
    final image = await boundary.toImage(pixelRatio: 0.15);
    try {
      final bytes = await image.toByteData(
        format: ImageByteFormat.rawStraightRgba,
      );
      if (bytes == null) return null;
      final data = bytes.buffer.asUint8List(
        bytes.offsetInBytes,
        bytes.lengthInBytes,
      );
      var sum = 0.0;
      var sumSq = 0.0;
      var count = 0;
      for (var i = 0; i + 3 < data.length; i += 16) {
        final luminance = (data[i] + data[i + 1] + data[i + 2]) / (3 * 255);
        sum += luminance;
        sumSq += luminance * luminance;
        count++;
      }
      if (count == 0) return null;
      final mean = sum / count;
      final variance = math.max(0.0, sumSq / count - mean * mean);
      return (mean: mean, deviation: math.sqrt(variance));
    } finally {
      image.dispose();
    }
  }

  @override
  void dispose() {
    _watchdog?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(key: _boundaryKey, child: widget.child);
  }
}

/// Buffering-driven leaf of the stage (issue #663).
///
/// Owns the engine's buffering stream so the overlays that depend on it —
/// the poster and the mid-playback spinner — rebuild in a leaf that sits
/// *next to* the WebView host in the stage stack, never above it. The poster
/// is a "playback never started" affordance, not a buffering one (issue
/// #662): keyed to the session's first-playing latch, so a mid-playback
/// `waiting` no longer fades the static thumbnail OVER the live frame; a
/// stall after playback has started gets the small spinner instead.
class _StageBufferingLeaf extends StatelessWidget {
  const _StageBufferingLeaf({required this.engine});

  final YoutubePlayerEngine engine;

  @override
  Widget build(BuildContext context) {
    final session = engine.session;
    return StreamBuilder<bool>(
      stream: engine.buffering,
      initialData: session.buffering,
      builder: (context, snapshot) {
        final bufferingNow = snapshot.data ?? session.buffering;
        final posterVisible = bufferingNow && !session.loggedFirstPlaying;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (session.tapToPlayHintActive && !posterVisible)
              _YoutubeTapToPlayHint(
                label:
                    AppLocalizations.of(context)?.youtubeTapToPlayHint ??
                    'Tap to play',
              ),
            YoutubeVideoPoster(
              primaryUrl: session.posterUrl,
              visible: posterVisible,
            ),
            if (bufferingNow && session.loggedFirstPlaying)
              const _YoutubeBufferingIndicator(),
          ],
        );
      },
    );
  }
}

class _YoutubeTapToPlayHint extends StatelessWidget {
  const _YoutubeTapToPlayHint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: ColoredBox(
        color: Colors.black45,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                EnjoyIcons.playCircle,
                size: 64,
                color: Colors.white70,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mid-playback buffering affordance (issue #662).
///
/// The poster used to be the only buffering overlay, which meant every
/// `waiting` after playback had started faded a static thumbnail over the
/// live frame. Once playback has started the stall is signalled with this
/// instead: a small spinner on a light scrim, never covering the video.
class _YoutubeBufferingIndicator extends StatelessWidget {
  const _YoutubeBufferingIndicator();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      ignoring: true,
      child: ColoredBox(
        color: Colors.black26,
        child: Center(
          child: SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
