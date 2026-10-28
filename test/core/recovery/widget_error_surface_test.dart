import 'package:enjoy_player/core/recovery/recovery_error_panel.dart';
import 'package:enjoy_player/core/recovery/widget_error_surface.dart';
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
  testWidgets('WidgetErrorSurface renders the shared recovery error panel', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        WidgetErrorSurface(
          details: FlutterErrorDetails(exception: StateError('widget blew up')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.textContaining('widget blew up'), findsAtLeastNWidgets(1));
    expect(find.byType(RecoveryErrorPanel), findsOneWidget);
    expect(find.text('Copy error'), findsOneWidget);
  });
}
