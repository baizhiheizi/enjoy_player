/// Aurora avatar, tier badge, and keycap primitives.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

/// Circular avatar: network image, else initials on an aurora-tinted disc.
class EnjoyAvatar extends StatelessWidget {
  const EnjoyAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 32,
    this.ring = false,
  });

  final String name;
  final String? imageUrl;
  final double size;

  /// Hairline ring (for overlapping stacks on busy backgrounds).
  final bool ring;

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return (parts[0].characters.first + parts[1].characters.first)
          .toUpperCase();
    }
    return trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final url = imageUrl;
    final hasImage = url != null && url.isNotEmpty;
    final seed = name.codeUnits.fold<int>(0, (a, b) => a + b);
    final hueShift = (seed % 5) / 5;
    final start = Color.lerp(t.auroraStart, t.auroraEnd, hueShift)!;
    final end = Color.lerp(t.auroraEnd, const Color(0xFFEC6FCF), hueShift)!;

    final Widget face = hasImage
        ? CachedNetworkImage(
            imageUrl: url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            memCacheWidth: (size * 3).round(),
            errorWidget: (_, _, _) => _initialsFace(start, end),
            placeholder: (_, _) => _initialsFace(start, end),
          )
        : _initialsFace(start, end);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: ring ? Border.all(color: cs.surface, width: 2) : null,
      ),
      child: ClipOval(child: face),
    );
  }

  Widget _initialsFace(Color start, Color end) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [start, end],
        ),
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w600,
            height: 1,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

/// Small aurora-gradient pill for paid tiers ("Pro", "Lite").
class EnjoyTierBadge extends StatelessWidget {
  const EnjoyTierBadge({super.key, required this.label, this.muted = false});

  final String label;

  /// Neutral (non-gradient) treatment for lower tiers.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: ShapeDecoration(
        gradient: muted ? null : t.aurora,
        color: muted ? t.fill : null,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: muted ? cs.onSurfaceVariant : Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          height: 1.3,
        ),
      ),
    );
  }
}

/// Keyboard shortcut keycap (e.g. `⌘K`, `Ctrl F`).
class EnjoyKeycap extends StatelessWidget {
  const EnjoyKeycap({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: ShapeDecoration(
        color: cs.onSurface.withValues(alpha: 0.05),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(t.radiusXs - 1),
          side: BorderSide(color: t.hairline),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: t.textFaint,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }
}
