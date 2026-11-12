/// Elapsed shadow-recording readout for the echo loop: the fill bar and the
/// tenths-precision caption row beside it.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/widgets/recording_elapsed_ticker.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/widgets/shadow_recording_caption.dart';

class EchoLoopRecordingProgress extends StatefulWidget {
  const EchoLoopRecordingProgress({required this.targetSec, super.key});

  final double targetSec;

  @override
  State<EchoLoopRecordingProgress> createState() =>
      _EchoLoopRecordingProgressState();
}

class _EchoLoopRecordingProgressState extends State<EchoLoopRecordingProgress>
    with
        TickerProviderStateMixin,
        RecordingElapsedTicker<EchoLoopRecordingProgress> {
  @override
  Widget build(BuildContext context) {
    final tok = EnjoyThemeTokens.of(context);

    return Row(
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: LayoutBuilder(
              builder: (context, constraints) => SizedBox(
                height: 4,
                width: constraints.maxWidth,
                child: CustomPaint(
                  painter: _LoopBarPainter(
                    elapsed: elapsedController,
                    targetSec: widget.targetSec,
                    track: tok.youSoft,
                    fill: tok.you,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ShadowRecordingElapsedCaption(
          elapsedTenths: elapsedTenths,
          targetSec: widget.targetSec,
        ),
      ],
    );
  }
}

class _LoopBarPainter extends CustomPainter {
  _LoopBarPainter({
    required this.elapsed,
    required this.targetSec,
    required this.track,
    required this.fill,
  }) : super(repaint: elapsed);

  final Animation<double> elapsed;
  final double targetSec;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = track;
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.height / 2);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);

    final fraction = targetSec > 0
        ? (elapsed.value / targetSec).clamp(0.0, 1.0)
        : 1.0;
    if (fraction <= 0) return;
    paint.color = fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * fraction, size.height),
        radius,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_LoopBarPainter oldDelegate) => false;
}
