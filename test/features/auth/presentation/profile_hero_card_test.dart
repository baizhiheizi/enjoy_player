import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/profile_hero_card.dart';
import 'package:enjoy_player/features/library/domain/learning_statistics.dart';
import 'package:enjoy_player/features/subscription/application/current_tier_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const _profile = UserProfile(
  id: '24000001',
  email: 'reader@example.com',
  name: 'Reader',
);

class _FakeAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedIn(profile: _profile);
}

Widget _themed({required List<Override> overrides, required Widget child}) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      locale: const Locale('en', 'US'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows Enjoy ID instead of email on secondary line', (
    tester,
  ) async {
    await tester.pumpWidget(
      _themed(
        overrides: [authCtrlProvider.overrideWith(_FakeAuthCtrl.new)],
        child: const ProfileHeroCard(profile: _profile),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2400 0001'), findsOneWidget);
    expect(find.text('reader@example.com'), findsNothing);
    expect(find.text('Reader'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
  });

  testWidgets('tier badge hugs the name row instead of stretching', (
    tester,
  ) async {
    await tester.pumpWidget(
      _themed(
        overrides: [authCtrlProvider.overrideWith(_FakeAuthCtrl.new)],
        child: const ProfileHeroCard(profile: _profile),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Free'), findsOneWidget);
    final badge = find
        .ancestor(of: find.text('Free'), matching: find.byType(Container))
        .first;
    expect(tester.getSize(badge).width, lessThan(120));
  });

  testWidgets('pro tier swaps the badge tint and drops the upgrade button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _themed(
        overrides: [
          authCtrlProvider.overrideWith(_FakeAuthCtrl.new),
          currentTierProvider.overrideWithValue(SubscriptionTier.pro),
        ],
        child: const ProfileHeroCard(profile: _profile),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pro'), findsOneWidget);
    expect(find.text('Upgrade to Pro'), findsNothing);
  });

  testWidgets('credits card shows upgrade CTA and low caption at 90%', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    await tester.pumpWidget(
      _themed(
        overrides: const [],
        child: const ProfileCreditsCard(
          used: 950,
          limit: 1000,
          permanent: null,
          tier: SubscriptionTier.free,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.profileCreditsRunningLow), findsOneWidget);
    expect(find.text(l10n.subscriptionUpgradeShort), findsOneWidget);
    expect(find.text(l10n.profileCreditsUsageLink), findsOneWidget);
  });

  testWidgets('credits card stays neutral below the low threshold', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    await tester.pumpWidget(
      _themed(
        overrides: const [],
        child: const ProfileCreditsCard(
          used: 640,
          limit: 1000,
          permanent: 2400,
          tier: SubscriptionTier.free,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.profileCreditsRunningLow), findsNothing);
    expect(find.text(l10n.subscriptionUpgradeShort), findsNothing);
    expect(
      find.text(l10n.profileCreditsResetsWithPermanent('2,400')),
      findsOneWidget,
    );
  });

  testWidgets('practice card hints while every stat is zero', (tester) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    await tester.pumpWidget(
      _themed(
        overrides: const [],
        child: ProfilePracticeCard(stats: LearningStatistics.empty()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.profilePracticeEmptyHint), findsOneWidget);
  });

  testWidgets('practice card omits the hint once a stat is nonzero', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    await tester.pumpWidget(
      _themed(
        overrides: const [],
        child: const ProfilePracticeCard(
          stats: LearningStatistics(
            today: PeriodStats(recordingDurationMs: 60000, recordingCount: 1),
            week: PeriodStats(recordingDurationMs: 60000, recordingCount: 1),
            month: PeriodStats(recordingDurationMs: 60000, recordingCount: 1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.profilePracticeEmptyHint), findsNothing);
  });

  test('formatEnjoyId groups numeric ids and leaves others alone', () {
    expect(formatEnjoyId('10482231'), '1048 2231');
    expect(formatEnjoyId('42'), '42');
    expect(formatEnjoyId('u1_x'), 'u1_x');
  });
}
