import 'dart:async';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/application/subscription_status_provider.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_status.dart';
import 'package:enjoy_player/features/subscription/presentation/subscription_screen.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/tier_comparison.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

class _SignedInAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedIn(
    profile: UserProfile(id: 'u1', email: 'a@b.com', name: 'Test'),
  );
}

Widget _harness(Widget child, {List<Override> overrides = const []}) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
  return ProviderScope(
    overrides: [
      authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
      ...overrides,
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: scheme,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows loading skeleton while status loads', (tester) async {
    final completer = Completer<SubscriptionStatus>();
    addTearDown(() {
      if (!completer.isCompleted) {
        completer.complete(
          const SubscriptionStatus(
            subscriptionActive: true,
            subscriptionTier: SubscriptionTier.free,
          ),
        );
      }
    });

    await tester.pumpWidget(
      _harness(
        const SubscriptionScreen(),
        overrides: [
          subscriptionStatusProvider.overrideWith((ref) => completer.future),
        ],
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('shows free tier comparison when status loads', (tester) async {
    await tester.pumpWidget(
      _harness(
        const SubscriptionScreen(),
        overrides: [
          subscriptionStatusProvider.overrideWith(
            (ref) async => const SubscriptionStatus(
              subscriptionActive: true,
              subscriptionTier: SubscriptionTier.free,
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.subscriptionTitle), findsWidgets);
    expect(find.text(l10n.subscriptionTierFreeName), findsWidgets);
    expect(find.text(l10n.subscriptionUpgrade), findsWidgets);
  });

  testWidgets('shows retry on error', (tester) async {
    await tester.pumpWidget(
      _harness(
        const SubscriptionScreen(),
        overrides: [
          subscriptionStatusProvider.overrideWith(
            (ref) async => throw Exception('network'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.subscriptionErrorLoading), findsOneWidget);
    expect(find.text(l10n.retry), findsOneWidget);
  });

  testWidgets('renders tier comparison on narrow phone without layout errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _harness(
        const SubscriptionScreen(),
        overrides: [
          subscriptionStatusProvider.overrideWith(
            (ref) async => const SubscriptionStatus(
              subscriptionActive: true,
              subscriptionTier: SubscriptionTier.free,
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS upgrade shows coming-soon dialog not purchase sheet', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          colorScheme: scheme,
          extensions: [EnjoyThemeTokens.build(scheme)],
        ),
        home: const Scaffold(
          body: TierComparison(
            status: SubscriptionStatus(
              subscriptionActive: true,
              subscriptionTier: SubscriptionTier.free,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('en'));
    await tester.tap(find.text(l10n.subscriptionUpgrade).last);
    await tester.pumpAndSettle();

    expect(find.text(l10n.subscriptionMobilePurchaseTitle), findsOneWidget);
    expect(find.text(l10n.subscriptionPurchaseTitle), findsNothing);

    debugDefaultTargetPlatformOverride = null;
  });
}
