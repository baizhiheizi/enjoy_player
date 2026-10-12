import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_dock_primitives.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DockActionPill', () {
    testWidgets('renders label, icon, and keycap in a paper pill', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            extensions: [
              EnjoyThemeTokens.build(
                ColorScheme.fromSeed(seedColor: Colors.blue),
              ),
            ],
          ),
          home: Scaffold(
            body: Center(
              child: DockActionPill(
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
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            extensions: [
              EnjoyThemeTokens.build(
                ColorScheme.fromSeed(seedColor: Colors.blue),
              ),
            ],
          ),
          home: Scaffold(
            body: Center(
              child: DockActionPill(
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
          ),
        ),
      );

      await tester.tap(find.byType(DockActionPill));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('omits right padding when caller overrides it', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            extensions: [
              EnjoyThemeTokens.build(
                ColorScheme.fromSeed(seedColor: Colors.blue),
              ),
            ],
          ),
          home: Scaffold(
            body: Center(
              child: DockActionPill(
                tooltip: 'Original',
                onTap: () {},
                icon: EnjoyIcons.play,
                slotColor: const Color(0xFFEEEEEE),
                inkColor: const Color(0xFF111111),
                label: 'Original',
                keycap: 'S',
                width: 200,
                height: 48,
                padding: const EdgeInsets.only(left: 8),
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Original'),
              matching: find.byType(Container),
            )
            .first,
      );
      final padding = container.padding! as EdgeInsets;
      expect(padding.right, 0);
      expect(padding.left, 8);
    });
  });
}
