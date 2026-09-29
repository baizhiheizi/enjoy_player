import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_frosted_back_button.dart';

void main() {
  ShapeDecoration washDecoration(WidgetTester tester) {
    final container = tester.widget<AnimatedContainer>(
      find
          .descendant(
            of: find.byType(EnjoyPressable),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    return container.foregroundDecoration! as ShapeDecoration;
  }

  /// 0–255 integer alpha of the wash fill (Color.alpha is deprecated).
  int washAlphaOf(ShapeDecoration decoration) =>
      (decoration.color!.a * 255).round();

  testWidgets('wash and focus ring follow the circular chrome outline', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: PlayerFrostedBackButton(onPressed: () {})),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The pressable paints its hover / press wash and focus ring as one
    // ShapeDecoration whose shape is state-independent — hover, press, and
    // focus only animate the color alpha and side. Idle: the true circle,
    // no wash, no ring.
    var decoration = washDecoration(tester);
    expect(decoration.shape, isA<CircleBorder>());
    expect(washAlphaOf(decoration), 0);
    expect((decoration.shape as OutlinedBorder).side, BorderSide.none);

    // Keyboard focus paints the ring on the same circular outline — a
    // RoundedSuperellipseBorder of radius _size / 2 would read as a faint
    // square halo inside the circular glass.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    decoration = washDecoration(tester);
    expect(decoration.shape, isA<CircleBorder>());
    expect((decoration.shape as OutlinedBorder).side, isNot(BorderSide.none));
  });

  // The back button's Tooltip owns a long-press recognizer, so a bare
  // touch-down there never wins the gesture arena and the press state is not
  // observable. The primitive-level press below proves the wash itself.
  testWidgets('press wash paints inside the true circle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: EnjoyPressable(
              onTap: () {},
              shape: const CircleBorder(),
              child: const ColoredBox(
                color: Color(0xFF0000FF),
                child: SizedBox(width: 38, height: 38),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(EnjoyPressable)),
    );
    await tester.pump();

    final decoration = washDecoration(tester);
    expect(decoration.shape, isA<CircleBorder>());
    // Press wash is visible and fills the circle, not a superellipse.
    expect(washAlphaOf(decoration), greaterThan(0));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('taps invoke onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: PlayerFrostedBackButton(onPressed: () => taps++)),
        ),
      ),
    );

    await tester.tap(find.byType(EnjoyPressable));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });
}
