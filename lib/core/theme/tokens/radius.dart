part of '../enjoy_tokens.dart';

final class _RadiusTokens {
  const _RadiusTokens({
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.radiusFull,
    required this.radiusXs,
    required this.radius2xl,
    required this.panelRadius,
    required this.radiusKeycap,
    required this.radiusBadge,
    required this.radiusSegmentThumb,
    required this.radiusControl,
    required this.radiusTile,
    required this.radiusCard,
    required this.radiusCardLarge,
    required this.radiusDialog,
    required this.radiusSheet,
  });

  factory _RadiusTokens.build() => const _RadiusTokens(
    radiusSm: 8,
    radiusMd: 12,
    radiusLg: 16,
    radiusXl: 22,
    radiusFull: 999,
    radiusXs: 6,
    radius2xl: 30,
    panelRadius: 0,
    radiusKeycap: 5,
    radiusBadge: 7,
    radiusSegmentThumb: 9,
    radiusControl: 12,
    radiusTile: 14,
    radiusCard: 20,
    radiusCardLarge: 24,
    radiusDialog: 24,
    radiusSheet: 26,
  );

  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;
  final double radiusFull;

  /// Tight radius for tiny badges and keycaps.
  final double radiusXs;

  /// Hero artwork, sheets, and large modal corners.
  final double radius2xl;

  /// Legacy floating content panel corner radius; 0 in Duet.
  final double panelRadius;
  final double radiusKeycap;
  final double radiusBadge;
  final double radiusSegmentThumb;
  final double radiusControl;
  final double radiusTile;
  final double radiusCard;
  final double radiusCardLarge;
  final double radiusDialog;
  final double radiusSheet;

  _RadiusTokens copyWith({
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    double? radiusFull,
    double? radiusXs,
    double? radius2xl,
    double? panelRadius,
    double? radiusKeycap,
    double? radiusBadge,
    double? radiusSegmentThumb,
    double? radiusControl,
    double? radiusTile,
    double? radiusCard,
    double? radiusCardLarge,
    double? radiusDialog,
    double? radiusSheet,
  }) {
    return _RadiusTokens(
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusXl: radiusXl ?? this.radiusXl,
      radiusFull: radiusFull ?? this.radiusFull,
      radiusXs: radiusXs ?? this.radiusXs,
      radius2xl: radius2xl ?? this.radius2xl,
      panelRadius: panelRadius ?? this.panelRadius,
      radiusKeycap: radiusKeycap ?? this.radiusKeycap,
      radiusBadge: radiusBadge ?? this.radiusBadge,
      radiusSegmentThumb: radiusSegmentThumb ?? this.radiusSegmentThumb,
      radiusControl: radiusControl ?? this.radiusControl,
      radiusTile: radiusTile ?? this.radiusTile,
      radiusCard: radiusCard ?? this.radiusCard,
      radiusCardLarge: radiusCardLarge ?? this.radiusCardLarge,
      radiusDialog: radiusDialog ?? this.radiusDialog,
      radiusSheet: radiusSheet ?? this.radiusSheet,
    );
  }

  _RadiusTokens lerp(_RadiusTokens other, double t) {
    return _RadiusTokens(
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t)!,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t)!,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t)!,
      radiusXl: lerpDouble(radiusXl, other.radiusXl, t)!,
      radiusFull: lerpDouble(radiusFull, other.radiusFull, t)!,
      radiusXs: lerpDouble(radiusXs, other.radiusXs, t)!,
      radius2xl: lerpDouble(radius2xl, other.radius2xl, t)!,
      panelRadius: lerpDouble(panelRadius, other.panelRadius, t)!,
      radiusKeycap: lerpDouble(radiusKeycap, other.radiusKeycap, t)!,
      radiusBadge: lerpDouble(radiusBadge, other.radiusBadge, t)!,
      radiusSegmentThumb: lerpDouble(
        radiusSegmentThumb,
        other.radiusSegmentThumb,
        t,
      )!,
      radiusControl: lerpDouble(radiusControl, other.radiusControl, t)!,
      radiusTile: lerpDouble(radiusTile, other.radiusTile, t)!,
      radiusCard: lerpDouble(radiusCard, other.radiusCard, t)!,
      radiusCardLarge: lerpDouble(radiusCardLarge, other.radiusCardLarge, t)!,
      radiusDialog: lerpDouble(radiusDialog, other.radiusDialog, t)!,
      radiusSheet: lerpDouble(radiusSheet, other.radiusSheet, t)!,
    );
  }
}
