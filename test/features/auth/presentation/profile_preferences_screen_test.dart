import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/auth/presentation/profile_preferences_screen.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const _profile = UserProfile(
  id: 'user-1',
  email: 'reader@example.com',
  name: 'Reader',
  goal: 30,
);

class _FakeAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedIn(profile: _profile);
}

class _FakePrefsCtrl extends AppPreferencesCtrl {
  @override
  Future<AppPreferencesState> build() async => AppPreferencesState.initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('preferences has no username field', (tester) async {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authCtrlProvider.overrideWith(_FakeAuthCtrl.new),
          appPreferencesCtrlProvider.overrideWith(_FakePrefsCtrl.new),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: scheme,
            useMaterial3: true,
            extensions: [EnjoyThemeTokens.build(scheme)],
          ),
          locale: const Locale('en', 'US'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProfilePreferencesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en', 'US'));

    expect(find.text(l10n.profileFieldName), findsNothing);
    expect(find.text(l10n.profileFieldGoal), findsOneWidget);
  });
}
