import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/application/subscription_plans_provider.dart';
import 'package:enjoy_player/features/subscription/application/subscription_purchase_provider.dart';
import 'package:enjoy_player/features/subscription/application/subscription_status_provider.dart';
import 'package:enjoy_player/features/subscription/domain/auto_renew_billing.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_plan.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_status.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/auto_renew_plan_sheet.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const _testPlans = [
  SubscriptionPlan(
    id: 'plan_monthly',
    tier: 'pro',
    interval: 'month',
    amount: 9.99,
  ),
  SubscriptionPlan(
    id: 'plan_yearly',
    tier: 'pro',
    interval: 'year',
    amount: 79.99,
  ),
];

class _IdlePurchaseCtrl extends SubscriptionPurchaseCtrl {
  @override
  AsyncValue<void> build() => const AsyncData(null);
}

Widget _harness({required List<Override> overrides, required Widget child}) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
  return ProviderScope(
    overrides: [
      subscriptionPurchaseCtrlProvider.overrideWith(_IdlePurchaseCtrl.new),
      ...overrides,
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      home: child,
    ),
  );
}

/// A scaffold with a button that opens the auto-renew plan sheet.
class _SheetLauncher extends StatelessWidget {
  const _SheetLauncher();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => showAutoRenewPlanSheet(context),
          child: const Text('Open Sheet'),
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutoRenewPlanSheet', () {
    testWidgets('shows plan tiles with monthly and yearly options', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      await tester.pumpWidget(
        _harness(
          overrides: [
            subscriptionPlansProvider.overrideWith((ref) async => _testPlans),
            subscriptionStatusProvider.overrideWith(
              (ref) async => const SubscriptionStatus(
                subscriptionActive: false,
                subscriptionTier: SubscriptionTier.free,
              ),
            ),
          ],
          child: const _SheetLauncher(),
        ),
      );
      await tester.pumpAndSettle();

      // Open the sheet.
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final l10n = lookupAppLocalizations(const Locale('en'));

      // Title is shown.
      expect(find.text(l10n.subscriptionAutoRenewTitle), findsOneWidget);

      // Monthly and yearly plan tiles are shown.
      expect(find.text(l10n.subscriptionAutoRenewMonthly), findsOneWidget);
      expect(find.text(l10n.subscriptionAutoRenewYearly), findsOneWidget);

      // Prices are formatted.
      expect(
        find.text(l10n.subscriptionAutoRenewPriceMonth('9.99')),
        findsOneWidget,
      );
      expect(
        find.text(l10n.subscriptionAutoRenewPriceYear('79.99')),
        findsOneWidget,
      );

      // Subscribe button is present.
      expect(find.text(l10n.subscriptionAutoRenewSubscribe), findsOneWidget);

      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('shows prepaid upsell when no active auto-renew plan', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      await tester.pumpWidget(
        _harness(
          overrides: [
            subscriptionPlansProvider.overrideWith((ref) async => _testPlans),
            subscriptionStatusProvider.overrideWith(
              (ref) async => const SubscriptionStatus(
                subscriptionActive: false,
                subscriptionTier: SubscriptionTier.free,
              ),
            ),
          ],
          child: const _SheetLauncher(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final l10n = lookupAppLocalizations(const Locale('en'));

      // Pay-once link is shown when no active auto-renew.
      expect(find.text(l10n.subscriptionPayOnceTitle), findsOneWidget);
      expect(find.text(l10n.subscriptionPayOnceSubtitle), findsOneWidget);

      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('hides prepaid upsell when active auto-renew plan exists', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      await tester.pumpWidget(
        _harness(
          overrides: [
            subscriptionPlansProvider.overrideWith((ref) async => _testPlans),
            subscriptionStatusProvider.overrideWith(
              (ref) async => const SubscriptionStatus(
                subscriptionActive: true,
                subscriptionTier: SubscriptionTier.pro,
                autoRenew: AutoRenewBilling(
                  active: true,
                  provider: 'stripe',
                  status: 'active',
                  autoRenew: true,
                  cancelAtPeriodEnd: false,
                  interval: 'month',
                  amount: 9.99,
                  tier: 'pro',
                ),
              ),
            ),
          ],
          child: const _SheetLauncher(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final l10n = lookupAppLocalizations(const Locale('en'));

      // Pay-once link is hidden when active auto-renew exists.
      expect(find.text(l10n.subscriptionPayOnceTitle), findsNothing);
      expect(find.text(l10n.subscriptionPayOnceSubtitle), findsNothing);

      // Subscribe button still present.
      expect(find.text(l10n.subscriptionAutoRenewSubscribe), findsOneWidget);

      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('shows unavailable message when plans list is empty', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      await tester.pumpWidget(
        _harness(
          overrides: [
            subscriptionPlansProvider.overrideWith(
              (ref) async => const <SubscriptionPlan>[],
            ),
            subscriptionStatusProvider.overrideWith(
              (ref) async => const SubscriptionStatus(
                subscriptionActive: false,
                subscriptionTier: SubscriptionTier.free,
              ),
            ),
          ],
          child: const _SheetLauncher(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(
        find.text(l10n.subscriptionAutoRenewPlansUnavailable),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('shows loading indicator while plans load', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      final completer = Completer<List<SubscriptionPlan>>();
      addTearDown(() {
        if (!completer.isCompleted) completer.complete(_testPlans);
      });

      await tester.pumpWidget(
        _harness(
          overrides: [
            subscriptionPlansProvider.overrideWith((ref) => completer.future),
            subscriptionStatusProvider.overrideWith(
              (ref) async => const SubscriptionStatus(
                subscriptionActive: false,
                subscriptionTier: SubscriptionTier.free,
              ),
            ),
          ],
          child: const _SheetLauncher(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('shows unavailable message on plans error', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      await tester.pumpWidget(
        _harness(
          overrides: [
            subscriptionPlansProvider.overrideWith(
              (ref) async => throw Exception('network error'),
            ),
            subscriptionStatusProvider.overrideWith(
              (ref) async => const SubscriptionStatus(
                subscriptionActive: false,
                subscriptionTier: SubscriptionTier.free,
              ),
            ),
          ],
          child: const _SheetLauncher(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(
        find.text(l10n.subscriptionAutoRenewPlansUnavailable),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('first plan is selected by default (radio checked)', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      await tester.pumpWidget(
        _harness(
          overrides: [
            subscriptionPlansProvider.overrideWith((ref) async => _testPlans),
            subscriptionStatusProvider.overrideWith(
              (ref) async => const SubscriptionStatus(
                subscriptionActive: false,
                subscriptionTier: SubscriptionTier.free,
              ),
            ),
          ],
          child: const _SheetLauncher(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // First plan (monthly) should have radio_button_checked icon.
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_off), findsOneWidget);

      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
