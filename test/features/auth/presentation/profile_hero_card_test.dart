import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/profile_hero_card.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows Enjoy ID instead of email on secondary line', (
    tester,
  ) async {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authCtrlProvider.overrideWith(_FakeAuthCtrl.new)],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: scheme,
            useMaterial3: true,
            extensions: [EnjoyThemeTokens.build(scheme)],
          ),
          locale: const Locale('en', 'US'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ProfileHeroCard(profile: _profile)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2400 0001'), findsOneWidget);
    expect(find.text('reader@example.com'), findsNothing);
    expect(find.text('Reader'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
  });

  test('formatEnjoyId groups numeric ids and leaves others alone', () {
    expect(formatEnjoyId('10482231'), '1048 2231');
    expect(formatEnjoyId('42'), '42');
    expect(formatEnjoyId('u1_x'), 'u1_x');
  });
}
