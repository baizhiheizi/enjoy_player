import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_dock_primitives.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness(Widget child) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
  return MaterialApp(
    theme: ThemeData(
      colorScheme: scheme,
      extensions: [EnjoyThemeTokens.build(scheme)],
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('DockActionPill', () {
    testWidgets('renders label, icon, and keycap in a paper pill', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          DockActionPill(
            tooltip: 'Cancel',
            onTap: () {},
            icon: EnjoyIcons.close,
            slotColor: const Color(0xFFEEEEEE),
            inkColor: const Color(0xFF111111),
            label: 'Cancel',
            keycap: 'Esc',
            width: 150,
            height: 52,
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byIcon(EnjoyIcons.close), findsOneWidget);
      expect(find.text('Esc'), findsOneWidget);
    });

    testWidgets('forwards taps to onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _harness(
          DockActionPill(
            tooltip: 'Cancel',
            onTap: () => taps++,
            icon: EnjoyIcons.close,
            slotColor: const Color(0xFFEEEEEE),
            inkColor: const Color(0xFF111111),
            label: 'Cancel',
            keycap: 'Esc',
            width: 150,
            height: 52,
          ),
        ),
      );

      await tester.tap(find.byType(DockActionPill));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('default padding reserves a trailing inset for the keycap', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          DockActionPill(
            tooltip: 'Original',
            onTap: () {},
            icon: EnjoyIcons.play,
            slotColor: const Color(0xFFEEEEEE),
            inkColor: const Color(0xFF111111),
            label: 'Original',
            keycap: 'S',
            width: 200,
            height: 48,
          ),
        ),
      );

      final pill = tester.getRect(find.byType(DockActionPill));
      final keycap = tester.getRect(find.byType(EnjoyKeycap));
      expect(pill.right - keycap.right, 12);
    });

    testWidgets('caller padding moves the keycap by the same delta', (
      tester,
    ) async {
      Future<double> keycapRight(EdgeInsetsGeometry padding) async {
        await tester.pumpWidget(
          _harness(
            DockActionPill(
              tooltip: 'Original',
              onTap: () {},
              icon: EnjoyIcons.play,
              slotColor: const Color(0xFFEEEEEE),
              inkColor: const Color(0xFF111111),
              label: 'Original',
              keycap: 'S',
              width: 200,
              height: 48,
              padding: padding,
            ),
          ),
        );
        return tester.getRect(find.byType(EnjoyKeycap)).right;
      }

      final inset = await keycapRight(
        const EdgeInsets.only(left: 8, right: 12),
      );
      final flush = await keycapRight(const EdgeInsets.only(left: 8));
      expect(flush - inset, 12);
    });
  });
}
