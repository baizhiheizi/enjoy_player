/// Custom bottom navigation — Enjoy editorial chrome (not stock [NavigationBar]).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

class EnjoyBottomNavDestination {
  const EnjoyBottomNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.semanticsLabel,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Defaults to [label] when null.
  final String? semanticsLabel;
}

class EnjoyBottomNav extends StatelessWidget {
  const EnjoyBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<EnjoyBottomNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerLow,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
          ),
        ),
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.zero,
          child: SizedBox(
            height: t.bottomNavHeight,
            child: Row(
              children: [
                for (var i = 0; i < destinations.length; i++)
                  Expanded(
                    child: _EnjoyBottomNavItem(
                      destination: destinations[i],
                      selected: i == selectedIndex,
                      onTap: () {
                        Haptics.selection(context);
                        onDestinationSelected(i);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnjoyBottomNavItem extends StatelessWidget {
  const _EnjoyBottomNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final EnjoyBottomNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final label = destination.semanticsLabel ?? destination.label;

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      child: Focus(
        child: Builder(
          builder: (focusContext) {
            final focused = Focus.of(focusContext).hasFocus;
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: t.space4,
                vertical: t.space4,
              ),
              child: Material(
                color: Colors.transparent,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(t.radiusLg),
                  side: focused && !selected
                      ? BorderSide(
                          color: cs.primary.withValues(alpha: 0.55),
                          width: t.focusRingWidth,
                        )
                      : BorderSide.none,
                ),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(t.radiusLg),
                  hoverColor: cs.onSurface.withValues(alpha: 0.05),
                  splashColor: cs.primary.withValues(alpha: 0.10),
                  highlightColor: cs.primary.withValues(alpha: 0.06),
                  child: AnimatedContainer(
                    duration: t.motionFast,
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: t.space4,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primaryContainer.withValues(alpha: 0.55)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(t.radiusLg),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected
                              ? destination.selectedIcon
                              : destination.icon,
                          size: 24,
                          color: selected
                              ? cs.onPrimaryContainer
                              : cs.onSurfaceVariant,
                        ),
                        SizedBox(height: t.space4),
                        Text(
                          destination.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: tt.labelSmall?.copyWith(
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: selected
                                ? cs.onSurface
                                : cs.onSurfaceVariant,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
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
