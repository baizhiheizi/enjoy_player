import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/library/presentation/library_actions.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness() {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: scheme,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) => Center(
            child: Builder(
              builder: (anchor) => TextButton(
                onPressed: () =>
                    showImportChooser(context, ref, anchor: anchor),
                child: const Text('Import'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('desktop drops a menu under the Import button', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await tester.pumpWidget(_harness());
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuItem<int>), findsNWidgets(3));
      expect(find.text('From file…'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
      final menuTop = tester.getTopLeft(find.text('From file…')).dy;
      expect(
        menuTop,
        greaterThan(tester.getBottomLeft(find.text('Import')).dy),
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('mobile opens the bottom sheet', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNWidgets(3));
    expect(find.byType(PopupMenuItem<int>), findsNothing);
  });
}
