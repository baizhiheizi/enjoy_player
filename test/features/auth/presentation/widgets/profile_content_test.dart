import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/application/profile_practice_stats_provider.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/profile_content.dart';
import 'package:enjoy_player/features/library/domain/learning_statistics.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const _fakeProfile = UserProfile(
  id: 'user-1',
  email: 'reader@example.com',
  name: 'Reader',
  balance: 12.5,
);

class _FakeAuthCtrl extends AuthCtrl {
  int refreshCount = 0;

  @override
  Future<AuthState> build() async => const AuthSignedIn(profile: _fakeProfile);

  @override
  Future<void> refreshProfile() async {
    refreshCount++;
  }
}

class _FakePrefsCtrl extends AppPreferencesCtrl {
  @override
  Future<AppPreferencesState> build() async => AppPreferencesState.initial;
}

Widget _harness(Widget child, {required _FakeAuthCtrl authCtrl}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7B61FF),
    brightness: Brightness.dark,
  );
  return ProviderScope(
    overrides: [
      authCtrlProvider.overrideWith(() => authCtrl),
      appPreferencesCtrlProvider.overrideWith(_FakePrefsCtrl.new),
      profilePracticeStatsProvider.overrideWith(
        (ref) async => LearningStatistics.empty(),
      ),
    ],
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        brightness: Brightness.dark,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      locale: const Locale('en', 'US'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

/// Scrolls the nearest [Scrollable] until [finder] is on-screen. The profile
/// list is long enough that the sign-out button starts below the fold.
Future<void> _scrollUntilVisible(WidgetTester tester, Finder finder) async {
  final scrollable = find.byType(Scrollable).first;
  for (var i = 0; i < 20 && finder.evaluate().isEmpty; i++) {
    await tester.drag(scrollable, const Offset(0, -300));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'ProfileContent renders with RefreshIndicator and scrollable list, '
    'suitable for the Profile tab',
    (tester) async {
      final authCtrl = _FakeAuthCtrl();
      await tester.pumpWidget(
        _harness(const ProfileContent(), authCtrl: authCtrl),
      );
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(
        const Locale('en', 'US'),
      );

      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byTooltip(l10n.profileRefreshTooltip), findsNothing);

      await _scrollUntilVisible(tester, find.text(l10n.authSignOut));
      expect(find.text(l10n.authSignOut), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ProfileContent shows Settings entry tile with gear icon and navigates '
    'to /settings',
    (tester) async {
      final authCtrl = _FakeAuthCtrl();
      await tester.pumpWidget(
        _harness(const ProfileContent(), authCtrl: authCtrl),
      );
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(
        const Locale('en', 'US'),
      );

      await _scrollUntilVisible(tester, find.text(l10n.settingsTitle));
      expect(find.text(l10n.settingsTitle), findsWidgets);
      expect(find.byIcon(Icons.settings_outlined), findsWidgets);
    },
  );
}
