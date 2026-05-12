/// Extra bottom clearance for floating notices above shell chrome (transport + nav).
library;

import 'package:flutter/material.dart';

/// Estimated total height of [GlobalTransportBar] (progress strip + control row +
/// padding). Slightly conservative so notices sit fully above the bar.
const double kRootShellTransportSnackClearance = 128;

/// [NavigationBarThemeData.height] in [app_theme.dart].
const double kRootShellBottomNavSnackClearance = 64;

/// Provides bottom clearance for [AppNotice] when the routed subtree lives under
/// [RootShell] (mini transport and/or bottom navigation).
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
