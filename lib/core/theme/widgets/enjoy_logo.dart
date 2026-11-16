/// Enjoy brand mark — gradient SVG, no chrome.
library;

import 'dart:math' as math;

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

/// Builds the outer boundary of a triangle expanded outward by [strokeRadius]
/// with circular joins, matching fill + round-stroke without `saveLayer`.
Path roundedExpandedTrianglePath(List<Offset> points, double strokeRadius) {
  if (points.length != 3 || strokeRadius <= 0) {
    return Path()..addPolygon(points, true);
  }
  final a = points[0];
  var b = points[1];
  var c = points[2];
  final cross = (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);
  if (cross == 0) {
    return Path()..addPolygon(points, true);
  }
  if (cross < 0) {
    final tmp = b;
    b = c;
    c = tmp;
  }
  final verts = <Offset>[a, b, c];
  final normals = <Offset>[];
  for (var i = 0; i < 3; i++) {
    final p0 = verts[i];
    final p1 = verts[(i + 1) % 3];
    final dx = p1.dx - p0.dx;
    final dy = p1.dy - p0.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) {
      return Path()..addPolygon(points, true);
    }
    normals.add(Offset((dy / len) * strokeRadius, (-dx / len) * strokeRadius));
  }
  final r = Radius.circular(strokeRadius);
  final path = Path()
    ..moveTo(verts[0].dx + normals[0].dx, verts[0].dy + normals[0].dy);
  for (var i = 0; i < 3; i++) {
    final next = (i + 1) % 3;
    final edgeEnd = verts[next] + normals[i];
    final nextStart = verts[next] + normals[next];
    path
      ..lineTo(edgeEnd.dx, edgeEnd.dy)
      ..arcToPoint(nextStart, radius: r, clockwise: true);
  }
  path.close();
  return path;
}

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
  final strokeRadius = 2.5 * scale;
  final paint = Paint()..shader = shader;

  for (final (points, layerOpacity) in kLogoMarkPlanes) {
    final alpha = (markOpacity * layerOpacity).clamp(0.0, 1.0);
    if (alpha <= 0) continue;
    final scaled = <Offset>[
      for (final p in points)
        Offset(
          (p.dx - kLogoMarkViewBox.left) * scale,
          (p.dy - kLogoMarkViewBox.top) * scale + dy,
        ),
    ];
    final path = roundedExpandedTrianglePath(scaled, strokeRadius);
    paint.color = Colors.white.withValues(alpha: alpha);
    canvas.drawPath(path, paint);
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
