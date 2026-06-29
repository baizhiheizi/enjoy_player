/// Semantic color tokens — neutral zinc dark base, logo-aligned blue/purple accent.
/// Dynamic color from artwork is handled separately in dynamic_color/.
library;

import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Echo & feature accents ──────────────────────────────────────────────
  static const echoActive = Color(0xFFE65100);

  // ── Brand — Premium Purple ──────────────────────────────────────────────
  static const brand = Color(0xFF7B61FF);
  static const brandSecondary = Color(0xFF4797F5);

  /// High-legibility primary tint on dark surfaces (text, icons, outlines).
  static const brandOnDark = Color(0xFFB2A1FF);

  // ── Dark surface ramp — zinc-style neutral ──────────────────────────────
  static const surfaceDark = Color(0xFF09090B);
  static const surfaceContainerLowestDark = Color(0xFF000000);
  static const surfaceContainerLowDark = Color(0xFF09090B);
  static const surfaceContainerDark = Color(0xFF18181B);
  static const surfaceContainerHighDark = Color(0xFF27272A);
  static const surfaceContainerHighestDark = Color(0xFF3F3F46);

  // ── Backdrop gradient for non-player routes ────────────────────────────
  static const gradientStartDark = Color(0xFF18181B);
  static const gradientEndDark = Color(0xFF09090B);

  // ── Seed for Material 3 ColorScheme.fromSeed ──────────────────────────
  static const seedBrand = brand;
}
