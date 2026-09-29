import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/app_background.dart';

Widget _harness(ThemeData theme, Widget child) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(body: child),
  );
}

ThemeData _theme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7B61FF),
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    extensions: [EnjoyThemeTokens.build(scheme)],
  );
}

void main() {
  group('AppBackground', () {
    for (final brightness in Brightness.values) {
      testWidgets('paints the page surface with the aurora glow '
          '(${brightness.name})', (tester) async {
        final theme = _theme(brightness);
        await tester.pumpWidget(
          _harness(theme, const AppBackground(child: Text('inside'))),
        );
        await tester.pumpAndSettle();
        expect(find.text('inside'), findsOneWidget);
        final fill = tester.widget<ColoredBox>(
          find
              .descendant(
                of: find.byType(AppBackground),
                matching: find.byType(ColoredBox),
              )
              .first,
        );
        expect(fill.color, theme.colorScheme.surface);
        expect(
          find.descendant(
            of: find.byType(AppBackground),
            matching: find.byType(AuroraGlow),
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('glow can be turned off', (tester) async {
      await tester.pumpWidget(
        _harness(
          _theme(Brightness.dark),
          const AppBackground(glow: false, child: Text('inside')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AuroraGlow), findsNothing);
      expect(find.text('inside'), findsOneWidget);
    });
  });

  group('PlayerAmbientBackdrop', () {
    testWidgets('passes child through unchanged when accentColor is null', (
      tester,
    ) async {
      const key = ValueKey('child');
      await tester.pumpWidget(
        _harness(
          _theme(Brightness.dark),
          const PlayerAmbientBackdrop(child: Text('inside', key: key)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(key), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PlayerAmbientBackdrop),
          matching: find.byType(Stack),
        ),
        findsNothing,
      );
    });

    testWidgets('renders a radial tint overlay when accentColor is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          _theme(Brightness.dark),
          const PlayerAmbientBackdrop(
            accentColor: Color(0xFFFF7F50),
            intensity: 0.10,
            child: Text('inside'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(PlayerAmbientBackdrop),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect((box.decoration as BoxDecoration).gradient, isA<RadialGradient>());
      expect(find.text('inside'), findsOneWidget);
    });
  });
}
