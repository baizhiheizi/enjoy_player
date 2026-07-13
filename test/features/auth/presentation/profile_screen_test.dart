import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/application/profile_practice_stats_provider.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/auth/presentation/profile_screen.dart';
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
  @override
  Future<AuthState> build() async => const AuthSignedIn(profile: _fakeProfile);
}

class _SignedOutAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedOut();
}

class _FakePrefsCtrl extends AppPreferencesCtrl {
  @override
  Future<AppPreferencesState> build() async => AppPreferencesState.initial;
}

Widget _harness(Widget child, AuthCtrl authCtrl) {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'ProfileScreen renders without Scaffold or AppBar (tab chrome-free)',
    (tester) async {
      final authCtrl = _FakeAuthCtrl();
      await tester.pumpWidget(_harness(const ProfileScreen(), authCtrl));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileContent), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
    },
  );

  testWidgets(
    'ProfileScreen signed-out state shows sign-in prompt',
    (tester) async {
      final authCtrl = _SignedOutAuthCtrl();
      await tester.pumpWidget(_harness(const ProfileScreen(), authCtrl));
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(
        const Locale('en', 'US'),
      );
      expect(find.text(l10n.authSignInTitle), findsOneWidget);
    },
  );
}
