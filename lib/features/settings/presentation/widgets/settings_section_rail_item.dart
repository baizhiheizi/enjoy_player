/// One rail entry in the two-pane Settings desktop layout.
///
/// Matches [AppSidebar]'s selected-nav-item treatment (pill highlight,
/// focus ring) so the Settings hub visually belongs to the rest of the app.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

class SettingsSectionRailItem extends StatelessWidget {
  const SettingsSectionRailItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space8, vertical: 2),
      child: Focus(
        child: Builder(
          builder: (focusContext) {
            final focused = Focus.of(focusContext).hasFocus;
            return Material(
              color: Colors.transparent,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(t.radiusFull),
                side: focused && !selected
                    ? BorderSide(
                        color: cs.primary.withValues(alpha: 0.55),
                        width: t.focusRingWidth,
                      )
                    : BorderSide.none,
              ),
              child: InkWell(
                onTap: () {
                  Haptics.selection(context);
                  onTap();
                },
                borderRadius: BorderRadius.circular(t.radiusFull),
                hoverColor: cs.onSurface.withValues(alpha: 0.06),
                splashColor: cs.primary.withValues(alpha: 0.10),
                highlightColor: cs.primary.withValues(alpha: 0.05),
                child: AnimatedContainer(
                  duration: t.motionFast,
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: t.space16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? cs.primaryContainer.withValues(alpha: 0.6)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(t.radiusFull),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: selected
                            ? cs.onPrimaryContainer
                            : cs.onSurfaceVariant,
                      ),
                      SizedBox(width: t.space12),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.labelLarge?.copyWith(
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: selected
                                ? cs.onSurface
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
