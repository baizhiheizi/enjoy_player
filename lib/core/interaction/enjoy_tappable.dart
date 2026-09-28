/// Shared tappable surfaces: press wash, hover scale, cursor, focus, haptics.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/interaction/haptics.dart';

/// Card / tile tap target — Aurora press (wash + press-scale, no ripple) with
/// optional hover lift. Thin wrapper over [EnjoyPressable].
class EnjoyTappableSurface extends StatelessWidget {
  const EnjoyTappableSurface({
    super.key,
    required this.borderRadius,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.enableHoverScale = true,
    this.hoverScale = 1.01,
    this.semanticsLabel,
    this.excludeSemantics = false,
  });

  final BorderRadius borderRadius;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enableHoverScale;
  final double hoverScale;
  final String? semanticsLabel;
  final bool excludeSemantics;

  @override
  Widget build(BuildContext context) {
    return EnjoyPressable(
      borderRadius: borderRadius,
      onTap: onTap,
      onLongPress: onLongPress,
      hoverScale: enableHoverScale ? hoverScale : 1,
      semanticsLabel: semanticsLabel,
      excludeSemantics: excludeSemantics,
      child: child,
    );
  }
}

/// Icon control with haptic on press (use for custom icon rows; prefer [IconButton] + haptic for a11y).
class EnjoyTappableIcon extends StatelessWidget {
  const EnjoyTappableIcon({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.iconSize = 24,
    this.visualDensity = VisualDensity.standard,
    this.style,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? semanticLabel;
  final double iconSize;
  final VisualDensity visualDensity;
  final ButtonStyle? style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: iconSize, color: color),
      visualDensity: visualDensity,
      style: style,
      onPressed: onPressed == null
          ? null
          : () {
              Haptics.selection(context);
              onPressed!();
            },
    );
    if (semanticLabel == null) return button;
    return Semantics(label: semanticLabel, button: true, child: button);
  }
}
