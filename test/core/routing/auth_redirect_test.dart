import 'package:enjoy_player/core/routing/auth_redirect.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _profile = UserProfile(
  id: 'user-1',
  email: 'test@example.com',
  name: 'Test User',
);

void main() {
  group('encodeSignInFrom', () {
    test('profile and credits shorthands', () {
      expect(encodeSignInFrom('/profile'), 'profile');
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
      expect(resolvePostSignInPath('credits'), '/credits');
      expect(resolvePostSignInPath('subscription'), '/subscription');
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

    test('auth loading redirects protected routes to sign-in', () {
      expect(
        resolveAuthRedirect(
          matchedLocation: '/',
          auth: const AsyncLoading(),
        ),
        '/sign-in?from=%2F',
      );
      expect(
        resolveAuthRedirect(
          matchedLocation: '/discover',
          auth: const AsyncLoading(),
        ),
        '/sign-in?from=%2Fdiscover',
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
      expect(
        resolveAuthRedirect(matchedLocation: '/', auth: signedIn),
        isNull,
      );
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

    test('auth error redirects like loading', () {
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
}
