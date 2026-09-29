import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';

/// The focus-ring side [EnjoyPressable] paints for the first pressable under
/// [of] (`BorderSide.none` when the ring is hidden).
BorderSide pressableFocusRingSide(WidgetTester tester, Finder of) {
  final container = tester.widget<AnimatedContainer>(
    find
        .descendant(
          of: find.descendant(of: of, matching: find.byType(EnjoyPressable)),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );
  final decoration = container.foregroundDecoration! as ShapeDecoration;
  return (decoration.shape as OutlinedBorder).side;
}
