/// Enjoy brand mark — gradient SVG, no chrome.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EnjoyLogo extends StatelessWidget {
  const EnjoyLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset('assets/logo-light.svg', fit: BoxFit.contain),
    );
  }
}

/// The logo's three planes — back / middle / front at the logo's opacity
/// steps (.35 / .65 / 1) — filled with the logo gradient. The shared mark
/// for empty states, the generated covers, and the share poster.
class EnjoyLogoMark extends StatelessWidget {
  const EnjoyLogoMark({super.key, required this.size, this.opacity = 1});

  final double size;

  /// Fades the whole mark (e.g. a low-opacity empty-state figure).
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(size: Size.square(size), painter: _LogoMarkPainter()),
    );
  }
}

class _LogoMarkPainter extends CustomPainter {
  static const _viewBox = Rect.fromLTWH(10, 4, 92, 92);

  static const _planes = [
    (<Offset>[Offset(30, 20), Offset(70, 40), Offset(30, 60)], 0.35),
    (<Offset>[Offset(30, 40), Offset(70, 60), Offset(30, 80)], 0.65),
    (<Offset>[Offset(50, 30), Offset(90, 50), Offset(50, 70)], 1.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.logoStart, AppColors.logoEnd],
    ).createShader(Offset.zero & size);

    final scale = size.width / _viewBox.width;
    final dy = (size.height - _viewBox.height * scale) / 2;
    final stroke = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 5 * scale;

    for (final (points, layerOpacity) in _planes) {
      final path = Path()
        ..moveTo(
          (points[0].dx - _viewBox.left) * scale,
          (points[0].dy - _viewBox.top) * scale + dy,
        );
      for (final p in points.skip(1)) {
        path.lineTo(
          (p.dx - _viewBox.left) * scale,
          (p.dy - _viewBox.top) * scale + dy,
        );
      }
      path.close();

      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: layerOpacity),
      );
      canvas.drawPath(path, Paint()..shader = gradient);
      canvas.drawPath(path, stroke);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LogoMarkPainter oldDelegate) => false;
}
