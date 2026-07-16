import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/update_profile_request.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/auth/presentation/profile_edit_screen.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const _profile = UserProfile(
  id: '24000001',
  email: 'reader@example.com',
  name: 'Reader',
  mixinId: null,
);

class _FakeAuthCtrl extends AuthCtrl {
  UpdateProfileRequest? lastRequest;
  Object? updateProfileError;

  @override
  Future<AuthState> build() async => const AuthSignedIn(profile: _profile);

  @override
  Future<void> updateProfile(UpdateProfileRequest request) async {
    lastRequest = request;
    if (updateProfileError != null) {
      throw updateProfileError!;
    }
    state = AsyncData(
      AuthSignedIn(profile: _profile.copyWith(name: request.name)),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget harness(_FakeAuthCtrl auth) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
    return ProviderScope(
      overrides: [authCtrlProvider.overrideWith(() => auth)],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: scheme,
          useMaterial3: true,
          extensions: [EnjoyThemeTokens.build(scheme)],
        ),
        locale: const Locale('en', 'US'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ProfileEditScreen(),
      ),
    );
  }

  testWidgets('shows read-only identity and editable username', (tester) async {
    final auth = _FakeAuthCtrl();
    await tester.pumpWidget(harness(auth));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en', 'US'));

    expect(find.text(l10n.profileEditTitle), findsOneWidget);
    expect(find.text('24000001'), findsOneWidget);
    expect(find.text('reader@example.com'), findsOneWidget);
    expect(find.text(l10n.profileMixinNotLinked), findsOneWidget);
    expect(find.text(l10n.profileFieldName), findsOneWidget);

    // Enjoy ID / email / Mixin are SelectableText, not TextFormFields.
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('saves username via updateProfile', (tester) async {
    final auth = _FakeAuthCtrl();
    await tester.pumpWidget(harness(auth));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en', 'US'));

    await tester.enterText(find.byType(TextFormField), 'NewName');
    await tester.tap(find.text(l10n.profileSave));
    await tester.pumpAndSettle();

    expect(auth.lastRequest?.name, 'NewName');
  });

  testWidgets('username save failure shows generic error, not avatar error', (
    tester,
  ) async {
    final auth = _FakeAuthCtrl()..updateProfileError = Exception('network');
    await tester.pumpWidget(harness(auth));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en', 'US'));

    await tester.enterText(find.byType(TextFormField), 'NewName');
    await tester.tap(find.text(l10n.profileSave));
    await tester.pumpAndSettle();

    expect(find.text(l10n.errorGenericLoadFailed), findsOneWidget);
    expect(find.text(l10n.profileAvatarUploadFailed), findsNothing);
  });
}
