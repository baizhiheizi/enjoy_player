/// Compact Local / Cloud badge toggle for the Library header title row.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
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
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: isCloud
              ? cs.primaryContainer.withValues(alpha: 0.55)
              : cs.surfaceContainerHighest.withValues(alpha: 0.65),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(t.radiusFull),
            side: BorderSide(
              color: cs.outlineVariant.withValues(alpha: isCloud ? 0.35 : 0.25),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Haptics.selection(context);
              onToggle();
            },
            child: Padding(
              padding: EdgeInsets.fromLTRB(t.space8, 4, t.space4, 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: tt.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                      color: isCloud
                          ? cs.onPrimaryContainer
                          : cs.onSurfaceVariant,
                    ),
                  ),
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 16,
                    color: isCloud
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
