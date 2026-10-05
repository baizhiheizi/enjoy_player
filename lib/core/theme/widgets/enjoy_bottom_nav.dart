/// Solid tab bar — Duet mobile chrome (ADR-0091), not stock [NavigationBar].
///
/// A full-width paper bar with a top line: the selected tab gets a
/// brandSoft pill, a filled glyph in brandInk, and a 600 label.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

class EnjoyBottomNavDestination {
  const EnjoyBottomNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.semanticsLabel,
    this.showBadge = false,
    this.iconWidget,
    this.selectedIconWidget,
  });

  final IconData icon;
  final IconData selectedIcon;

  /// When set, rendered instead of [icon] (chrome glyph). Tests may omit this.
  final Widget? iconWidget;

  /// When set, rendered instead of [selectedIcon].
  final Widget? selectedIconWidget;
  final String label;

  /// Defaults to [label] when null.
  final String? semanticsLabel;

  /// Small notification dot on the icon (e.g. pending app update).
  final bool showBadge;
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

  /// Content height above the safe inset — 84 − 26 (tokens.tabBarHeight −
  /// tokens.tabBarSafeInset); the real bottom inset grows the bar.
  static double get contentHeight => 58;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: t.paper,
        border: Border(top: BorderSide(color: t.line)),
      ),
      padding: EdgeInsets.fromLTRB(8, 6, 8, bottomInset),
      height: contentHeight + bottomInset,
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
    final tt = Theme.of(context).textTheme;
    final label = destination.semanticsLabel ?? destination.label;
    final color = selected ? t.brandInk : t.ink3;

    return EnjoyPressable(
      onTap: onTap,
      haptic: false,
      showHoverWash: false,
      pressedScale: 0.92,
      borderRadius: BorderRadius.circular(t.radiusFull),
      semanticsLabel: label,
      excludeSemantics: true,
      selected: selected,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 30,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: selected ? t.brandSoft : Colors.transparent,
              shape: const StadiumBorder(),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconTheme(
                  data: IconThemeData(size: 22, color: color),
                  child: selected
                      ? (destination.selectedIconWidget ??
                            destination.iconWidget ??
                            Icon(destination.selectedIcon))
                      : (destination.iconWidget ?? Icon(destination.icon)),
                ),
                if (destination.showBadge)
                  Positioned(
                    right: -3,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: t.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: t.paper, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            destination.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: tt.labelSmall?.copyWith(
              fontSize: 11.5,
              height: 1.2,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: color,
              letterSpacing: 0.05,
            ),
          ),
        ],
      ),
    );
  }
}
