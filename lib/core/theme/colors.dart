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

  static const groundLight = Color(0xFFF5F6F8);
  static const paperLight = Color(0xFFFFFFFF);
  static const raisedLight = Color(0xFFFFFFFF);
  static const sunkLight = Color(0xFFEDEFF2);
  static const lineLight = Color(0xFFE3E6EB);
  static const inkLight = Color(0xFF12141A);
  static const ink2Light = Color(0xFF3D4350);
  static const ink3Light = Color(0xFF5E6573);
  static const originalLight = Color(0xFF4797F5);
  static const originalInkLight = Color(0xFF1D64C8);
  static const originalSoftLight = Color(0xFFE9F2FE);
  static const youLight = Color(0xFF8B2FE0);
  static const youInkLight = Color(0xFF7E22CE);
  static const youSoftLight = Color(0xFFF4ECFE);
  static const youLineLight = Color(0xFFD8B4FE);
  static const onYouLight = Color(0xFFFFFFFF);
  static const brandInkLight = Color(0xFF4F46E5);
  static const brandSoftLight = Color(0xFFEEEBFE);
  static const primaryInkLight = Color(0xFF12141A);
  static const onPrimaryInkLight = Color(0xFFFFFFFF);
  static const dangerLight = Color(0xFFB42318);
  static const shapeLight = Color(0xFFDCE0E6);
  static const Color tickLight = Color.fromRGBO(18, 20, 26, 0.26);
  static const Color scrimLight = Color.fromRGBO(18, 20, 26, 0.32);
  static const videoLight = Color(0xFF0B0D11);
  static const vocabNewLight = Color(0xFFC7D2FE);
  static const vocabLearningLight = Color(0xFFA5B4FC);
  static const vocabReviewingLight = Color(0xFF6366F1);
  static const vocabMasteredLight = Color(0xFF3730A3);

  static const groundDark = Color(0xFF0E1014);
  static const paperDark = Color(0xFF16191F);
  static const raisedDark = Color(0xFF1F232B);
  static const sunkDark = Color(0xFF23272F);
  static const lineDark = Color(0xFF2A2F38);
  static const inkDark = Color(0xFFEEF0F4);
  static const ink2Dark = Color(0xFFB8BEC9);
  static const ink3Dark = Color(0xFF8A91A0);
  static const originalDark = Color(0xFF6AAEFF);
  static const originalInkDark = Color(0xFF7DB8FF);
  static const Color originalSoftDark = Color.fromRGBO(90, 162, 255, 0.15);
  static const youDark = Color(0xFF8F55F0);
  static const youInkDark = Color(0xFFC7A0FF);
  static const Color youSoftDark = Color.fromRGBO(143, 85, 240, 0.16);
  static const Color youLineDark = Color.fromRGBO(167, 120, 250, 0.5);
  static const onYouDark = Color(0xFFFFFFFF);
  static const brandInkDark = Color(0xFFB4AFFF);
  static const Color brandSoftDark = Color.fromRGBO(124, 58, 237, 0.2);
  static const primaryInkDark = Color(0xFFEEF0F4);
  static const onPrimaryInkDark = Color(0xFF0E1014);
  static const dangerDark = Color(0xFFFF8A80);
  static const shapeDark = Color(0xFF2C313B);
  static const Color tickDark = Color.fromRGBO(238, 240, 244, 0.28);
  static const Color scrimDark = Color.fromRGBO(0, 0, 0, 0.55);
  static const videoDark = Color(0xFF000000);
  static const vocabNewDark = Color(0xFF312E81);
  static const vocabLearningDark = Color(0xFF4338CA);
  static const vocabReviewingDark = Color(0xFF818CF8);
  static const vocabMasteredDark = Color(0xFFC7D2FE);

  static const brandStart = Color(0xFF2563EB);
  static const brandEnd = Color(0xFF7C3AED);
  static const logoStart = Color(0xFF4797F5);
  static const logoEnd = Color(0xFFA855F7);

  static ColorScheme colorScheme(Brightness brightness) {
    final light = brightness == Brightness.light;
    final brandInk = light ? brandInkLight : brandInkDark;
    final danger = light ? dangerLight : dangerDark;
    final ground = light ? groundLight : groundDark;
    final paper = light ? paperLight : paperDark;
    final raised = light ? raisedLight : raisedDark;
    final sunk = light ? sunkLight : sunkDark;
    final line = light ? lineLight : lineDark;
    final ink = light ? inkLight : inkDark;
    final ink2 = light ? ink2Light : ink2Dark;
    final ink3 = light ? ink3Light : ink3Dark;
    final original = light ? originalLight : originalDark;
    final originalInk = light ? originalInkLight : originalInkDark;
    final originalSoft = light ? originalSoftLight : originalSoftDark;
    final you = light ? youLight : youDark;
    final onYou = light ? onYouLight : onYouDark;
    final youSoft = light ? youSoftLight : youSoftDark;
    final youInk = light ? youInkLight : youInkDark;
    return ColorScheme(
      brightness: brightness,
      primary: brandInk,
      onPrimary: light ? onPrimaryInkLight : onPrimaryInkDark,
      primaryContainer: light ? brandSoftLight : brandSoftDark,
      onPrimaryContainer: brandInk,
      secondary: original,
      onSecondary: onYou,
      secondaryContainer: originalSoft,
      onSecondaryContainer: originalInk,
      tertiary: you,
      onTertiary: onYou,
      tertiaryContainer: youSoft,
      onTertiaryContainer: youInk,
      error: danger,
      onError: onYou,
      errorContainer: danger.withValues(alpha: 0.12),
      onErrorContainer: danger,
      surface: ground,
      onSurface: ink,
      onSurfaceVariant: ink2,
      surfaceDim: ground,
      surfaceBright: paper,
      surfaceContainerLowest: ground,
      surfaceContainerLow: sunk,
      surfaceContainer: sunk,
      surfaceContainerHigh: sunk,
      surfaceContainerHighest: raised,
      outline: ink3,
      outlineVariant: line,
      inverseSurface: ink,
      onInverseSurface: ground,
      inversePrimary: light ? brandInkDark : brandInkLight,
      scrim: light ? scrimLight : scrimDark,
      shadow: const Color(0xFF000000),
    );
  }
}
