/// Editorial empty-state primitive (Aurora).
///
/// A softly lit icon orb, a serif title, a measured line of copy, and up to
/// two actions — centered with generous breathing room.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';

import '../enjoy_tokens.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.actionLabel,
    this.secondaryAction,
    this.secondaryActionLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? action;
  final String? actionLabel;
  final VoidCallback? secondaryAction;
  final String? secondaryActionLabel;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final hasPrimary = action != null && actionLabel != null;
    final hasSecondary =
        secondaryAction != null && secondaryActionLabel != null;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: t.space32,
          vertical: t.space40,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EnjoyIconOrb(icon: icon),
              SizedBox(height: t.space24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: enjoyDisplayStyle(
                  context,
                  size: 28,
                  color: cs.onSurface,
                ),
              ),
              SizedBox(height: t.space8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
              if (hasPrimary || hasSecondary) ...[
                SizedBox(height: t.space24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: t.space8,
                  runSpacing: t.space8,
                  children: [
                    if (hasPrimary)
                      EnjoyButton.primary(
                        onPressed: action,
                        child: Text(actionLabel!),
                      ),
                    if (hasSecondary)
                      EnjoyButton.secondary(
                        onPressed: secondaryAction,
                        child: Text(secondaryActionLabel!),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A glyph floating in a soft aurora-lit disc with a faint halo ring.
class EnjoyIconOrb extends StatelessWidget {
  const EnjoyIconOrb({super.key, required this.icon, this.size = 76});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final light = Theme.of(context).brightness == Brightness.light;
    return SizedBox(
      width: size * 1.5,
      height: size * 1.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  t.auroraEnd.withValues(alpha: light ? 0.14 : 0.20),
                  t.auroraStart.withValues(alpha: 0),
                ],
              ),
            ),
            child: SizedBox(width: size * 1.5, height: size * 1.5),
          ),
          Container(
            width: size,
            height: size,
            decoration: ShapeDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    t.auroraStart.withValues(alpha: light ? 0.12 : 0.22),
                    t.card,
                  ),
                  Color.alphaBlend(
                    t.auroraEnd.withValues(alpha: light ? 0.14 : 0.26),
                    t.card,
                  ),
                ],
              ),
              shape: CircleBorder(
                side: BorderSide(
                  color: light
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              shadows: t.shadowCard,
            ),
            child: Icon(icon, size: size * 0.4, color: t.accentInk),
          ),
        ],
      ),
    );
  }
}
