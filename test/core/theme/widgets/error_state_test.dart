import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
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
        _harness(ErrorState(message: 'boom', onRetry: () => retries++)),
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

    testWidgets('a message taller than the viewport scrolls, not overflows', (
      tester,
    ) async {
      const longMessage =
          'error: DatabaseException(android.database.sqlite.SQLiteException: '
          'could not roll back transaction — database is locked (code '
          'SQLITE_BUSY) while committing audio row 7f3c of library import '
          'batch 41; the write-ahead log grew past its checkpoint budget and '
          'the retry queue kept the connection busy until the timeout fired';
      await tester.pumpWidget(
        _harness(
          const SizedBox(height: 220, child: ErrorState(message: longMessage)),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.textContaining('SQLITE_BUSY'), findsOneWidget);
    });
  });
}
