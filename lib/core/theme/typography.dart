/// Typography tokens — **Aurora** type system (ADR-0089).
///
/// - **Geist** for all UI (body, labels, buttons, nav) — crisp, neutral,
///   excellent tabular figures.
/// - **Instrument Serif** for editorial display titles (page heroes, hero
///   numbers) — the signature voice. Regular weight only; never embolden.
/// - **Geist Mono** for timestamps, durations, and scores.
/// - Transcript reading keeps **Source Serif 4** (runtime toggle via
///   [TranscriptTypographyTokens]).
///
/// CJK falls back to installed platform faces (PingFang / YaHei / Noto CJK)
/// so Chinese UI renders natively without extra font downloads.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Installed-platform CJK sans faces, in preference order. Names that are not
/// present on a platform are skipped by the engine at no cost.
const List<String> kCjkSansFallbacks = [
  'PingFang SC',
  'Hiragino Sans GB',
  'Microsoft YaHei UI',
  'Microsoft YaHei',
  'Noto Sans CJK SC',
  'Source Han Sans SC',
];

/// Installed-platform CJK serif faces for display titles.
const List<String> kCjkSerifFallbacks = [
  'Songti SC',
  'Noto Serif CJK SC',
  'Source Han Serif SC',
  'STSong',
];

/// CJK fallbacks so Windows does not substitute low-quality system fonts.
List<String> _transcriptCjkSerifFallbacks() => [
  GoogleFonts.notoSerifKr().fontFamily,
  GoogleFonts.notoSerifSc().fontFamily,
  GoogleFonts.notoSerifJp().fontFamily,
].whereType<String>().toList();

List<String> _transcriptCjkSansFallbacks() => [
  GoogleFonts.notoSansKr().fontFamily,
  GoogleFonts.notoSansSc().fontFamily,
  GoogleFonts.notoSansJp().fontFamily,
  GoogleFonts.geist().fontFamily,
].whereType<String>().toList();

TextStyle _withCjkFallbacks(TextStyle style, {required bool serif}) {
  return style.copyWith(
    fontFamilyFallback: serif
        ? _transcriptCjkSerifFallbacks()
        : _transcriptCjkSansFallbacks(),
  );
}

TextStyle? _ui(TextStyle? s) => s?.copyWith(
  fontFamilyFallback: [...?s.fontFamilyFallback, ...kCjkSansFallbacks],
);

TextStyle _display(
  TextStyle? base, {
  required double size,
  required double height,
  required double letterSpacing,
}) {
  final style = GoogleFonts.instrumentSerif(
    fontSize: size,
    fontWeight: FontWeight.w400,
    height: height,
    letterSpacing: letterSpacing,
    color: base?.color,
  );
  return style.copyWith(
    fontFamilyFallback: [...?style.fontFamilyFallback, ...kCjkSerifFallbacks],
  );
}

/// Editorial display style at an arbitrary [size] — for hero numbers and
/// one-off display moments outside the [TextTheme] scale.
///
/// Derived from the active theme's `displaySmall` (Instrument Serif under
/// [buildBaseTextTheme]) so widgets never fetch fonts themselves. Regular
/// weight only: the face ships no bold.
TextStyle enjoyDisplayStyle(
  BuildContext context, {
  required double size,
  Color? color,
  double height = 1.05,
  double? letterSpacing,
}) {
  final base = Theme.of(context).textTheme.displaySmall ?? const TextStyle();
  return base.copyWith(
    fontSize: size,
    fontWeight: FontWeight.w400,
    height: height,
    letterSpacing: letterSpacing ?? -size * 0.018,
    color: color,
  );
}

/// Tabular mono numerals (Geist Mono under the Aurora theme) for timers,
/// durations, and scores. Derived from [TranscriptTypographyTokens.monoStyle]
/// when present so widgets never fetch fonts themselves.
TextStyle enjoyMonoStyle(
  BuildContext context, {
  double size = 12,
  FontWeight weight = FontWeight.w500,
  Color? color,
  double letterSpacing = 0,
}) {
  final base =
      Theme.of(context).extension<TranscriptTypographyTokens>()?.monoStyle ??
      const TextStyle();
  return base.copyWith(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// Builds the base [TextTheme]: Instrument Serif display + Geist UI.
TextTheme buildBaseTextTheme(TextTheme base, ColorScheme scheme) {
  final ui = GoogleFonts.geistTextTheme(
    base,
  ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

  return ui.copyWith(
    displayLarge: _display(
      ui.displayLarge,
      size: 56,
      height: 1.0,
      letterSpacing: -1.2,
    ),
    displayMedium: _display(
      ui.displayMedium,
      size: 44,
      height: 1.04,
      letterSpacing: -0.9,
    ),
    displaySmall: _display(
      ui.displaySmall,
      size: 38,
      height: 1.08,
      letterSpacing: -0.7,
    ),
    headlineLarge: _display(
      ui.headlineLarge,
      size: 30,
      height: 1.12,
      letterSpacing: -0.5,
    ),
    headlineMedium: _ui(
      ui.headlineMedium?.copyWith(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        height: 1.22,
        letterSpacing: -0.45,
      ),
    ),
    headlineSmall: _ui(
      ui.headlineSmall?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.28,
      ),
    ),
    titleLarge: _ui(
      ui.titleLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        height: 1.3,
      ),
    ),
    titleMedium: _ui(
      ui.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.15,
        height: 1.35,
      ),
    ),
    titleSmall: _ui(
      ui.titleSmall?.copyWith(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.05,
        height: 1.35,
      ),
    ),
    bodyLarge: _ui(
      ui.bodyLarge?.copyWith(
        fontSize: 15.5,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        height: 1.55,
      ),
    ),
    bodyMedium: _ui(
      ui.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.05,
        height: 1.5,
      ),
    ),
    bodySmall: _ui(
      ui.bodySmall?.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.45,
      ),
    ),
    labelLarge: _ui(
      ui.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
      ),
    ),
    labelMedium: _ui(
      ui.labelMedium?.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    ),
    labelSmall: _ui(
      ui.labelSmall?.copyWith(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ),
  );
}

/// Theme extension carrying Source Serif 4 styles for transcript reading.
///
/// Widgets that render transcript lines read [TranscriptTypographyTokens.of]
/// and use [bodyStyle] / [secondaryStyle] when the user has enabled
/// serif reading mode.
@immutable
class TranscriptTypographyTokens
    extends ThemeExtension<TranscriptTypographyTokens> {
  const TranscriptTypographyTokens({
    required this.useSerif,
    required this.bodyStyle,
    required this.secondaryStyle,
    required this.timestampStyle,
    this.monoStyle = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      fontFamily: 'monospace',
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    this.displaySerifStyle = const TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.5,
      fontFamily: 'serif',
    ),
  });

  final bool useSerif;
  final TextStyle bodyStyle;
  final TextStyle secondaryStyle;
  final TextStyle timestampStyle;

  /// Monospace / numeric style for timers, durations, scores, and badges.
  final TextStyle monoStyle;

  /// Editorial serif display style for hero & screen titles.
  final TextStyle displaySerifStyle;

  static TranscriptTypographyTokens of(BuildContext context) {
    return Theme.of(context).extension<TranscriptTypographyTokens>() ??
        _fallback(Theme.of(context).textTheme, Theme.of(context).colorScheme);
  }

  static TranscriptTypographyTokens build({
    required bool useSerif,
    required TextTheme base,
    required ColorScheme scheme,
  }) {
    if (useSerif) {
      final serif = GoogleFonts.sourceSerif4TextTheme(
        base,
      ).apply(bodyColor: scheme.onSurface);
      return TranscriptTypographyTokens(
        useSerif: true,
        bodyStyle: _withCjkFallbacks(
          (serif.bodyLarge ?? const TextStyle()).copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            height: 1.65,
            letterSpacing: 0.01,
            color: scheme.onSurface,
          ),
          serif: true,
        ),
        secondaryStyle: _withCjkFallbacks(
          GoogleFonts.notoSansSc(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.55,
            letterSpacing: 0.02,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.88),
          ),
          serif: false,
        ),
        timestampStyle: GoogleFonts.geistMono(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
        ),
        monoStyle: _withCjkFallbacks(
          GoogleFonts.geistMono(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.15,
            color: scheme.onSurface,
          ),
          serif: false,
        ),
        displaySerifStyle: _display(
          null,
          size: 32,
          height: 1.05,
          letterSpacing: -0.6,
        ).copyWith(color: scheme.onSurface),
      );
    }
    return _fallback(base, scheme);
  }

  static TranscriptTypographyTokens _fallback(
    TextTheme base,
    ColorScheme scheme,
  ) {
    return TranscriptTypographyTokens(
      useSerif: false,
      bodyStyle: _withCjkFallbacks(
        (base.bodyLarge ?? const TextStyle()).copyWith(
          fontSize: 16,
          height: 1.6,
          color: scheme.onSurface,
        ),
        serif: false,
      ),
      secondaryStyle: _withCjkFallbacks(
        GoogleFonts.notoSansSc(
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
          height: 1.55,
          letterSpacing: 0.02,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.88),
        ),
        serif: false,
      ),
      timestampStyle: GoogleFonts.geistMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
      ),
      monoStyle: _withCjkFallbacks(
        GoogleFonts.geistMono(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: scheme.onSurface,
        ),
        serif: false,
      ),
      displaySerifStyle: _display(
        null,
        size: 32,
        height: 1.05,
        letterSpacing: -0.6,
      ).copyWith(color: scheme.onSurface),
    );
  }

  @override
  TranscriptTypographyTokens copyWith({
    bool? useSerif,
    TextStyle? bodyStyle,
    TextStyle? secondaryStyle,
    TextStyle? timestampStyle,
    TextStyle? monoStyle,
    TextStyle? displaySerifStyle,
  }) {
    return TranscriptTypographyTokens(
      useSerif: useSerif ?? this.useSerif,
      bodyStyle: bodyStyle ?? this.bodyStyle,
      secondaryStyle: secondaryStyle ?? this.secondaryStyle,
      timestampStyle: timestampStyle ?? this.timestampStyle,
      monoStyle: monoStyle ?? this.monoStyle,
      displaySerifStyle: displaySerifStyle ?? this.displaySerifStyle,
    );
  }

  @override
  TranscriptTypographyTokens lerp(
    covariant ThemeExtension<TranscriptTypographyTokens>? other,
    double t,
  ) {
    if (other is! TranscriptTypographyTokens) return this;
    return TranscriptTypographyTokens(
      useSerif: t < 0.5 ? useSerif : other.useSerif,
      bodyStyle: TextStyle.lerp(bodyStyle, other.bodyStyle, t)!,
      secondaryStyle: TextStyle.lerp(secondaryStyle, other.secondaryStyle, t)!,
      timestampStyle: TextStyle.lerp(timestampStyle, other.timestampStyle, t)!,
      monoStyle: TextStyle.lerp(monoStyle, other.monoStyle, t)!,
      displaySerifStyle: TextStyle.lerp(
        displaySerifStyle,
        other.displaySerifStyle,
        t,
      )!,
    );
  }
}
