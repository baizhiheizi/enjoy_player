/// Extra bottom clearance for floating notices above shell chrome (dock + nav).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/widgets/enjoy_bottom_nav.dart';

/// Estimated total height of the player dock (ruler + control row +
/// padding). Slightly conservative so notices sit fully above the bar.
const double kRootShellTransportSnackClearance = 128;

/// Bottom nav bar content height + system home-indicator inset (Duet tab bar).
double rootShellBottomNavClearance(BuildContext context) =>
    EnjoyBottomNav.contentHeight + MediaQuery.paddingOf(context).bottom;

/// Provides bottom clearance for [AppNotice] when the routed subtree lives under
/// [RootShell] (mini transport and/or [EnjoyBottomNav]).
/// Nav clearance is [rootShellBottomNavClearance] (bar height + system bottom inset).
class RootShellBottomInset extends InheritedWidget {
  const RootShellBottomInset({
    required this.bottomClearance,
    required super.child,
    super.key,
  });

  /// Logical pixels to add above system bottom inset (transport + bottom nav).
  final double bottomClearance;

  static RootShellBottomInset? maybeOf(BuildContext context) {
    return context.findAncestorWidgetOfExactType<RootShellBottomInset>();
  }

  static double clearanceOf(BuildContext context) {
    return maybeOf(context)?.bottomClearance ?? 0;
  }

  @override
  bool updateShouldNotify(RootShellBottomInset oldWidget) {
    return bottomClearance != oldWidget.bottomClearance;
  }
}
