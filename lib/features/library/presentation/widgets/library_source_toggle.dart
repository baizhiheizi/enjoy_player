/// Compact Local / Cloud badge toggle for the Library header title row.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/routing/library_source.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class LibrarySourceToggle extends StatelessWidget {
  const LibrarySourceToggle({
    required this.source,
    required this.onToggle,
    super.key,
  });

  final LibrarySource source;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isCloud = source == LibrarySource.cloud;
    final label = isCloud ? l10n.librarySourceCloud : l10n.librarySourceLocal;
    final tooltip = isCloud
        ? l10n.librarySourceToggleToLocal
        : l10n.librarySourceToggleToCloud;

    return Semantics(
      button: true,
      label: l10n.librarySourceSwitchSemantics,
      value: label,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: EnjoyPressable(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(t.radiusFull),
          pressedScale: 0.95,
          child: Container(
            padding: EdgeInsets.fromLTRB(t.space8 + 2, 4, t.space8, 4),
            decoration: ShapeDecoration(
              color: isCloud ? t.brandSoft : t.fill,
              shape: StadiumBorder(
                side: BorderSide(
                  color: isCloud ? t.brandInk.withValues(alpha: 0.18) : t.line,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCloud ? EnjoyIcons.cloudDone : EnjoyIcons.monitor,
                  size: 13,
                  color: isCloud ? t.brandInk : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCloud ? t.brandInk : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  EnjoyIcons.caretUpDown,
                  size: 12,
                  color: isCloud ? t.brandInk : t.ink3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
