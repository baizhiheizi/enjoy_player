import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/signed_in_gate.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class _AuthSignedOutCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedOut();
}

class _AuthSignedInCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedIn(
    profile: UserProfile(id: 'test-user', email: 't@example.com', name: 'Test'),
  );
}

class _AuthErrorCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => throw StateError('auth blew up');
}

class _AuthLoadingCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => Completer<AuthState>().future;
}

Widget _app({required List<Override> overrides, required Widget child}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

Widget _gate() {
  return SignedInGate(
    surface: AuthRequiredSurface.subscription,
    loading: const SizedBox(key: Key('gate-loading')),
    builder: (context, state) => Text(state.profile.name),
  );
}

void main() {
  testWidgets('renders the builder when signed in', (tester) async {
    await tester.pumpWidget(
      _app(
        overrides: [authCtrlProvider.overrideWith(_AuthSignedInCtrl.new)],
        child: _gate(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test'), findsOneWidget);
    expect(find.byType(AuthRequiredCallout), findsNothing);
  });

  testWidgets('renders the full callout when signed out', (tester) async {
    await tester.pumpWidget(
      _app(
        overrides: [authCtrlProvider.overrideWith(_AuthSignedOutCtrl.new)],
        child: _gate(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuthRequiredCallout), findsOneWidget);
    expect(find.text('Test'), findsNothing);
  });

  testWidgets('renders the supplied loading widget while auth resolves', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        overrides: [authCtrlProvider.overrideWith(_AuthLoadingCtrl.new)],
        child: _gate(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('gate-loading')), findsOneWidget);
    expect(find.byType(AuthRequiredCallout), findsNothing);
  });

  testWidgets('renders the localized failure instead of the raw exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        overrides: [authCtrlProvider.overrideWith(_AuthErrorCtrl.new)],
        child: _gate(),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(SignedInGate)),
    )!;
    expect(find.text(l10n.errorGenericLoadFailed), findsOneWidget);
    expect(find.textContaining('auth blew up'), findsNothing);
  });
}
