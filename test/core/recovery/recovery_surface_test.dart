import 'package:enjoy_player/core/recovery/recovery_surface.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  testWidgets('RecoverySurface renders the three actions', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RecoverySurface(error: 'SqliteException: file is not a database'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Local data needs attention'), findsOneWidget);
    expect(find.text('Copy error'), findsOneWidget);
    expect(find.text('Open logs folder'), findsOneWidget);
    // "Reset local library" appears as both the card title and the
    // button label; the important assertion is the button is present.
    expect(find.text('Reset local library'), findsAtLeastNWidgets(1));
    // The error preview is truncated; just confirm the snippet is present.
    expect(
      find.textContaining('file is not a database'),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets('Tapping Reset shows the confirmation dialog', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(const RecoverySurface(error: 'SqliteException: oops')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Reset local library'));
    await tester.pumpAndSettle();

    expect(find.text('Reset local library?'), findsOneWidget);
    expect(find.text('Reset everything'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
