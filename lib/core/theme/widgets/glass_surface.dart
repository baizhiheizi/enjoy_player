/// Frosted glass panel (transport bar, floating chrome) — Aurora glass.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';

import '../enjoy_tokens.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    required this.child,
    this.sigma,
    this.padding,
    this.borderRadius = 0,
    this.shape,
    super.key,
  }) : assert(
         shape == null || borderRadius == 0,
         'GlassSurface.shape owns the outline entirely — pass either shape or '
         'borderRadius, never both. A shaped surface that needs rounded '
         'corners should pass a RoundedSuperellipseBorder as its shape.',
       );

  final Widget child;
  final double? sigma;
  final EdgeInsetsGeometry? padding;

  /// Corner radius. `0` keeps the historical square clip used by full-bleed
  /// callers; the floating transport passes [EnjoyThemeTokens.radiusXl].
  /// Mutually exclusive with [shape]: the outline override wins geometry
  /// outright, so combining them trips a debug assert instead of silently
  /// dropping the radius.
  final double borderRadius;

  /// Optional outline override for non-rectangular chrome — the circular
  /// player collapse control passes [CircleBorder]. When null (the default)
  /// the surface clips to a [RoundedSuperellipseBorder] built from
  /// [borderRadius]; when set, [borderRadius] must be `0`. The tint fill,
  /// hairline, and blur sigma always come from [EnjoyThemeTokens].
  final OutlinedBorder? shape;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final blurRaw = sigma ?? t.miniBarBlurSigma;
    final blur = _effectiveTransportBlur(blurRaw);
    final radius = BorderRadius.circular(borderRadius);
    final side = BorderSide(color: t.glassBorder);
    final outline =
        shape?.copyWith(side: side) ??
        RoundedSuperellipseBorder(borderRadius: radius, side: side);

    // No Material wrapper: this adapter only paints decoration + blur.
    // Callers own their Material needs — the back button subtree is a bare
    // SizedBox + Icon (no ink, no inherited text), and the transport bar
    // supplies its own transparent Material inside its child.
    Widget inner = child;

    if (padding != null) {
      inner = Padding(padding: padding!, child: inner);
    }

    if (blur <= 0) {
      return DecoratedBox(
        decoration: ShapeDecoration(
          color: t.popover.withValues(alpha: 0.96),
          shape: outline,
        ),
        child: inner,
      );
    }

    final Widget blurred = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: DecoratedBox(
        decoration: ShapeDecoration(color: t.glassTint, shape: outline),
        child: inner,
      ),
    );

    if (shape != null) {
      return ClipPath(
        clipper: ShapeBorderClipper(shape: outline),
        child: blurred,
      );
    }
    return ClipRSuperellipse(borderRadius: radius, child: blurred);
  }
}

/// Softer blur on Android to reduce GPU overdraw from [BackdropFilter] on transport.
double _effectiveTransportBlur(double sigma) {
  if (sigma <= 0) return sigma;
  if (defaultTargetPlatform == TargetPlatform.android) {
    return sigma > 10 ? 10 : sigma;
  }
  return sigma;
}
