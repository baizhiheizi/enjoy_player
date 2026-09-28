/// Ambient backdrops — the Aurora canvas and the player's artwork tint.
///
/// [AppBackground] paints the page color with a soft **aurora glow** (logo
/// blue → violet) pooled at the top edge: the signature light of the design
/// language. [PlayerAmbientBackdrop] overlays the artwork-derived tint on
/// player screens.
library;

import 'package:flutter/material.dart';

import '../enjoy_tokens.dart';

/// Wraps [child] in the page background with the top aurora glow.
class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.color,
    this.glow = true,
  });

  final Widget child;

  /// Base fill (defaults to the page surface).
  final Color? color;

  /// Paint the aurora glow along the top edge.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: color ?? cs.surface,
      child: glow
          ? Stack(
              fit: StackFit.expand,
              children: [
                const Positioned.fill(
                  child: IgnorePointer(child: AuroraGlow()),
                ),
                child,
              ],
            )
          : child,
    );
  }
}

/// Two soft radial pools of the aurora stops, fading out ~320px down.
///
/// Static paint (no blur filters) so it is effectively free; it sits behind
/// scrolling content like a stage light.
class AuroraGlow extends StatelessWidget {
  const AuroraGlow({super.key, this.intensity = 1});

  /// 0…1 multiplier (player / immersive surfaces dim it).
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final light = Theme.of(context).brightness == Brightness.light;
    final a = (light ? 0.075 : 0.11) * intensity;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 800.0;
        final h = (w * 0.42).clamp(220.0, 360.0);
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: h,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.75, -1.25),
                  radius: 1.1,
                  colors: [
                    t.auroraStart.withValues(alpha: a),
                    t.auroraStart.withValues(alpha: 0),
                  ],
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.7, -1.35),
                    radius: 1.2,
                    colors: [
                      t.auroraEnd.withValues(alpha: a * 1.1),
                      t.auroraEnd.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
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
