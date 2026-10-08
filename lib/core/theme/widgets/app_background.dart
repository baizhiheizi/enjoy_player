/// The flat page background (Duet ground, ADR-0093).
library;

import 'package:flutter/material.dart';

/// Wraps [child] in the flat page background.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.color});

  final Widget child;

  /// Base fill (defaults to the ground surface).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(color: color ?? cs.surface, child: child);
  }
}
