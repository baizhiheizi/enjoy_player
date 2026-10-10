import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/credits/application/credits_summary_provider.dart';
import 'package:enjoy_player/features/credits/domain/credits_summary.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_credits_chip.dart';
import 'package:enjoy_player/features/subscription/application/subscription_status_provider.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_status.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class _StubAuthController extends AuthCtrl {
  _StubAuthController(this._state);
  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;
}

UserProfile _stubProfile() => const UserProfile(
  id: 'user-1',
  email: 'user@example.com',
  name: 'Test User',
  subscriptionTier: SubscriptionTier.free,
);

CreditsSummary _summary(int dailyRemaining) => CreditsSummary(
  tier: 'free',
  dailyUsed: 1000 - dailyRemaining,
  dailyLimit: 1000,
  dailyRemaining: dailyRemaining,
  permanentAvailable: 0,
  resetAt: 0,
);

Widget _harness({
  required AuthState auth,
  CreditsSummary? summary,
  Object? summaryError,
  Key? key,
}) {
  return ProviderScope(
    key: key,
    overrides: [
      authCtrlProvider.overrideWith(() => _StubAuthController(auth)),
      subscriptionStatusProvider.overrideWith(
        (ref) async => const SubscriptionStatus(
          subscriptionActive: false,
          subscriptionTier: SubscriptionTier.free,
        ),
      ),
      if (summaryError != null)
        creditsSummaryProvider.overrideWith((ref) => Future.error(summaryError))
      else if (summary != null)
        creditsSummaryProvider.overrideWith((ref) async => summary),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: LookupCreditsChip()),
    ),
  );
}

void main() {
  testWidgets('renders nothing while signed out', (tester) async {
    await tester.pumpWidget(
      _harness(auth: const AuthSignedOut(), summary: _summary(500)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LookupCreditsChip), findsOneWidget);
    expect(find.byIcon(EnjoyIcons.wallet), findsNothing);
    expect(find.textContaining('left today'), findsNothing);
  });

  testWidgets('shows today\'s remaining credits', (tester) async {
    await tester.pumpWidget(
      _harness(
        auth: AuthSignedIn(profile: _stubProfile()),
        summary: _summary(500),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('500 left today'), findsOneWidget);
    expect(find.textContaining('Almost out'), findsNothing);
  });

  testWidgets('warns once remaining credits pass the low threshold', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        auth: AuthSignedIn(profile: _stubProfile()),
        summary: _summary(40),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Almost out — 40 left today'), findsOneWidget);
  });

  testWidgets('low threshold boundary matches the profile meter', (
    tester,
  ) async {
    Future<void> pumpRemaining(int remaining) async {
      await tester.pumpWidget(
        _harness(
          key: UniqueKey(),
          auth: AuthSignedIn(profile: _stubProfile()),
          summary: _summary(remaining),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpRemaining(100);
    expect(find.text('Almost out — 100 left today'), findsOneWidget);

    await pumpRemaining(101);
    expect(find.text('101 left today'), findsOneWidget);
  });

  testWidgets('renders nothing while the summary has not loaded', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        auth: AuthSignedIn(profile: _stubProfile()),
        summaryError: Exception('offline'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(EnjoyIcons.wallet), findsNothing);
    expect(find.textContaining('left today'), findsNothing);
  });
}
