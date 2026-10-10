import 'package:enjoy_player/core/routing/route_paths.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_credits_banner.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _harness({required String message, GoRouter? router}) {
  return MaterialApp.router(
    routerConfig:
        router ??
        GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) =>
                  Scaffold(body: LookupCreditsBanner(message: message)),
            ),
            GoRoute(
              path: kSubscriptionRoutePath,
              builder: (context, state) =>
                  const Scaffold(body: Text('subscription-page')),
            ),
          ],
        ),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF)),
      extensions: [
        EnjoyThemeTokens.build(
          ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF)),
        ),
      ],
    ),
  );
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  testWidgets('renders the wallet icon and the provided message', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(message: 'AI credits limit reached.'));
    await tester.pumpAndSettle();

    expect(find.byIcon(EnjoyIcons.wallet), findsOneWidget);
    expect(find.text('AI credits limit reached.'), findsOneWidget);
  });

  testWidgets('renders the shared View plans & packages CTA', (tester) async {
    await tester.pumpWidget(_harness(message: 'AI credits limit reached.'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.subscriptionViewPlansAndPackages), findsOneWidget);
  });

  testWidgets('CTA pushes the subscription route', (tester) async {
    await tester.pumpWidget(_harness(message: 'AI credits limit reached.'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.subscriptionViewPlansAndPackages));
    await tester.pumpAndSettle();

    expect(find.text('subscription-page'), findsOneWidget);
  });
}
