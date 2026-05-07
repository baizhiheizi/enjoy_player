/// Video surface + transcript side panel (desktop-friendly split).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class VideoPlayerLayout extends StatefulWidget {
  const VideoPlayerLayout({
    required this.controller,
    required this.transcript,
    super.key,
  });

  final VideoController controller;
  final Widget transcript;

  @override
  State<VideoPlayerLayout> createState() => _VideoPlayerLayoutState();
}

class _VideoPlayerLayoutState extends State<VideoPlayerLayout> {
  /// Minimum transcript column width when layout allows it.
  static const double _kMinTranscriptWidth = 240;

  /// Transcript may use at most this fraction of total width (video keeps ≥50%).
  static const double _kMaxTranscriptFraction = 0.5;

  /// Initial transcript width as a fraction of total (before first drag).
  static const double _kDefaultTranscriptFraction = 0.4;

  /// Hit target for the invisible resize strip.
  static const double _kSplitterHitWidth = 12;

  /// User-chosen transcript width in pixels; `null` = use default fraction.
  double? _transcriptWidthPx;

  /// Hover on splitter (desktop) for a faint affordance — no hard divider line.
  bool _splitterHovered = false;

  double _transcriptWidthForTotal(double totalWidth) {
    final maxW = totalWidth * _kMaxTranscriptFraction;
    final minW = math.min(_kMinTranscriptWidth, maxW);
    final defaultW = totalWidth * _kDefaultTranscriptFraction;
    final raw = _transcriptWidthPx ?? defaultW;
    return raw.clamp(minW, maxW);
  }

  void _applyDragDelta(double totalWidth, double deltaDx) {
    final maxW = totalWidth * _kMaxTranscriptFraction;
    final minW = math.min(_kMinTranscriptWidth, maxW);
    final current = _transcriptWidthForTotal(totalWidth);
    setState(() {
      // Subtract delta so the split follows the pointer: drag left widens
      // transcript / narrows video; drag right does the opposite.
      _transcriptWidthPx = (current - deltaDx).clamp(minW, maxW);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth > t.breakpointTranscriptSideBySide;
        if (wide) {
          final total = constraints.maxWidth;
          final tw = _transcriptWidthForTotal(total);
          final vw = math.max(0.0, total - tw - _kSplitterHitWidth);
          final cs = Theme.of(context).colorScheme;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: vw,
                child: _VideoStageBackground(
                  padding: EdgeInsets.zero,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      return _VideoWidthAspectViewport(
                        controller: widget.controller,
                        maxWidth: c.maxWidth,
                        maxHeight: c.maxHeight,
                        fill: cs.surface,
                      );
                    },
                  ),
                ),
              ),
              _ResizeSplitter(
                hitWidth: _kSplitterHitWidth,
                hovered: _splitterHovered,
                onHover: (v) => setState(() => _splitterHovered = v),
                semanticLabel:
                    AppLocalizations.of(context)!.playerTranscriptResizeHint,
                onDragDelta: (dx) => _applyDragDelta(total, dx),
              ),
              SizedBox(
                width: tw,
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surface,
                  child: widget.transcript,
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            Expanded(
              flex: 2,
              child: _VideoStageBackground(
                padding: EdgeInsets.zero,
                child: LayoutBuilder(
                  builder: (context, c) {
                    final cs = Theme.of(context).colorScheme;
                    return _VideoWidthAspectViewport(
                      controller: widget.controller,
                      maxWidth: c.maxWidth,
                      maxHeight: c.maxHeight,
                      fill: cs.surface,
                    );
                  },
                ),
              ),
            ),
            Expanded(flex: 3, child: widget.transcript),
          ],
        );
      },
    );
  }
}

/// Full zone width, native display aspect ratio, [BoxFit.contain] — no stretch.
/// Taller-than-zone frames are centered and clipped; shorter frames letterbox
/// (gradient shows in [_VideoStageBackground]).
class _VideoWidthAspectViewport extends StatelessWidget {
  const _VideoWidthAspectViewport({
    required this.controller,
    required this.maxWidth,
    required this.maxHeight,
    required this.fill,
  });

  final VideoController controller;
  final double maxWidth;
  final double maxHeight;
  final Color fill;

  static double _aspectRatio(VideoParams vp, PlayerState state) {
    if (vp.aspect != null && vp.aspect! > 0) {
      return vp.aspect!;
    }
    final ww = vp.dw ?? vp.w ?? state.width;
    final hh = vp.dh ?? vp.h ?? state.height;
    if (ww != null && hh != null && ww > 0 && hh > 0) {
      return ww / hh;
    }
    return 16 / 9;
  }

  @override
  Widget build(BuildContext context) {
    if (maxWidth <= 0 || maxHeight <= 0) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<double>(
      // Avoid rebuilding this subtree for every raw videoParams tick.
      // On Windows this can overwhelm the accessibility bridge.
      stream: controller.player.stream.videoParams
          .map((vp) => _aspectRatio(vp, controller.player.state))
          .distinct((a, b) => (a - b).abs() < 0.0001),
      initialData: _aspectRatio(
        controller.player.state.videoParams,
        controller.player.state,
      ),
      builder: (context, snapshot) {
        final ar = (snapshot.data ?? (16 / 9)).clamp(0.001, 1000.0);
        final w = maxWidth;
        final h = w / ar;

        return ClipRect(
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: w,
              height: h,
              child: ExcludeSemantics(
                child: Video(
                  controller: controller,
                  controls: null,
                  width: w,
                  height: h,
                  fit: BoxFit.contain,
                  fill: fill,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Soft gradient behind the video — avoids a flat “box” and matches surface tokens.
class _VideoStageBackground extends StatelessWidget {
  const _VideoStageBackground({
    required this.child,
    required this.padding,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceContainerLow,
            cs.surface,
            Color.lerp(cs.surface, cs.surfaceContainerHigh, 0.55)!,
          ],
          stops: const [0.0, 0.42, 1.0],
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _ResizeSplitter extends StatelessWidget {
  const _ResizeSplitter({
    required this.hitWidth,
    required this.hovered,
    required this.onHover,
    required this.onDragDelta,
    required this.semanticLabel,
  });

  final double hitWidth;
  final bool hovered;
  final ValueChanged<bool> onHover;
  final ValueChanged<double> onDragDelta;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      cursor: SystemMouseCursors.resizeColumn,
      child: SizedBox(
        width: hitWidth,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (details) {
            onDragDelta(details.delta.dx);
          },
          child: Tooltip(
            message: semanticLabel,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                width: hovered ? 3 : 0,
                height: 88,
                decoration: BoxDecoration(
                  color: hovered
                      ? cs.outline.withValues(alpha: 0.45)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
