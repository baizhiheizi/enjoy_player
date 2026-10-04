/// Ambient backdrops — the flat ground and the player's artwork tint.
///
/// [AppBackground] paints the page color only (Duet ground is flat,
/// ADR-0091). [PlayerAmbientBackdrop] overlays the artwork-derived tint on
/// player screens until the player rebuild removes it (D3.1).
library;

import 'package:flutter/material.dart';

/// Wraps [child] in the flat page background.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.color});

  final Widget child;

  /// Base fill (defaults to the ground surface).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(color: color ?? cs.surface, child: child);
  }
}

/// Legacy aurora glow, painted nothing in Duet. The sign-in stage still
/// mounts it until its rebuild (D4.7); the class and every call go away
/// then.
class AuroraGlow extends StatelessWidget {
  const AuroraGlow({super.key, this.intensity = 1});

  /// 0…1 multiplier — ignored.
  final double intensity;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Overlays a soft ambient tint from [accentColor] on top of the scaffold
/// background. Used in the expanded player and audio player layout.
class PlayerAmbientBackdrop extends StatelessWidget {
  const PlayerAmbientBackdrop({
    super.key,
    required this.child,
    this.accentColor,
    this.intensity = 0.09,
  });

  final Widget child;

  /// Artwork dominant color. When null, no tint overlay is applied.
  final Color? accentColor;

  /// Opacity of the ambient tint overlay.
  final double intensity;

  @override
  Widget build(BuildContext context) {
    if (accentColor == null) return child;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -1.1),
                  radius: 1.4,
                  colors: [
                    accentColor!.withValues(alpha: intensity),
                    accentColor!.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
