import 'package:enjoy_player/core/recovery/recovery_error_panel.dart';
import 'package:enjoy_player/core/recovery/widget_error_surface.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
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

    final l10n = AppLocalizations.of(
      tester.element(find.byType(WidgetErrorSurface)),
    )!;
    final surface = Theme.of(
      tester.element(find.byType(RecoveryErrorPanel)),
    ).colorScheme.surface;

    expect(find.byType(RecoveryErrorLayout), findsOneWidget);
    expect(find.byType(RecoveryErrorPanel), findsOneWidget);
    expect(find.text(l10n.widgetErrorTitle), findsOneWidget);
    expect(find.text(l10n.widgetErrorSubtitle), findsOneWidget);
    expect(find.text(l10n.recoveryCopyError), findsOneWidget);
    expect(tester.widget<Icon>(find.byIcon(EnjoyIcons.error)).size, 56);

    final message = tester.widget<Text>(find.textContaining('widget blew up'));
    expect(message.maxLines, 8);
    expect(
      tester
          .widgetList<Material>(find.byType(Material))
          .any((material) => material.color == surface),
      isTrue,
    );
  });
}
