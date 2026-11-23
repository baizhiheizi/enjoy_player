/// Meta-line badges under media card artwork / at row trailing meta.
library;

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';

import '../../enjoy_tokens.dart';

/// Language / metadata chip in [MediaCardRow] meta.
class MediaCardBadge extends StatelessWidget {
  const MediaCardBadge({
    super.key,
    required this.label,
    required this.cs,
    this.onTap,
    this.showLanguageIcon = false,
  });

  final String label;
  final ColorScheme cs;
  final VoidCallback? onTap;
  final bool showLanguageIcon;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final interactive = onTap != null;
    final fg = interactive ? t.brandInk : cs.onSurfaceVariant;
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: ShapeDecoration(
        color: interactive ? t.brandSoft : t.sunk,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLanguageIcon) ...[
            Icon(EnjoyIcons.translate, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (!interactive) return child;
    return EnjoyPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(t.radiusFull),
      pressedScale: 0.95,
      child: child,
    );
  }
}

final RegExp _parenSplitRegExp = RegExp(r'\s*[（(]');

/// Inline language link for a tile's meta line (tap to edit when [onTap]).
class MediaCardMetaLanguage extends StatelessWidget {
  const MediaCardMetaLanguage({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final short = label.split(_parenSplitRegExp).first.trim();
    final text = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(EnjoyIcons.translate, size: 12.5, color: t.ink3),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            short.isEmpty ? label : short,
            semanticsLabel: label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
    if (onTap == null) return Tooltip(message: label, child: text);
    return Tooltip(
      message: label,
      child: EnjoyPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(t.radiusXs),
        pressedScale: 0.96,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: text,
        ),
      ),
    );
  }
}

/// Middle-dot separator for meta lines.
class MediaCardMetaDot extends StatelessWidget {
  const MediaCardMetaDot({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
