import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/ai/domain/models/translation_result.dart';
import 'package:enjoy_player/features/lookup/application/lookup_section_providers.dart';
import 'package:enjoy_player/features/lookup/domain/lookup_request.dart';
import 'package:enjoy_player/features/lookup/presentation/sections/translation_lookup_section.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class _AuthSignedOutCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedOut();
}

class _AuthSignedInCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedIn(
        profile: UserProfile(
          id: 'test-user',
          email: 't@example.com',
          name: 'Test',
        ),
      );
}

Widget _appWithRouter({
  required Widget child,
  required List<Override> overrides,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(body: child),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => Scaffold(
          body: Text(
            'sign-in-page from=${state.uri.queryParameters['from'] ?? ''}',
          ),
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  testWidgets('AuthRequiredCallout compact shows sign-in CTA when signed out', (
    tester,
  ) async {
    await tester.pumpWidget(
      _appWithRouter(
        overrides: [
          authCtrlProvider.overrideWith(_AuthSignedOutCtrl.new),
        ],
        child: const Center(
          child: AuthRequiredCallout(
            surface: AuthRequiredSurface.lookupTranslation,
            compact: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final ctx = tester.element(find.byType(AuthRequiredCallout));
    final loc = AppLocalizations.of(ctx)!;
    expect(find.text(loc.syncScreenGoSignIn), findsOneWidget);
    expect(find.text(loc.authRequiredCloudFeaturesTitle), findsOneWidget);
  });

  testWidgets('TranslationLookupSection does not load translation when signed out', (
    tester,
  ) async {
    var translationCalled = false;
    await tester.pumpWidget(
      _appWithRouter(
        overrides: [
          authCtrlProvider.overrideWith(_AuthSignedOutCtrl.new),
          lookupSheetTranslationProvider.overrideWith(
            (ref, params) async {
              translationCalled = true;
              return const TranslationResult(
                translatedText: 'should-not-appear',
                targetLanguage: 'en',
              );
            },
          ),
        ],
        child: const TranslationLookupSection(
          request: LookupRequest(
            selectedText: 'hello',
            sourceLanguage: 'en',
            targetLanguage: 'zh',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(translationCalled, isFalse);
    expect(find.text('should-not-appear'), findsNothing);
  });

  testWidgets('TranslationLookupSection shows translation when signed in', (
    tester,
  ) async {
    await tester.pumpWidget(
      _appWithRouter(
        overrides: [
          authCtrlProvider.overrideWith(_AuthSignedInCtrl.new),
          lookupSheetTranslationProvider.overrideWith(
            (ref, params) async => const TranslationResult(
              translatedText: 'from-test-override',
              targetLanguage: 'zh',
            ),
          ),
        ],
        child: const TranslationLookupSection(
          request: LookupRequest(
            selectedText: 'hello',
            sourceLanguage: 'en',
            targetLanguage: 'zh',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('from-test-override'), findsOneWidget);
  });
}
