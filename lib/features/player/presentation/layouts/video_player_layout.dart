/// Video surface + transcript side panel (desktop-friendly split).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class VideoPlayerLayout extends StatefulWidget {
  const VideoPlayerLayout({
    required this.engine,
    required this.transcript,
    super.key,
    this.initialTranscriptSplitWidthPx,
    this.onTranscriptSplitWidthCommitted,
  });

  final PlayerEngine engine;
  final Widget transcript;

  /// Restored persisted split width; `null` uses default fraction.
  final double? initialTranscriptSplitWidthPx;

  /// Called once when the user finishes dragging the resize handle.
  final ValueChanged<double>? onTranscriptSplitWidthCommitted;

  @override
  State<VideoPlayerLayout> createState() => _VideoPlayerLayoutState();
}

class _VideoPlayerLayoutState extends State<VideoPlayerLayout> {
  /// Minimum transcript column width when layout allows it.
  static const double _kMinTranscriptWidth = 360;

  @override
  void initState() {
    super.initState();
    _transcriptWidthPx = widget.initialTranscriptSplitWidthPx;
  }

  @override
  void didUpdateWidget(covariant VideoPlayerLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTranscriptSplitWidthPx !=
            oldWidget.initialTranscriptSplitWidthPx &&
        widget.initialTranscriptSplitWidthPx != null &&
        _transcriptWidthPx == null) {
      _transcriptWidthPx = widget.initialTranscriptSplitWidthPx;
    }
  }

  /// Transcript may use at most this fraction of total width (video keeps ≥50%).
  static const double _kMaxTranscriptFraction = 0.5;

  /// Initial transcript width as a fraction of total (before first drag).
  static const double _kDefaultTranscriptFraction = 0.4;

  /// Hit target for the invisible resize strip.
  static const double _kSplitterHitWidth = 12;

  /// Stacked (narrow) layout: video stage matches TV-safe 16:9 frame width.
  static const double _kMobileVideoAspectWidth = 16;
  static const double _kMobileVideoAspectHeight = 9;

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
      // Drag left widens transcript, drag right narrows it.
      _transcriptWidthPx = (current - deltaDx).clamp(minW, maxW);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSideBySide =
            constraints.maxWidth > t.breakpointTranscriptSideBySide;

        if (useSideBySide) {
          final total = constraints.maxWidth;
          final tw = _transcriptWidthForTotal(total);
          final vw = math.max(0.0, total - tw - _kSplitterHitWidth);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: vw,
                child: SafeArea(
                  top: true,
                  bottom: false,
                  left: false,
                  right: false,
                  child: ColoredBox(
                    color: Colors.black,
                    child: LayoutBuilder(
                      builder: (context, c) {
                        return widget.engine.buildVideoStage(
                          context: context,
                          maxWidth: c.maxWidth,
                          maxHeight: c.maxHeight,
                        );
                      },
                    ),
                  ),
                ),
              ),
              _ResizeSplitter(
                hitWidth: _kSplitterHitWidth,
                hovered: _splitterHovered,
                onHover: (v) => setState(() => _splitterHovered = v),
                semanticLabel: AppLocalizations.of(
                  context,
                )!.playerTranscriptResizeHint,
                onDragDelta: (dx) => _applyDragDelta(total, dx),
                onDragEnd: () => widget.onTranscriptSplitWidthCommitted?.call(
                  _transcriptWidthForTotal(total),
                ),
              ),
              SizedBox(
                width: tw,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border(
                      left: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                  ),
                  child: widget.transcript,
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SafeArea(
              top: true,
              bottom: false,
              left: false,
              right: false,
              child: AspectRatio(
                aspectRatio:
                    _kMobileVideoAspectWidth / _kMobileVideoAspectHeight,
                child: ColoredBox(
                  color: Colors.black,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      return widget.engine.buildVideoStage(
                        context: context,
                        maxWidth: c.maxWidth,
                        maxHeight: c.maxHeight,
                      );
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(color: cs.surface, child: widget.transcript),
            ),
          ],
        );
      },
    );
  }
}

class _ResizeSplitter extends StatelessWidget {
  const _ResizeSplitter({
    required this.hitWidth,
    required this.hovered,
    required this.onHover,
    required this.onDragDelta,
    required this.onDragEnd,
    required this.semanticLabel,
  });

  final double hitWidth;
  final bool hovered;
  final ValueChanged<bool> onHover;
  final ValueChanged<double> onDragDelta;
  final VoidCallback onDragEnd;
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
          onHorizontalDragEnd: (_) => onDragEnd(),
          child: Tooltip(
            message: semanticLabel,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                width: hovered ? 4 : 3,
                height: 88,
                decoration: BoxDecoration(
                  color: hovered
                      ? cs.outline.withValues(alpha: 0.65)
                      : cs.outline.withValues(alpha: 0.25),
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
