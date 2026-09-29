/// Circular frosted collapse control matching OpenDesign player `.p-back`.
///
/// Renders through the shared [GlassSurface] adapter (ADR-0018 press
/// primitive): one frosted-chrome recipe — token tint, hairline, and blur —
/// for the transport capsule and this control alike.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/widgets/glass_surface.dart';

class PlayerFrostedBackButton extends StatelessWidget {
  const PlayerFrostedBackButton({
    required this.onPressed,
    this.iconColor,
    super.key,
  });

  final VoidCallback onPressed;

  /// Chevron color. Defaults to [ColorScheme.onSurface] so the glyph stays
  /// legible on the [GlassSurface] tint in both brightnesses.
  final Color? iconColor;

  static const double _size = 38;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: MaterialLocalizations.of(context).backButtonTooltip,
      child: EnjoyPressable(
        onTap: onPressed,
        shape: const CircleBorder(),
        child: GlassSurface(
          shape: const CircleBorder(),
          child: SizedBox(
            width: _size,
            height: _size,
            child: Icon(
              EnjoyIcons.chevronDown,
              color: iconColor ?? Theme.of(context).colorScheme.onSurface,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
