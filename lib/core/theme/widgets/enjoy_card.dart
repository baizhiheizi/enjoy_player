/// Aurora card surface — continuous corners, hairline outline, and depth that
/// reads as light (soft ambient shadow on porcelain, a lit top edge on
/// midnight) instead of Material elevation.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

class EnjoyCard extends StatelessWidget {
  const EnjoyCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.color,
    this.elevated = true,
    this.clip = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// Corner radius; defaults to [EnjoyThemeTokens.radiusLg].
  final double? radius;

  /// Fill; defaults to [EnjoyThemeTokens.card].
  final Color? color;

  /// Resting ambient shadow (light) — set false for nested / flat cards.
  final bool elevated;

  final bool clip;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return DecoratedBox(
      decoration: enjoyCardDecoration(
        context,
        radius: radius,
        color: color,
        elevated: elevated,
      ),
      child: ClipRSuperellipse(
        borderRadius: BorderRadius.circular(radius ?? t.radiusLg),
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        child: Material(
          type: MaterialType.transparency,
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    );
  }
}

/// Shared card decoration so bespoke surfaces (hero cards, insight tiles)
/// match [EnjoyCard] exactly.
ShapeDecoration enjoyCardDecoration(
  BuildContext context, {
  double? radius,
  Color? color,
  bool elevated = true,
  Gradient? gradient,
}) {
  final t = EnjoyThemeTokens.of(context);
  final light = Theme.of(context).brightness == Brightness.light;
  return ShapeDecoration(
    color: gradient == null ? (color ?? t.card) : null,
    gradient: gradient,
    shape: RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(radius ?? t.radiusLg),
      side: BorderSide(color: t.hairline.withValues(alpha: light ? 1 : 0.9)),
    ),
    shadows: elevated ? t.shadowCard : const [],
  );
}
