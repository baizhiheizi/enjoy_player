/// One rail entry in the two-pane Settings desktop layout.
///
/// Delegates the shared pill highlight / focus-ring treatment to
/// [NavItemPill] so the Settings hub visually belongs to the rest of the
/// app (matches [AppSidebar]'s selected-nav-item look) without copying the
/// `Material` + `InkWell` + `AnimatedContainer` stack.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/widgets/nav_item_pill.dart';

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
    return NavItemPill(
      icon: icon,
      label: label,
      selected: selected,
      onTap: onTap,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
