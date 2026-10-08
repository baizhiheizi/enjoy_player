/// Deterministic generated cover — the Duet logo-plane recipe
/// (docs/design/duet/tokens.json → generatedCover, ADR-0093).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/widgets/enjoy_logo.dart';

/// Accent color for a seed — the palette's gradient start.
Color generativeAccentForSeed(String seed) =>
    coverPaletteForSeed(seed).gradientStart;

class CoverPalette {
  const CoverPalette({
    required this.background,
    required this.gradientStart,
    required this.gradientEnd,
  });

  final Color background;
  final Color gradientStart;
  final Color gradientEnd;
}

/// The eight generated-cover palettes
/// (tokens.json → generatedCover.palettes): background, gradient start,
/// gradient end.
const List<(Color, Color, Color)> kGeneratedCoverPalettes = [
  (Color(0xFF15203A), Color(0xFF4797F5), Color(0xFFA855F7)),
  (Color(0xFF1E1636), Color(0xFFA855F7), Color(0xFFF0ABFC)),
  (Color(0xFF0B2E2D), Color(0xFF14B8A6), Color(0xFFA7F3D0)),
  (Color(0xFF2A1F14), Color(0xFFF59E0B), Color(0xFFFDE68A)),
  (Color(0xFF141C2B), Color(0xFF3B82F6), Color(0xFFA5B4FC)),
  (Color(0xFF2B1424), Color(0xFFEC4899), Color(0xFFFBCFE8)),
  (Color(0xFF17251A), Color(0xFF65A30D), Color(0xFFD9F99D)),
  (Color(0xFF1F1A2E), Color(0xFF6366F1), Color(0xFFC4B5FD)),
];

/// FNV-1a over the whole id — ids that share a prefix still spread.
@visibleForTesting
int coverHash(String seed) {
  var h = 0x811c9dc5;
  for (final unit in seed.codeUnits) {
    h ^= unit;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

CoverPalette coverPaletteForSeed(String seed) {
  final (background, start, end) =
      kGeneratedCoverPalettes[coverHash(seed) % kGeneratedCoverPalettes.length];
  return CoverPalette(
    background: background,
    gradientStart: start,
    gradientEnd: end,
  );
}

/// Full-bleed cover: one palette background + the logo's three planes,
/// scaled and offset per seed so the mark crops past the frame.
class GenerativeMediaCover extends StatelessWidget {
  const GenerativeMediaCover({
    super.key,
    required this.seed,
    required this.isVideo,
  });

  final String seed;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GeneratedCoverPainter(seed: seed));
  }
}

class _GeneratedCoverPainter extends CustomPainter {
  _GeneratedCoverPainter({required this.seed})
    : spec = coverPaletteForSeed(seed);

  final String seed;
  final CoverPalette spec;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = spec.background);

    final h = coverHash(seed);
    final scaleJitter = 0.78 + ((h % 100) / 100) * (1.20 - 0.78);
    final markUnit = size.longestSide / 60;
    final markSize = kLogoMarkViewBox.width * markUnit * scaleJitter;
    final offsetX =
        ((h >> 8) % 100) / 100 * math.max(0, size.width - markSize * 0.55);
    final offsetY =
        ((h >> 16) % 100) / 100 * math.max(0, size.height - markSize * 0.55);

    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [spec.gradientStart, spec.gradientEnd],
    ).createShader(rect);

    paintLogoMarkPlanes(
      canvas,
      destination: Rect.fromLTWH(offsetX, offsetY, markSize, markSize),
      shader: shader,
    );
  }

  @override
  bool shouldRepaint(covariant _GeneratedCoverPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
