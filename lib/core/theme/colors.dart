/// Semantic color tokens — **Aurora** design language.
///
/// Quiet, cool-neutral chrome (porcelain light / midnight dark) with a single
/// luminous iris accent and the logo's blue → violet aurora reserved for
/// signature moments. Contrast targets (WCAG 2.1) are noted per token; see
/// ADR-0089 and docs/features/app-ui.md.
library;

import 'package:flutter/material.dart';

abstract final class AppColors {
  /// Iris fill for light surfaces — white labels 5.8:1, ink on page 5.4:1.
  static const brand = Color(0xFF5B4BE8);

  /// Iris fill tuned for midnight — white labels 4.5:1, ink on page 4.2:1.
  static const brandDark = Color(0xFF6D5DFC);

  /// High-legibility iris ink on midnight (7.9:1 on page).
  static const brandOnDark = Color(0xFFA99BFF);

  /// Iris ink on porcelain (6.5:1 on page).
  static const brandOnLight = Color(0xFF4F3FD6);

  static const onAccent = Color(0xFFFFFFFF);

  /// Soft iris wash (~12% ink) for selected rows, chips, and badges.
  static const accentSoft = Color(0x1F6D5DFC);

  /// Logo aurora stops — mark, Pro badge, goal ring, signature glows.
  static const auroraBlue = Color(0xFF4797F5);
  static const auroraViolet = Color(0xFFA855F7);
  static const auroraPink = Color(0xFFEC6FCF);

  /// Echo fill — coral, white icons ≥ 3.9:1.
  static const echoActive = Color(0xFFE0512B);

  static const echoInkLight = Color(0xFFC2410C);
  static const echoInkDark = Color(0xFFFF8A5C);

  /// Listening-focus / blur practice (teal, distinct from echo + iris).
  static const blurActive = Color(0xFF0F8C80);

  static const scoreGoodLight = Color(0xFF0E8050);
  static const scoreWarnLight = Color(0xFFA35F00);
  static const scoreBadLight = Color(0xFFD02A37);
  static const scoreGoodDark = Color(0xFF3DD68C);
  static const scoreWarnDark = Color(0xFFF5B83D);
  static const scoreBadDark = Color(0xFFFF6369);

  static const scoreGoodContainer = Color(0x243DD68C);
  static const scoreWarnContainer = Color(0x24F5B83D);
  static const scoreBadContainer = Color(0x29FF6369);

  static const intelligenceInkLight = Color(0xFF1D5FD1);
  static const intelligenceInkDark = Color(0xFF6FA8FF);
  static const intelligenceFill = Color(0xFF1F6FE5);

  /// Window canvas behind the sidebar and the floating content panel.
  static const canvasLight = Color(0xFFECECF1);
  static const surfaceLight = Color(0xFFF7F7F9);
  static const surfaceContainerLowestLight = Color(0xFFFFFFFF);
  static const surfaceContainerLowLight = Color(0xFFFBFBFC);
  static const surfaceContainerLight = Color(0xFFF3F3F6);
  static const surfaceContainerHighLight = Color(0xFFEDEDF1);
  static const surfaceContainerHighestLight = Color(0xFFE6E6EC);
  static const onSurfaceLight = Color(0xFF16161D);
  static const mutedLight = Color(0xFF5E5E6E);
  static const faintLight = Color(0xFF8A8A99);
  static const borderLight = Color(0xFFE3E3E9);
  static const borderStrongLight = Color(0xFFCBCBD4);
  static const cardLight = Color(0xFFFFFFFF);
  static const popoverLight = Color(0xFFFFFFFF);
  static const fillLight = Color(0xFFEDEDF2);

  static const gradientStartLight = Color(0xFFF7F7F9);
  static const gradientEndLight = Color(0xFFF3F3F6);

  static const canvasDark = Color(0xFF09090B);
  static const surfaceDark = Color(0xFF111115);
  static const surfaceContainerLowestDark = Color(0xFF0C0C0F);
  static const surfaceContainerLowDark = Color(0xFF141418);
  static const surfaceContainerDark = Color(0xFF18181D);
  static const surfaceContainerHighDark = Color(0xFF1F1F25);
  static const surfaceContainerHighestDark = Color(0xFF27272F);
  static const onSurfaceDark = Color(0xFFEDEDF2);
  static const mutedDark = Color(0xFF9A9AA8);
  static const faintDark = Color(0xFF6C6C7A);
  static const borderDark = Color(0xFF25252C);
  static const borderStrongDark = Color(0xFF383842);
  static const cardDark = Color(0xFF17171C);
  static const popoverDark = Color(0xFF1E1E24);
  static const fillDark = Color(0xFF222229);

  static const gradientStartDark = Color(0xFF111115);
  static const gradientEndDark = Color(0xFF0E0E12);

  static ColorScheme colorScheme(Brightness brightness) {
    final light = brightness == Brightness.light;
    return ColorScheme(
      brightness: brightness,
      primary: light ? brand : brandDark,
      onPrimary: onAccent,
      primaryContainer: light
          ? const Color(0xFFE9E6FD)
          : const Color(0xFF26214D),
      onPrimaryContainer: light ? brandOnLight : brandOnDark,
      secondary: intelligenceFill,
      onSecondary: onAccent,
      secondaryContainer: light
          ? const Color(0xFFE0EBFC)
          : const Color(0xFF142A4D),
      onSecondaryContainer: light ? intelligenceInkLight : intelligenceInkDark,
      tertiary: echoActive,
      onTertiary: onAccent,
      tertiaryContainer: light
          ? const Color(0xFFFCE6DD)
          : const Color(0xFF3F1C10),
      onTertiaryContainer: light ? echoInkLight : echoInkDark,
      error: light ? scoreBadLight : scoreBadDark,
      onError: onAccent,
      errorContainer: light ? const Color(0xFFFBE3E4) : const Color(0xFF3D1518),
      onErrorContainer: light ? scoreBadLight : scoreBadDark,
      surface: light ? surfaceLight : surfaceDark,
      onSurface: light ? onSurfaceLight : onSurfaceDark,
      onSurfaceVariant: light ? mutedLight : mutedDark,
      surfaceDim: light ? canvasLight : canvasDark,
      surfaceBright: light
          ? surfaceContainerLowestLight
          : surfaceContainerHighDark,
      surfaceContainerLowest: light
          ? surfaceContainerLowestLight
          : surfaceContainerLowestDark,
      surfaceContainerLow: light
          ? surfaceContainerLowLight
          : surfaceContainerLowDark,
      surfaceContainer: light ? surfaceContainerLight : surfaceContainerDark,
      surfaceContainerHigh: light
          ? surfaceContainerHighLight
          : surfaceContainerHighDark,
      surfaceContainerHighest: light
          ? surfaceContainerHighestLight
          : surfaceContainerHighestDark,
      outline: light ? borderStrongLight : borderStrongDark,
      outlineVariant: light ? borderLight : borderDark,
      inverseSurface: light ? onSurfaceLight : onSurfaceDark,
      onInverseSurface: light ? surfaceLight : surfaceDark,
      inversePrimary: light ? brandOnDark : brand,
      scrim: const Color(0xFF050507),
      shadow: const Color(0xFF050507),
    );
  }
}
