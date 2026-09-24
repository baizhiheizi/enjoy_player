/// media_kit half of the surface host slot: the letterboxed [Video] stage.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:enjoy_player/features/player/application/engines/media_kit/media_kit_player_engine.dart';
import 'package:enjoy_player/features/player/application/player_engine_constants.dart';

/// Video stage mounted for a [MediaKitPlayerEngine].
///
/// Moved out of the engine (issue #664): an application service must not build
/// widgets. The engine only publishes the non-widget inputs this stage reads —
/// [MediaKitPlayerEngine.nativeBackendAllowed] (plus its listenable, below)
/// and [MediaKitPlayerEngine.videoController].
class MediaKitVideoStage extends StatefulWidget {
  const MediaKitVideoStage({
    super.key,
    required this.engine,
    required this.maxWidth,
    required this.maxHeight,
  });

  final MediaKitPlayerEngine engine;
  final double maxWidth;
  final double maxHeight;

  @override
  State<MediaKitVideoStage> createState() => _MediaKitStageGateState();
}

/// Gates the [Video] subtree on [MediaKitPlayerEngine.nativeBackendAllowed].
///
/// While the gate is closed the stage is a bare placeholder — mpv must not be
/// allocated until the previous engine's WebView has detached. The swap arms
/// the gate with `prepareNativeBackend()` *after* that detach; this state
/// listens to [MediaKitPlayerEngine.nativeBackendAllowedListenable] so an
/// already-mounted placeholder rebuilds and mounts [Video] immediately — the
/// signal that used to ride a second hand-bumped `playerEngineRevProvider`
/// bump (issue #751: the rev is now the identity module's change signal, and
/// stage inputs notify through the engine that owns them). If the flip lands
/// before the first build, [build] simply reads `true` and mounts directly.
class _MediaKitStageGateState extends State<MediaKitVideoStage> {
  @override
  void initState() {
    super.initState();
    widget.engine.nativeBackendAllowedListenable.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(covariant MediaKitVideoStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.engine, widget.engine)) return;
    oldWidget.engine.nativeBackendAllowedListenable.removeListener(_rebuild);
    widget.engine.nativeBackendAllowedListenable.addListener(_rebuild);
  }

  @override
  void dispose() {
    // removeListener is legal after the notifier is disposed (engine teardown
    // can race the stage unmount); the swap itself unmounts the old stage via
    // ADR-0057 re-keying before it disposes the engine.
    widget.engine.nativeBackendAllowedListenable.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;
    if (widget.maxWidth <= 0 || widget.maxHeight <= 0) {
      return const SizedBox.shrink();
    }
    if (!engine.nativeBackendAllowed) {
      return const ColoredBox(color: Colors.black);
    }

    // Fill the host slot and let [Video] letterbox. An outer [ClipRect] plus a
    // child taller than the slot makes Android's Surface/Texture stay black
    // until a later layout (transcript splitter / rotation).
    return ColoredBox(
      color: Colors.black,
      child: _MediaKitVideoStage(
        controller: engine.videoController,
        maxWidth: widget.maxWidth,
        maxHeight: widget.maxHeight,
      ),
    );
  }
}

/// Mounts media_kit [Video] and relayouts it once the native texture exists.
///
/// A kick on the first Flutter frame is too early — [Texture] is still a
/// 1×1 placeholder, so the layout is a no-op. Dragging the transcript splitter
/// works because it changes the viewport *after* frames are flowing. Listen
/// for texture id/rect (and first-frame) and then pulse [Video] width/height.
class _MediaKitVideoStage extends StatefulWidget {
  const _MediaKitVideoStage({
    required this.controller,
    required this.maxWidth,
    required this.maxHeight,
  });

  final VideoController controller;
  final double maxWidth;
  final double maxHeight;

  @override
  State<_MediaKitVideoStage> createState() => _MediaKitVideoStageState();
}

class _MediaKitVideoStageState extends State<_MediaKitVideoStage> {
  var _nudge = false;
  var _kicked = false;

  @override
  void initState() {
    super.initState();
    widget.controller.id.addListener(_onTexture);
    widget.controller.rect.addListener(_onTexture);
    _onTexture();
    unawaited(_kickAfterFirstFrame());
  }

  @override
  void didUpdateWidget(covariant _MediaKitVideoStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Loading 16:9 → side-by-side chrome is a large viewport change. The first
    // kick already ran; without another pulse the Texture stays black until
    // the user resizes the window / splitter.
    final dw = (oldWidget.maxWidth - widget.maxWidth).abs();
    final dh = (oldWidget.maxHeight - widget.maxHeight).abs();
    if (dw > kVideoTextureKickMinViewportDelta ||
        dh > kVideoTextureKickMinViewportDelta) {
      _kicked = false;
      _scheduleKick();
    }
  }

  @override
  void dispose() {
    widget.controller.id.removeListener(_onTexture);
    widget.controller.rect.removeListener(_onTexture);
    super.dispose();
  }

  Future<void> _kickAfterFirstFrame() async {
    try {
      await widget.controller.waitUntilFirstFrameRendered;
    } on Object {
      return;
    }
    if (!mounted) return;
    _scheduleKick();
  }

  void _onTexture() {
    final id = widget.controller.id.value;
    final rect = widget.controller.rect.value;
    if (id == null || rect == null || rect.width <= 1 || rect.height <= 1) {
      return;
    }
    _scheduleKick();
  }

  void _scheduleKick() {
    if (_kicked) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _kick());
  }

  void _kick() {
    if (!mounted || _kicked) return;
    _kicked = true;
    setState(() => _nudge = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _nudge = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final inset = _nudge ? kVideoTextureKickInset : 0.0;
    final w = widget.maxWidth > inset
        ? widget.maxWidth - inset
        : widget.maxWidth;
    final h = widget.maxHeight > inset
        ? widget.maxHeight - inset
        : widget.maxHeight;
    return ExcludeSemantics(
      child: Video(
        controller: widget.controller,
        controls: null,
        width: w,
        height: h,
        fit: BoxFit.contain,
        fill: Colors.black,
        subtitleViewConfiguration: const SubtitleViewConfiguration(
          visible: false,
        ),
      ),
    );
  }
}
