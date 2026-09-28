import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/sign_in_screen.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

class _SignedOutAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedOut();
}

Widget _harness(Widget child, {List<Override> overrides = const []}) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
  return ProviderScope(
    overrides: [
      authCtrlProvider.overrideWith(_SignedOutAuthCtrl.new),
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
  testWidgets('shows welcome copy on sign-in hub', (tester) async {
    await tester.pumpWidget(_harness(const SignInScreen()));
    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.authSignInTitle), findsOneWidget);
    expect(find.text(l10n.authSignInSubtitle), findsOneWidget);
    expect(find.text(l10n.authContinueWithEmail), findsOneWidget);
  });

  testWidgets('does not offer cancel or close escape to home', (tester) async {
    await tester.pumpWidget(_harness(const SignInScreen()));
    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.byIcon(EnjoyIcons.close), findsNothing);
    expect(find.text(l10n.authCancel), findsNothing);
  });
}
