import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/subscription/presentation/credits_failure_actions.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('credits failure snackbar navigates to subscription', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showCreditsFailureWithUpgradeAction(
                  context,
                  const CreditsFailure('Daily limit reached'),
                ),
                child: const Text('trigger'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/subscription',
          builder: (context, state) =>
              const Scaffold(body: Text('subscription-page')),
        ),
      ],
    );

    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          colorScheme: scheme,
          extensions: [EnjoyThemeTokens.build(scheme)],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('trigger'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text('Daily limit reached'), findsOneWidget);
    expect(find.text(l10n.subscriptionViewPlansAndPackages), findsOneWidget);

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    snackBar.action!.onPressed();
    await tester.pumpAndSettle();

    expect(find.text('subscription-page'), findsOneWidget);
  });
}
