import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/plans_unavailable_view.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

void main() {
  testWidgets('defaults to the shared plans-unavailable message', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(PlansUnavailableView(onRetry: () {})));

    final context = tester.element(find.byType(PlansUnavailableView));
    final l10n = AppLocalizations.of(context)!;
    expect(
      find.text(l10n.subscriptionAutoRenewPlansUnavailable),
      findsOneWidget,
    );
    expect(find.text(l10n.retry), findsOneWidget);
  });

  testWidgets('renders a caller-provided label', (tester) async {
    await tester.pumpWidget(
      _wrap(PlansUnavailableView(label: 'No plans today', onRetry: () {})),
    );

    expect(find.text('No plans today'), findsOneWidget);
  });

  testWidgets('retry button invokes the callback', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      _wrap(PlansUnavailableView(onRetry: () => retries++)),
    );

    final context = tester.element(find.byType(PlansUnavailableView));
    final l10n = AppLocalizations.of(context)!;
    await tester.tap(find.widgetWithText(EnjoyButton, l10n.retry));
    expect(retries, 1);
  });
}
