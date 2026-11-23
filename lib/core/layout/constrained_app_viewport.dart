/// Root viewport: keeps a sensible minimum width so mobile layouts are not crushed.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Minimum logical width for the app shell. Narrower host windows scroll horizontally.
const double kMinAppViewportWidth = 360;

/// Wraps the routed subtree so widths below [kMinAppViewportWidth] scroll horizontally.
class ConstrainedAppViewport extends StatelessWidget {
  const ConstrainedAppViewport({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mq = MediaQuery.sizeOf(context);
        final h = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : mq.height;
        final w = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : kMinAppViewportWidth;
        if (w >= kMinAppViewportWidth) {
          return SizedBox(width: w, height: h, child: child);
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: kMinAppViewportWidth,
            height: math.max(h, 0),
            child: child,
          ),
        );
      },
    );
  }
}
