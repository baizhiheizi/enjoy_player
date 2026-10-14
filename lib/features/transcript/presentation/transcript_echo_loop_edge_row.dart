/// The line just outside the Echo loop, drawn as a dashed “+ line” row that
/// adds it to the loop, with “−” beside it to drop the loop's nearest line
/// (canvas v30, D6.2).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/transcript/transcript_lens_metrics.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_tooltip_label.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'transcript_markup.dart';

enum EchoLoopEdge { above, below }

class EchoLoopEdgeRow extends ConsumerWidget {
  const EchoLoopEdgeRow({
    required this.line,
    required this.edge,
    required this.canDrop,
    super.key,
  });

  final TranscriptLine line;
  final EchoLoopEdge edge;

  /// False when the loop is a single line (nothing to drop).
  final bool canDrop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final metrics = TranscriptLensMetrics.of(context);
    final typography = TranscriptTypographyTokens.of(context);
    final above = edge == EchoLoopEdge.above;
    final interactions = ref.read(playerInteractionsProvider);

    final addLabel = above
        ? l10n.hotkeysDescExpandEchoBackward
        : l10n.hotkeysDescExpandEchoForward;
    final dropLabel = above
        ? l10n.hotkeysDescShrinkEchoBackward
        : l10n.hotkeysDescShrinkEchoForward;
    final addTip = hotkeyTooltipLabel(
      ref,
      above ? 'player.expandEchoBackward' : 'player.expandEchoForward',
      addLabel,
    );
    final dropTip = hotkeyTooltipLabel(
      ref,
      above ? 'player.shrinkEchoBackward' : 'player.shrinkEchoForward',
      dropLabel,
    );

    final add = Tooltip(
      message: addTip,
      child: EnjoyPressable(
        key: ValueKey('echo-edge-add-${edge.name}'),
        onTap: () => above
            ? interactions.expandEchoBackward()
            : interactions.expandEchoForward(),
        borderRadius: BorderRadius.circular(12),
        pressedScale: 0.99,
        washColor: t.sunk,
        semanticsLabel: addLabel,
        child: CustomPaint(
          painter: _DashedRRectPainter(color: t.shape, radius: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: t.youSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(EnjoyIcons.add, size: 12, color: t.youInk),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      line.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.bodyStyle.copyWith(
                        fontSize: metrics.isPhone ? 15 : 16,
                        height: 1.3,
                        color: t.ink3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final drop = Tooltip(
      message: dropTip,
      child: Opacity(
        opacity: canDrop ? 1 : 0.38,
        child: EnjoyPressable(
          key: ValueKey('echo-edge-drop-${edge.name}'),
          onTap: canDrop
              ? () => above
                    ? interactions.shrinkEchoBackward()
                    : interactions.shrinkEchoForward()
              : null,
          borderRadius: BorderRadius.circular(12),
          pressedScale: 0.94,
          washColor: t.youSoft,
          semanticsLabel: dropLabel,
          child: Container(
            width: 40,
            height: 40,
            decoration: ShapeDecoration(
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: t.youLine),
              ),
            ),
            child: Icon(EnjoyIcons.minus, size: 14, color: t.youInk),
          ),
        ),
      ),
    );

    return Padding(
      padding: metrics.contextPadding.copyWith(
        top: above ? 16 : 8,
        bottom: above ? 0 : 4,
      ),
      child: Row(
        children: [
          if (metrics.timeInGutter) ...[
            SizedBox(
              width: metrics.gutterWidth,
              child: Text(
                formatTranscriptTimestampMs(line.startMs),
                textAlign: TextAlign.end,
                style: typography.timestampStyle.copyWith(
                  fontSize: metrics.timeFontSize,
                  color: t.ink3,
                ),
              ),
            ),
            SizedBox(width: metrics.gutterGap),
          ],
          Expanded(child: add),
          const SizedBox(width: 10),
          drop,
        ],
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.5),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + _dash), paint);
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}
