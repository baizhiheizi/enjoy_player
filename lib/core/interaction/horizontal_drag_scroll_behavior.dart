/// Scroll behavior for horizontal strips (mouse / trackpad drag on desktop).
library;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

/// Stable [ScrollBehavior] for horizontal [ListView]s — avoids rebuilding
/// [ScrollConfiguration] from [ScrollConfiguration.of] on every frame.
class HorizontalDragScrollBehavior extends ScrollBehavior {
  const HorizontalDragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
