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

    var decoration = washDecoration(tester);
    expect(decoration.shape, isA<CircleBorder>());
    expect(washAlphaOf(decoration), 0);
    expect((decoration.shape as OutlinedBorder).side, BorderSide.none);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    decoration = washDecoration(tester);
    expect(decoration.shape, isA<CircleBorder>());
    expect((decoration.shape as OutlinedBorder).side, isNot(BorderSide.none));
  });

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
