import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/error_state.dart';

Widget _harness(Widget child) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7B61FF),
    brightness: Brightness.dark,
  );
  return MaterialApp(
    theme: ThemeData(
      colorScheme: scheme,
      extensions: [EnjoyThemeTokens.build(scheme)],
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  group('ErrorState', () {
    testWidgets('renders the error glyph, the message, and the retry action', (
      tester,
    ) async {
      var retries = 0;
      await tester.pumpWidget(
        _harness(
          ErrorState(
            message: 'boom',
            onRetry: () => retries++,
            retryLabel: 'Retry',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(EnjoyIcons.error), findsOneWidget);
      expect(find.text('boom'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });

    testWidgets('omits the retry button without a retry callback', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(const ErrorState(message: 'boom')));
      await tester.pumpAndSettle();

      expect(find.byIcon(EnjoyIcons.error), findsOneWidget);
      expect(find.text('boom'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(EnjoyButton), findsNothing);
    });
  });
}
