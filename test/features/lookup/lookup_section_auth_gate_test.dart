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
    // Never completes — keeps the provider in the loading state.
    return Completer<AuthState>().future;
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
    // One frame only — the provider future never resolves.
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
}
