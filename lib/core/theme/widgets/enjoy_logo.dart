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

/// The logo mark's square box in the source SVG's coordinate space.
const Rect kLogoMarkViewBox = Rect.fromLTWH(10, 4, 92, 92);

/// The logo's three planes in [kLogoMarkViewBox] space: back / middle /
/// front, each with its logo-layer opacity (.35 / .65 / 1).
const List<(List<Offset>, double)> kLogoMarkPlanes = [
  (<Offset>[Offset(30, 20), Offset(70, 40), Offset(30, 60)], 0.35),
  (<Offset>[Offset(30, 40), Offset(70, 60), Offset(30, 80)], 0.65),
  (<Offset>[Offset(50, 30), Offset(90, 50), Offset(50, 70)], 1.0),
];

/// Paints the three logo planes into [destination], faded by [markOpacity],
/// with [shader] as fill and outline (round joins, 5-unit stroke). The
/// planes are cropped by whatever clip is active — tiles offset and scale
/// so the mark bleeds past the frame.
void paintLogoMarkPlanes(
  Canvas canvas, {
  required Rect destination,
  required Shader shader,
  double markOpacity = 1,
}) {
  final scale = destination.width / kLogoMarkViewBox.width;
  final dy = (destination.height - kLogoMarkViewBox.height * scale) / 2;
  final stroke = Paint()
    ..shader = shader
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = 5 * scale;

  for (final (points, layerOpacity) in kLogoMarkPlanes) {
    final path = Path()
      ..moveTo(
        (points[0].dx - kLogoMarkViewBox.left) * scale,
        (points[0].dy - kLogoMarkViewBox.top) * scale + dy,
      );
    for (final p in points.skip(1)) {
      path.lineTo(
        (p.dx - kLogoMarkViewBox.left) * scale,
        (p.dy - kLogoMarkViewBox.top) * scale + dy,
      );
    }
    path.close();

    canvas.saveLayer(
      destination,
      Paint()
        ..color = Colors.white.withValues(alpha: markOpacity * layerOpacity),
    );
    canvas.drawPath(path, Paint()..shader = shader);
    canvas.drawPath(path, stroke);
    canvas.restore();
  }
}

/// The logo's three planes at the logo opacity steps, filled with the logo
/// gradient. The shared mark for empty states, the generated covers, and
/// the share poster.
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
  @override
  void paint(Canvas canvas, Size size) {
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.logoStart, AppColors.logoEnd],
    ).createShader(Offset.zero & size);
    paintLogoMarkPlanes(
      canvas,
      destination: Offset.zero & size,
      shader: gradient,
    );
  }

  @override
  bool shouldRepaint(covariant _LogoMarkPainter oldDelegate) => false;
}

/// Resolves the painting shader for the cover painters.
Shader logoMarkShader(Rect rect, List<Color> colors) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: colors,
).createShader(rect);
