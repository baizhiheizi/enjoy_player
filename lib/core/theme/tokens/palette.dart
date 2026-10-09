part of '../enjoy_tokens.dart';

final class _SurfaceColors {
  const _SurfaceColors({
    required this.glassTint,
    required this.glassBorder,
    required this.gradientStart,
    required this.gradientEnd,
    required this.canvas,
    required this.card,
    required this.popover,
    required this.hairline,
    required this.fill,
    required this.textFaint,
    required this.logoStart,
    required this.logoEnd,
    required this.topHighlight,
    required this.ground,
    required this.paper,
    required this.raised,
    required this.sunk,
    required this.line,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.shape,
    required this.tick,
    required this.scrim,
    required this.video,
  });

  factory _SurfaceColors.build({required bool light}) => _SurfaceColors(
    glassTint: light ? AppColors.paperLight : AppColors.paperDark,
    glassBorder: light ? AppColors.lineLight : AppColors.lineDark,
    gradientStart: light ? AppColors.groundLight : AppColors.groundDark,
    gradientEnd: light ? AppColors.groundLight : AppColors.groundDark,
    canvas: light ? AppColors.groundLight : AppColors.groundDark,
    card: light ? AppColors.paperLight : AppColors.paperDark,
    popover: light ? AppColors.raisedLight : AppColors.raisedDark,
    hairline: light ? AppColors.lineLight : AppColors.lineDark,
    fill: light ? AppColors.sunkLight : AppColors.sunkDark,
    textFaint: light ? AppColors.ink3Light : AppColors.ink3Dark,
    logoStart: AppColors.logoStart,
    logoEnd: AppColors.logoEnd,
    topHighlight: Colors.transparent,
    ground: light ? AppColors.groundLight : AppColors.groundDark,
    paper: light ? AppColors.paperLight : AppColors.paperDark,
    raised: light ? AppColors.raisedLight : AppColors.raisedDark,
    sunk: light ? AppColors.sunkLight : AppColors.sunkDark,
    line: light ? AppColors.lineLight : AppColors.lineDark,
    ink: light ? AppColors.inkLight : AppColors.inkDark,
    ink2: light ? AppColors.ink2Light : AppColors.ink2Dark,
    ink3: light ? AppColors.ink3Light : AppColors.ink3Dark,
    shape: light ? AppColors.shapeLight : AppColors.shapeDark,
    tick: light ? AppColors.tickLight : AppColors.tickDark,
    scrim: light ? AppColors.scrimLight : AppColors.scrimDark,
    video: light ? AppColors.videoLight : AppColors.videoDark,
  );

  final Color glassTint;
  final Color glassBorder;
  final Color gradientStart;
  final Color gradientEnd;

  /// Window canvas behind the sidebar and the content area.
  final Color canvas;

  /// Card / grouped-list surface.
  final Color card;

  /// Menus, popovers, dialogs, and sheets.
  final Color popover;

  /// 1px separators and card outlines.
  final Color hairline;

  /// Subtle control fill (search fields, segmented tracks, chips).
  final Color fill;

  /// Tertiary text (timestamps, hints).
  final Color textFaint;

  /// Logo gradient start (original blue).
  final Color logoStart;

  /// Logo gradient end (you violet).
  final Color logoEnd;

  /// Legacy dark-surface lit edge; transparent in Duet.
  final Color topHighlight;

  /// Page and sidebar ground.
  final Color ground;

  /// Cards and content tiles.
  final Color paper;

  /// Menus, popovers, dialogs, and sheets.
  final Color raised;

  /// Sunk control fill (search fields, segmented tracks, chips).
  final Color sunk;

  /// 1px separators, card outlines, and the you-soft boundary.
  final Color line;

  /// Primary text.
  final Color ink;

  /// Secondary text.
  final Color ink2;

  /// Tertiary text (timestamps, hints) — readable in both themes.
  final Color ink3;

  /// Hidden-word shape bars.
  final Color shape;

  /// Sentence-ruler track ticks.
  final Color tick;

  /// Modal and drawer scrims.
  final Color scrim;

  /// Video stage letterbox.
  final Color video;

  _SurfaceColors copyWith({
    Color? glassTint,
    Color? glassBorder,
    Color? gradientStart,
    Color? gradientEnd,
    Color? canvas,
    Color? card,
    Color? popover,
    Color? hairline,
    Color? fill,
    Color? textFaint,
    Color? logoStart,
    Color? logoEnd,
    Color? topHighlight,
    Color? ground,
    Color? paper,
    Color? raised,
    Color? sunk,
    Color? line,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? shape,
    Color? tick,
    Color? scrim,
    Color? video,
  }) {
    return _SurfaceColors(
      glassTint: glassTint ?? this.glassTint,
      glassBorder: glassBorder ?? this.glassBorder,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      canvas: canvas ?? this.canvas,
      card: card ?? this.card,
      popover: popover ?? this.popover,
      hairline: hairline ?? this.hairline,
      fill: fill ?? this.fill,
      textFaint: textFaint ?? this.textFaint,
      logoStart: logoStart ?? this.logoStart,
      logoEnd: logoEnd ?? this.logoEnd,
      topHighlight: topHighlight ?? this.topHighlight,
      ground: ground ?? this.ground,
      paper: paper ?? this.paper,
      raised: raised ?? this.raised,
      sunk: sunk ?? this.sunk,
      line: line ?? this.line,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      shape: shape ?? this.shape,
      tick: tick ?? this.tick,
      scrim: scrim ?? this.scrim,
      video: video ?? this.video,
    );
  }

  _SurfaceColors lerp(_SurfaceColors other, double t) {
    return _SurfaceColors(
      glassTint: Color.lerp(glassTint, other.glassTint, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      card: Color.lerp(card, other.card, t)!,
      popover: Color.lerp(popover, other.popover, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      fill: Color.lerp(fill, other.fill, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      logoStart: Color.lerp(logoStart, other.logoStart, t)!,
      logoEnd: Color.lerp(logoEnd, other.logoEnd, t)!,
      topHighlight: Color.lerp(topHighlight, other.topHighlight, t)!,
      ground: Color.lerp(ground, other.ground, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      sunk: Color.lerp(sunk, other.sunk, t)!,
      line: Color.lerp(line, other.line, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      ink3: Color.lerp(ink3, other.ink3, t)!,
      shape: Color.lerp(shape, other.shape, t)!,
      tick: Color.lerp(tick, other.tick, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      video: Color.lerp(video, other.video, t)!,
    );
  }
}
