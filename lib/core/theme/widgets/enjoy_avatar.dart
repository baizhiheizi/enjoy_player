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

/// Small aurora-gradient pill — the shared surface for every signature pill:
/// tier badges ("Pro", "Lite"), the sidebar Upgrade button, and the tier
/// catalog's "Recommended" / "Current plan" badges.
class EnjoyTierBadge extends StatelessWidget {
  const EnjoyTierBadge({
    super.key,
    required this.label,
    this.muted = false,
    this.leading,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
    this.color,
    this.textColor,
    this.shape = const StadiumBorder(),
  });

  final String label;

  /// Neutral (non-gradient) treatment for lower tiers.
  final bool muted;

  /// Optional leading glyph (e.g. the sparkle on "Recommended").
  final IconData? leading;

  /// Pill padding. Compact badges use the default; tappable pills (the
  /// sidebar Upgrade pill, the tier catalog) scale it up.
  final EdgeInsetsGeometry padding;

  /// Solid fill override — drops the aurora gradient (e.g. "Current plan" on
  /// `secondaryContainer`).
  final Color? color;

  /// Label and leading color. Defaults to white on the aurora, `onSurface`
  /// on a solid [color], and `onSurfaceVariant` when [muted].
  final Color? textColor;

  /// Pill shape — stadium by default. Exposed the same way the lit-fill
  /// decoration takes a shape: one kit surface, any shape, so a non-pill
  /// caller never needs a parallel widget.
  final ShapeBorder shape;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final solid = _resolveSolid(color, muted: muted, fill: t.fill);
    final fg = _resolveFg(
      textColor,
      hasColor: color != null,
      muted: muted,
      cs: cs,
    );
    return Container(
      padding: padding,
      decoration: ShapeDecoration(
        gradient: solid == null ? t.aurora : null,
        color: solid,
        shape: shape,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            Icon(leading, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: fg,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Background fill: an explicit [color], else the muted surface fill, else
  /// null (the aurora gradient paints).
  static Color? _resolveSolid(
    Color? color, {
    required bool muted,
    required Color fill,
  }) => color ?? (muted ? fill : null);

  /// Foreground: a [textColor] override, else `onSurface` on an explicit
  /// [color], `onSurfaceVariant` when muted, white on the aurora.
  ///
  /// Note the deliberate asymmetry with [_resolveSolid]: a muted badge fills
  /// with `t.fill` but keeps the `onSurfaceVariant` label, so this keys off
  /// whether a color override was given, not whether the fill resolved solid.
  static Color _resolveFg(
    Color? override, {
    required bool hasColor,
    required bool muted,
    required ColorScheme cs,
  }) {
    if (override != null) return override;
    if (hasColor) return cs.onSurface;
    if (muted) return cs.onSurfaceVariant;
    return Colors.white;
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
