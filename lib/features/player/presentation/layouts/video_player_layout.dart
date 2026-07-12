/// Video surface + transcript side panel (desktop-friendly split).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_player_engine.dart';
import 'package:enjoy_player/features/player/application/player_collapse.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:enjoy_player/features/player/application/player_state_providers.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/presentation/widgets/youtube_login_video_frame_button.dart';
import 'package:enjoy_player/features/player/presentation/widgets/youtube_open_in_browser_button.dart';
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

  /// Transcript may use at most this fraction of total width (video keeps >=50%).
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

  /// Whether the mouse hovers the video column (desktop side-by-side only).
  bool _videoColumnHovered = false;

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
                child: MouseRegion(
                  onEnter: (_) => setState(() => _videoColumnHovered = true),
                  onExit: (_) => setState(() => _videoColumnHovered = false),
                  child: SafeArea(
                    top: true,
                    bottom: false,
                    left: false,
                    right: false,
                    child: _VideoColumn(
                      engine: widget.engine,
                      isHovered: _videoColumnHovered,
                      showButtonsInTitleBar: true,
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
                child: _VideoColumn(
                  engine: widget.engine,
                  isHovered: false,
                  showButtonsInTitleBar: false,
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

/// Wraps the video stage with an optional title-bar overlay.
///
/// On desktop (side-by-side) the title bar contains the YT control buttons;
/// on mobile the YT buttons stay at the bottom-right inside the stage.
class _VideoColumn extends StatelessWidget {
  const _VideoColumn({
    required this.engine,
    required this.isHovered,
    required this.showButtonsInTitleBar,
  });

  final PlayerEngine engine;
  final bool isHovered;
  final bool showButtonsInTitleBar;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, c) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _VideoStageWithChrome(
                engine: engine,
                maxWidth: c.maxWidth,
                maxHeight: c.maxHeight,
                showButtons: !showButtonsInTitleBar,
                loginOnTop: showButtonsInTitleBar,
              ),
              _VideoTitleBar(
                isHovered: isHovered,
                showYtButtons: showButtonsInTitleBar,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Title bar overlaid at the top of the video column.
///
/// Visible when paused, buffering, or the mouse hovers the video column
/// (desktop only — [isHovered] is always `false` on mobile).
class _VideoTitleBar extends ConsumerWidget {
  const _VideoTitleBar({required this.isHovered, required this.showYtButtons});

  final bool isHovered;
  final bool showYtButtons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(playerIsPlayingProvider).value ?? false;
    final isBuffering = ref.watch(playerIsBufferingProvider).value ?? false;
    final chrome = ref.watch(playerControllerProvider.select(playbackChromeOf));
    final isVisible = (!isPlaying || isBuffering) || isHovered;

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Align(
        alignment: Alignment.topCenter,
        child: IgnorePointer(
          ignoring: !isVisible,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              left: false,
              right: false,
              child: SizedBox(
                height: kToolbarHeight,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () =>
                          unawaited(collapseExpandedPlayer(ref, context)),
                    ),
                    Expanded(
                      child: Text(
                        chrome?.mediaTitle ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                      ),
                    ),
                    if (showYtButtons) ...[
                      const YoutubeOpenInBrowserButton(),
                      const SizedBox(width: 6),
                      const YoutubeLoginVideoFrameButton(),
                      const SizedBox(width: 12),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoStageWithChrome extends ConsumerWidget {
  const _VideoStageWithChrome({
    required this.engine,
    required this.maxWidth,
    required this.maxHeight,
    required this.loginOnTop,
    this.showButtons = true,
  });

  final PlayerEngine engine;
  final double maxWidth;
  final double maxHeight;

  /// Wide side-by-side: login sits top-right on the video column (share uses
  /// app chrome top-right). Stacked narrow: login sits bottom-right to avoid
  /// the share button over the video top edge.
  final bool loginOnTop;

  /// Whether to render YouTube control buttons inside this stage.
  ///
  /// Should be `false` when the buttons are rendered in [\_VideoTitleBar].
  final bool showButtons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isYoutube = engine is YoutubePlayerEngine;
    return Stack(
      fit: StackFit.expand,
      children: [
        engine.buildVideoStage(
          context: context,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        if (!isYoutube)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: Haptics.wrapTap(
                context,
                () => ref.read(playerControllerProvider.notifier).togglePlay(),
              ),
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
        if (showButtons)
          Positioned(
            top: loginOnTop ? 8 : null,
            bottom: loginOnTop ? null : 12,
            right: 8,
            child: isYoutube
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      YoutubeOpenInBrowserButton(),
                      SizedBox(width: 6),
                      YoutubeLoginVideoFrameButton(),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
      ],
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
