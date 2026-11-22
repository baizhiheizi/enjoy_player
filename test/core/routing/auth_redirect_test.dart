import 'dart:io';

import 'package:enjoy_player/core/routing/auth_redirect.dart';
import 'package:enjoy_player/core/routing/route_paths.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _profile = UserProfile(
  id: 'user-1',
  email: 'test@example.com',
  name: 'Test User',
);

void main() {
  group('isNativeAuthCallbackArtifact', () {
    test('matches the go_router path for an auto-forwarded auth callback', () {
      expect(isNativeAuthCallbackArtifact('/callback'), isTrue);
    });

    test('does not match real app routes', () {
      expect(isNativeAuthCallbackArtifact('/'), isFalse);
      expect(isNativeAuthCallbackArtifact('/sign-in'), isFalse);
      expect(isNativeAuthCallbackArtifact('/auth/callback'), isFalse);
    });
  });

  group('encodeSignInFrom', () {
    test('profile and credits shorthands', () {
      expect(encodeSignInFrom('/profile'), 'profile');
      expect(encodeSignInFrom('/profile/edit'), 'profile_edit');
      expect(encodeSignInFrom('/profile/preferences'), 'profile_preferences');
      expect(encodeSignInFrom('/credits'), 'credits');
      expect(encodeSignInFrom('/subscription'), 'subscription');
    });

    test('encodes other paths', () {
      expect(encodeSignInFrom('/library'), '%2Flibrary');
      expect(encodeSignInFrom('/player/abc'), '%2Fplayer%2Fabc');
    });
  });

  group('resolvePostSignInPath', () {
    test('defaults to home', () {
      expect(resolvePostSignInPath(null), '/');
      expect(resolvePostSignInPath(''), '/');
      expect(resolvePostSignInPath('   '), '/');
    });

    test('shorthand targets', () {
      expect(resolvePostSignInPath('profile'), '/profile');
      expect(resolvePostSignInPath('profile_edit'), '/profile/edit');
      expect(
        resolvePostSignInPath('profile_preferences'),
        '/profile/preferences',
      );
      expect(resolvePostSignInPath('credits'), '/credits');
      expect(resolvePostSignInPath('subscription'), '/subscription');
    });

    test('profile surface tags round-trip to their routes', () {
      expect(AuthRequiredSurface.profileEdit.fromQueryParam, 'profile_edit');
      expect(
        AuthRequiredSurface.profilePreferences.fromQueryParam,
        'profile_preferences',
      );
      expect(
        resolvePostSignInPath(AuthRequiredSurface.profileEdit.fromQueryParam),
        '/profile/edit',
      );
      expect(
        resolvePostSignInPath(
          AuthRequiredSurface.profilePreferences.fromQueryParam,
        ),
        '/profile/preferences',
      );
    });

    test('encoded full paths', () {
      expect(resolvePostSignInPath('%2Flibrary'), '/library');
      expect(resolvePostSignInPath('%2Fplayer%2Fabc'), '/player/abc');
    });

    test('rejects sign-in paths', () {
      expect(resolvePostSignInPath('%2Fsign-in'), '/');
    });
  });

  group('resolveAuthRedirect', () {
    test('signed-out protected routes redirect with from', () {
      expect(
        resolveAuthRedirect(
          matchedLocation: '/',
          auth: const AsyncData(AuthSignedOut()),
        ),
        '/sign-in?from=%2F',
      );
      expect(
        resolveAuthRedirect(
          matchedLocation: '/library',
          auth: const AsyncData(AuthSignedOut()),
        ),
        '/sign-in?from=%2Flibrary',
      );
      expect(
        resolveAuthRedirect(
          matchedLocation: '/profile',
          auth: const AsyncData(AuthSignedOut()),
        ),
        '/sign-in?from=profile',
      );
    });

    test('auth loading stays on protected routes (no sign-in flash)', () {
      expect(
        resolveAuthRedirect(matchedLocation: '/', auth: const AsyncLoading()),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          matchedLocation: '/discover',
          auth: const AsyncLoading(),
        ),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          matchedLocation: '/player/abc',
          auth: const AsyncLoading(),
        ),
        isNull,
      );
    });

    test('auth loading allows sign-in routes', () {
      expect(
        resolveAuthRedirect(
          matchedLocation: '/sign-in',
          auth: const AsyncLoading(),
        ),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          matchedLocation: '/sign-in/email',
          auth: const AsyncLoading(),
        ),
        isNull,
      );
    });

    test('signed-in users skip gate for app routes', () {
      const signedIn = AsyncData(AuthSignedIn(profile: _profile));
      expect(resolveAuthRedirect(matchedLocation: '/', auth: signedIn), isNull);
      expect(
        resolveAuthRedirect(matchedLocation: '/library', auth: signedIn),
        isNull,
      );
      expect(
        resolveAuthRedirect(matchedLocation: '/settings', auth: signedIn),
        isNull,
      );
    });

    test('signed-in users bounce off sign-in routes', () {
      const signedIn = AsyncData(AuthSignedIn(profile: _profile));
      expect(
        resolveAuthRedirect(matchedLocation: '/sign-in', auth: signedIn),
        '/',
      );
      expect(
        resolveAuthRedirect(matchedLocation: '/sign-in/email', auth: signedIn),
        '/',
      );
    });

    test('signed-out users stay on sign-in routes', () {
      expect(
        resolveAuthRedirect(
          matchedLocation: '/sign-in',
          auth: const AsyncData(AuthSignedOut()),
        ),
        isNull,
      );
    });

    test('auth error still redirects protected routes to sign-in', () {
      expect(
        resolveAuthRedirect(
          matchedLocation: '/settings',
          auth: AsyncError(Exception('network'), StackTrace.empty),
        ),
        '/sign-in?from=%2Fsettings',
      );
    });

    test('youtube login is gated when signed out', () {
      expect(
        resolveAuthRedirect(
          matchedLocation: '/youtube/login',
          auth: const AsyncData(AuthSignedOut()),
        ),
        '/sign-in?from=%2Fyoutube%2Flogin',
      );
    });
  });

  group('checkout return deep link helpers', () {
    test('isCheckoutReturnArtifact matches go_router /return paths', () {
      expect(isCheckoutReturnArtifact('/return'), isTrue);
      expect(isCheckoutReturnArtifact('/return/'), isTrue);
      expect(isCheckoutReturnArtifact('/subscription'), isFalse);
      expect(isCheckoutReturnArtifact('/checkout/return'), isFalse);
    });

    test('isCheckoutReturnUri identifies checkout return scheme/host/path', () {
      expect(
        isCheckoutReturnUri(
          Uri.parse(
            'enjoyplayer://checkout/return?result=success&kind=credits_package',
          ),
        ),
        isTrue,
      );
      expect(
        isCheckoutReturnUri(Uri.parse('enjoyplayer://checkout/return/')),
        isTrue,
      );
      expect(
        isCheckoutReturnUri(
          Uri.parse('enjoyplayer://auth/callback?code=c&state=s'),
        ),
        isFalse,
      );
      expect(
        isCheckoutReturnUri(Uri.parse('https://enjoy.bot/checkout/return')),
        isFalse,
      );
      expect(
        isCheckoutReturnUri(Uri.parse('enjoyplayer://other/return')),
        isFalse,
      );
      expect(
        isCheckoutReturnUri(Uri.parse('enjoyplayer://checkout/other')),
        isFalse,
      );
    });

    test(
      'checkoutReturnTarget maps credits_package to /credits and others to /subscription',
      () {
        expect(
          checkoutReturnTarget(
            Uri.parse(
              'enjoyplayer://checkout/return?result=success&kind=credits_package',
            ),
          ),
          kCreditsRoutePath,
        );
        expect(
          checkoutReturnTarget(
            Uri.parse(
              'enjoyplayer://checkout/return?result=success&kind=auto_renew',
            ),
          ),
          kSubscriptionRoutePath,
        );
        expect(
          checkoutReturnTarget(
            Uri.parse(
              'enjoyplayer://checkout/return?result=cancel&kind=subscription',
            ),
          ),
          kSubscriptionRoutePath,
        );
        expect(
          checkoutReturnTarget(Uri.parse('enjoyplayer://checkout/return')),
          kSubscriptionRoutePath,
        );
      },
    );

    test('resolveCheckoutReturnRedirect respects auth state and target', () {
      const signedIn = AsyncData<AuthState>(AuthSignedIn(profile: _profile));
      const signedOut = AsyncData<AuthState>(AuthSignedOut());
      const loading = AsyncLoading<AuthState>();

      expect(
        resolveCheckoutReturnRedirect(
          matchedLocation: '/return',
          uri: Uri.parse(
            'enjoyplayer://checkout/return?result=success&kind=credits_package',
          ),
          auth: signedIn,
        ),
        '/credits',
      );
      expect(
        resolveCheckoutReturnRedirect(
          matchedLocation: '/return',
          uri: Uri.parse(
            'enjoyplayer://checkout/return?result=success&kind=subscription',
          ),
          auth: signedIn,
        ),
        '/subscription',
      );
      expect(
        resolveCheckoutReturnRedirect(
          matchedLocation: '/return',
          uri: Uri.parse(
            'enjoyplayer://checkout/return?result=success&kind=credits_package',
          ),
          auth: signedOut,
        ),
        '/sign-in?from=credits',
      );
      expect(
        resolveCheckoutReturnRedirect(
          matchedLocation: '/return',
          uri: Uri.parse('enjoyplayer://checkout/return'),
          auth: loading,
        ),
        '/subscription',
      );
      expect(
        resolveCheckoutReturnRedirect(
          matchedLocation: '/library',
          uri: Uri.parse('/library'),
          auth: signedIn,
        ),
        isNull,
      );
    });

    testWidgets(
      'GoRouter redirects /return deep links to billing destination',
      (tester) async {
        AsyncValue<AuthState> currentAuth = const AsyncData<AuthState>(
          AuthSignedIn(profile: _profile),
        );
        final router = GoRouter(
          initialLocation: '/return?result=success&kind=credits_package',
          redirect: (context, state) {
            return resolveCheckoutReturnRedirect(
                  matchedLocation: state.matchedLocation,
                  uri: state.uri,
                  auth: currentAuth,
                ) ??
                resolveAuthRedirect(
                  matchedLocation: state.matchedLocation,
                  auth: currentAuth,
                );
          },
          routes: [
            GoRoute(
              path: '/subscription',
              builder: (_, _) => const Text('subscription-page'),
            ),
            GoRoute(
              path: '/credits',
              builder: (_, _) => const Text('credits-page'),
            ),
            GoRoute(
              path: '/sign-in',
              builder: (_, state) =>
                  Text('sign-in:${state.uri.queryParameters['from']}'),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
        expect(find.text('credits-page'), findsOneWidget);

        router.go('/return?result=success&kind=auto_renew');
        await tester.pumpAndSettle();
        expect(find.text('subscription-page'), findsOneWidget);

        currentAuth = const AsyncData<AuthState>(AuthSignedOut());
        router.go('/return?result=success&kind=credits_package');
        await tester.pumpAndSettle();
        expect(find.text('sign-in:credits'), findsOneWidget);
      },
    );

    test(
      'AndroidManifest registers intent-filters for auth/callback and checkout/return',
      () {
        final manifest = File('android/app/src/main/AndroidManifest.xml');
        expect(manifest.existsSync(), isTrue);
        final xml = manifest.readAsStringSync();
        expect(xml, contains('android:scheme="enjoyplayer"'));
        expect(xml, contains('android:host="auth"'));
        expect(xml, contains('android:path="/callback"'));
        expect(xml, contains('android:host="checkout"'));
        expect(xml, contains('android:path="/return"'));
      },
    );
  });
}
