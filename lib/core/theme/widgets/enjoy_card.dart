/// Duet card surface — paper with a line outline and the lift shadow
/// instead of Material elevation.
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

  /// Corner radius; defaults to [EnjoyThemeTokens.radiusCard].
  final double? radius;

  /// Fill; defaults to [EnjoyThemeTokens.paper].
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
        borderRadius: BorderRadius.circular(radius ?? t.radiusCard),
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
  return ShapeDecoration(
    color: gradient == null ? (color ?? t.paper) : null,
    gradient: gradient,
    shape: RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(radius ?? t.radiusCard),
      side: BorderSide(color: t.line),
    ),
    shadows: elevated ? t.shadowCard : const [],
  );
}
