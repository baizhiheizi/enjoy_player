import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_section_auth_gate.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_section_shimmer.dart';
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
  Future<AuthState> build() async {
    return Completer<AuthState>().future;
  }
}

/// First build emits a signed-in state; a later rebuild (invalidate /
/// refresh) fails, leaving an error state whose previous value is still
/// the signed-in one.
class _AuthRefreshFailCtrl extends AuthCtrl {
  bool _threw = false;

  @override
  Future<AuthState> build() async {
    if (_threw) {
      throw StateError('refresh blew up');
    }
    _threw = true;
    return const AuthSignedIn(
      profile: UserProfile(
        id: 'test-user',
        email: 't@example.com',
        name: 'Test',
      ),
    );
  }
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

void main() {
  const childMarker = Key('gate-child');

  testWidgets('renders the child when signed in (pass-through)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        overrides: [authCtrlProvider.overrideWith(_AuthSignedInCtrl.new)],
        child: const LookupSectionAuthGate(
          surface: AuthRequiredSurface.lookupTranslation,
          child: SizedBox(key: childMarker),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(childMarker), findsOneWidget);
    expect(find.byType(AuthRequiredCallout), findsNothing);
    expect(find.byType(LookupSectionShimmer), findsNothing);
  });

  testWidgets('renders AuthRequiredCallout when signed out', (tester) async {
    await tester.pumpWidget(
      _app(
        overrides: [authCtrlProvider.overrideWith(_AuthSignedOutCtrl.new)],
        child: const LookupSectionAuthGate(
          surface: AuthRequiredSurface.lookupDictionary,
          child: SizedBox(key: childMarker),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(childMarker), findsNothing);
    expect(find.byType(AuthRequiredCallout), findsOneWidget);
  });

  testWidgets('renders shimmer while auth is loading', (tester) async {
    await tester.pumpWidget(
      _app(
        overrides: [authCtrlProvider.overrideWith(_AuthLoadingCtrl.new)],
        child: const LookupSectionAuthGate(
          surface: AuthRequiredSurface.lookupContextual,
          child: SizedBox(key: childMarker),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(childMarker), findsNothing);
    expect(find.byType(LookupSectionShimmer), findsOneWidget);
    expect(find.byType(AuthRequiredCallout), findsNothing);
  });

  testWidgets('renders AuthRequiredCallout when auth resolves to an error', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        overrides: [authCtrlProvider.overrideWith(_AuthErrorCtrl.new)],
        child: const LookupSectionAuthGate(
          surface: AuthRequiredSurface.lookupTranslation,
          child: SizedBox(key: childMarker),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(childMarker), findsNothing);
    expect(find.byType(AuthRequiredCallout), findsOneWidget);
  });

  testWidgets('a failed refresh that still carries a signed-in previous value '
      'renders the callout, not the child (issue #827 C1 review)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        overrides: [authCtrlProvider.overrideWith(_AuthRefreshFailCtrl.new)],
        child: const LookupSectionAuthGate(
          surface: AuthRequiredSurface.lookupTranslation,
          child: SizedBox(key: childMarker),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(childMarker), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LookupSectionAuthGate)),
    );
    container.invalidate(authCtrlProvider);
    await tester.pumpAndSettle();

    expect(
      find.byKey(childMarker),
      findsNothing,
      reason:
          'terminal error must gate the child even when the '
          'previous value was signed in',
    );
    expect(find.byType(AuthRequiredCallout), findsOneWidget);
  });
}
