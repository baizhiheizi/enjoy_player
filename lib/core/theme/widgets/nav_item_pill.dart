/// Sidebar-style navigation row: icon + label with a quiet selection plate.
///
/// Shared by [AppSidebar]'s desktop nav and the Settings two-pane rail —
/// both render the same "selected nav item" treatment, so they share this
/// primitive (ADR-0018). Aurora styling (ADR-0089): compact 34px rows,
/// continuous corners, a lifted plate for the selected item (white card on
/// porcelain, lit wash on midnight), filled glyph + iris ink when selected.
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
    this.iconSize = 18,
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final light = Theme.of(context).brightness == Brightness.light;
    final radius = BorderRadius.circular(t.radiusSm + 1);

    final plate = selected
        ? ShapeDecoration(
            color: light ? t.card : cs.onSurface.withValues(alpha: 0.075),
            shape: RoundedSuperellipseBorder(
              borderRadius: radius,
              side: BorderSide(
                color: light
                    ? t.hairline
                    : Colors.white.withValues(alpha: 0.04),
              ),
            ),
            shadows: light
                ? const [
                    BoxShadow(
                      color: Color(0x0F16161D),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ]
                : const [],
          )
        : ShapeDecoration(
            shape: RoundedSuperellipseBorder(borderRadius: radius),
          );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space8 + 2, vertical: 1),
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
          constraints: const BoxConstraints(minHeight: 34),
          padding: EdgeInsets.symmetric(horizontal: t.space8 + 2, vertical: 6),
          decoration: plate,
          child: Row(
            children: [
              IconTheme(
                data: IconThemeData(
                  size: iconSize,
                  color: selected ? t.accentInk : cs.onSurfaceVariant,
                ),
                child: selected
                    ? (selectedIconWidget ??
                          iconWidget ??
                          Icon(selectedIcon ?? icon, size: iconSize))
                    : (iconWidget ?? Icon(icon, size: iconSize)),
              ),
              SizedBox(width: t.space8 + 2),
              Expanded(
                child: Text(
                  label,
                  maxLines: maxLines,
                  overflow: overflow,
                  style: tt.labelLarge?.copyWith(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? cs.onSurface : cs.onSurfaceVariant,
                  ),
                ),
              ),
              if (trailing != null) ...[SizedBox(width: t.space8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
