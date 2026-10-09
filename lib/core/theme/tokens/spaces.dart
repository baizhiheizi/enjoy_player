part of '../enjoy_tokens.dart';

final class _SpaceTokens {
  const _SpaceTokens({
    required this.space4,
    required this.space8,
    required this.space12,
    required this.space16,
    required this.space20,
    required this.space24,
    required this.space32,
    required this.space40,
    required this.space48,
    required this.pageGutterCompact,
    required this.pageGutter,
    required this.desktopGutter,
    required this.marginWidth,
    required this.gutter,
    required this.gutterPhone,
  });

  factory _SpaceTokens.build() => const _SpaceTokens(
    space4: 4,
    space8: 8,
    space12: 12,
    space16: 16,
    space20: 20,
    space24: 24,
    space32: 32,
    space40: 40,
    space48: 48,
    pageGutterCompact: 16,
    pageGutter: 40,
    desktopGutter: 24,
    marginWidth: 340,
    gutter: 40,
    gutterPhone: 16,
  );

  final double space4;
  final double space8;
  final double space12;
  final double space16;
  final double space20;
  final double space24;
  final double space32;
  final double space40;
  final double space48;

  /// Horizontal gutter when pane width is below [breakpointCompact].
  final double pageGutterCompact;

  /// Default horizontal gutter for page content (browse + capped columns).
  final double pageGutter;

  /// Horizontal inset for wide layouts (sidebar + content rhythm).
  final double desktopGutter;
  final double marginWidth;
  final double gutter;
  final double gutterPhone;

  _SpaceTokens copyWith({
    double? space4,
    double? space8,
    double? space12,
    double? space16,
    double? space20,
    double? space24,
    double? space32,
    double? space40,
    double? space48,
    double? pageGutterCompact,
    double? pageGutter,
    double? desktopGutter,
    double? marginWidth,
    double? gutter,
    double? gutterPhone,
  }) {
    return _SpaceTokens(
      space4: space4 ?? this.space4,
      space8: space8 ?? this.space8,
      space12: space12 ?? this.space12,
      space16: space16 ?? this.space16,
      space20: space20 ?? this.space20,
      space24: space24 ?? this.space24,
      space32: space32 ?? this.space32,
      space40: space40 ?? this.space40,
      space48: space48 ?? this.space48,
      pageGutterCompact: pageGutterCompact ?? this.pageGutterCompact,
      pageGutter: pageGutter ?? this.pageGutter,
      desktopGutter: desktopGutter ?? this.desktopGutter,
      marginWidth: marginWidth ?? this.marginWidth,
      gutter: gutter ?? this.gutter,
      gutterPhone: gutterPhone ?? this.gutterPhone,
    );
  }

  _SpaceTokens lerp(_SpaceTokens other, double t) {
    return _SpaceTokens(
      space4: lerpDouble(space4, other.space4, t)!,
      space8: lerpDouble(space8, other.space8, t)!,
      space12: lerpDouble(space12, other.space12, t)!,
      space16: lerpDouble(space16, other.space16, t)!,
      space20: lerpDouble(space20, other.space20, t)!,
      space24: lerpDouble(space24, other.space24, t)!,
      space32: lerpDouble(space32, other.space32, t)!,
      space40: lerpDouble(space40, other.space40, t)!,
      space48: lerpDouble(space48, other.space48, t)!,
      pageGutterCompact: lerpDouble(
        pageGutterCompact,
        other.pageGutterCompact,
        t,
      )!,
      pageGutter: lerpDouble(pageGutter, other.pageGutter, t)!,
      desktopGutter: lerpDouble(desktopGutter, other.desktopGutter, t)!,
      marginWidth: lerpDouble(marginWidth, other.marginWidth, t)!,
      gutter: lerpDouble(gutter, other.gutter, t)!,
      gutterPhone: lerpDouble(gutterPhone, other.gutterPhone, t)!,
    );
  }
}
