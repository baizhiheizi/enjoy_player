import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The four `you` corner brackets framing the echo loop block.
class EchoLoopBrackets extends CustomPainter {
  EchoLoopBrackets({required this.color, this.arm = 20, this.radius = 10});

  final Color color;
  final double arm;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 2.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final w = size.width;
    final h = size.height;

    final topLeft = Path()
      ..moveTo(0, arm)
      ..lineTo(0, radius)
      ..arcToPoint(Offset(radius, 0), radius: Radius.circular(radius))
      ..lineTo(arm, 0);
    final topRight = Path()
      ..moveTo(w - arm, 0)
      ..lineTo(w - radius, 0)
      ..arcToPoint(Offset(w, radius), radius: Radius.circular(radius))
      ..lineTo(w, arm);
    final bottomLeft = Path()
      ..moveTo(0, h - arm)
      ..lineTo(0, h - radius)
      ..arcToPoint(
        Offset(radius, h),
        radius: Radius.circular(radius),
        clockwise: false,
      )
      ..lineTo(arm, h);
    final bottomRight = Path()
      ..moveTo(w - arm, h)
      ..lineTo(w - radius, h)
      ..arcToPoint(
        Offset(w, h - radius),
        radius: Radius.circular(radius),
        clockwise: false,
      )
      ..lineTo(w, h - arm);

    canvas
      ..drawPath(topLeft, paint)
      ..drawPath(topRight, paint)
      ..drawPath(bottomLeft, paint)
      ..drawPath(bottomRight, paint);
  }

  @override
  bool shouldRepaint(EchoLoopBrackets oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.arm != arm ||
      oldDelegate.radius != radius;
}

/// dot used on the loop label row while a take is being recorded.
class EchoRecordingPulseDot extends StatefulWidget {
  const EchoRecordingPulseDot({required this.color, super.key});

  final Color color;

  @override
  State<EchoRecordingPulseDot> createState() => _EchoRecordingPulseDotState();
}

class _EchoRecordingPulseDotState extends State<EchoRecordingPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_controller.isAnimating && !MediaQuery.disableAnimationsOf(context)) {
      unawaited(_controller.repeat());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final opacity = MediaQuery.disableAnimationsOf(context)
            ? 1.0
            : 0.65 + 0.35 * math.cos(t * 2 * math.pi);
        return Opacity(
          opacity: opacity.clamp(0.3, 1.0),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
