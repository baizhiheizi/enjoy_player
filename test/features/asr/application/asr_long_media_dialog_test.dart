import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/asr/application/asr_long_media_dialog.dart';
import 'package:enjoy_player/features/asr/domain/asr_long_form_constants.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ThemeData _theme() {
  final scheme = ColorScheme.fromSeed(seedColor: Colors.teal);
  return ThemeData(
    colorScheme: scheme,
    extensions: [EnjoyThemeTokens.build(scheme)],
  );
}

void main() {
  testWidgets('skips confirm below 900 seconds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _theme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                final result = await showAsrLongMediaConfirmDialog(
                  context,
                  mediaDurationSeconds: kLongFormMinDurationSeconds - 1,
                );
                expect(result, isTrue);
              },
              child: const Text('go'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('shows confirm at 900 seconds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _theme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                await showAsrLongMediaConfirmDialog(
                  context,
                  mediaDurationSeconds: kLongFormMinDurationSeconds,
                );
              },
              child: const Text('go'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}
