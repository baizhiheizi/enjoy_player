/// Sidebar-style navigation row: icon + label with a paper selection plate.
///
/// Shared by [AppSidebar]'s desktop nav and the Settings two-pane rail —
/// both render the same "selected nav item" treatment, so they share this
/// primitive (ADR-0018). Duet styling (ADR-0091): 38px rows at radius 11,
/// a paper plate with the lift shadow for the selected item, and the
/// brand-ink glyph when selected.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

class NavItemPill extends StatelessWidget {
  const NavItemPill({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedIcon,
    this.iconWidget,
    this.selectedIconWidget,
    this.iconSize = 20,
    this.maxLines,
    this.overflow,
    this.trailing,
  });

  final IconData icon;

  /// When [selected] is true, the icon shown for the active item. Falls back
  /// to [icon] when null.
  final IconData? selectedIcon;

  /// Optional chrome widget; when set, replaces the [Icon] for this state.
  final Widget? iconWidget;
  final Widget? selectedIconWidget;

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Pixel size for the leading icon.
  final double iconSize;

  /// Forwarded to the label [Text].
  final int? maxLines;
  final TextOverflow? overflow;

  /// Optional trailing widget (count badge, keycap).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(t.radiusControl - 1);

    final plate = selected
        ? ShapeDecoration(
            color: t.paper,
            shape: RoundedSuperellipseBorder(borderRadius: radius),
            shadows: t.shadowLift,
          )
        : ShapeDecoration(
            shape: RoundedSuperellipseBorder(borderRadius: radius),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: EnjoyPressable(
        onTap: onTap,
        borderRadius: radius,
        pressedScale: 0.985,
        showHoverWash: !selected,
        showFocusRing: !selected,
        selected: selected,
        child: AnimatedContainer(
          duration: t.motionFast,
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 38),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: plate,
          child: Row(
            children: [
              IconTheme(
                data: IconThemeData(
                  size: iconSize,
                  color: selected ? t.brandInk : t.ink2,
                ),
                child: selected
                    ? (selectedIconWidget ??
                          iconWidget ??
                          Icon(selectedIcon ?? icon, size: iconSize))
                    : (iconWidget ?? Icon(icon, size: iconSize)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  maxLines: maxLines,
                  overflow: overflow,
                  style: tt.labelLarge?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                    color: selected ? t.ink : t.ink2,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
