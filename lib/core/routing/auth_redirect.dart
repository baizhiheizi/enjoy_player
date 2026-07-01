/// Pure auth-gate redirect rules for [GoRouter] (login-only app access).
library;

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Routes reachable without a signed-in Enjoy account session.
const signInAllowlistedLocations = <String>{
  '/sign-in',
  '/sign-in/email',
};

/// Returns `true` when [matchedLocation] is the sign-in hub or email OTP sub-route.
bool isSignInAllowlisted(String matchedLocation) {
  return signInAllowlistedLocations.contains(matchedLocation);
}

/// Matches the location go_router derives if the OS ever auto-forwards the
/// custom-scheme PKCE redirect (`enjoyplayer://auth/callback`) as an initial
/// route before `AuthDeepLinkListener` can process it via app_links.
///
/// go_router's top-level redirect only sees the URI's `path` component, so
/// `enjoyplayer://auth/callback?code=...&state=...` becomes matchedLocation
/// `/callback`. No app route is registered at that path; treat it like `/`
/// so users land on home (or sign-in, if the token exchange hasn't finished
/// yet) instead of a "Page not found" screen.
bool isNativeAuthCallbackArtifact(String matchedLocation) =>
    matchedLocation == '/callback';

/// Returns `true` when the user has an active Enjoy account session.
bool isAuthenticated(AuthState? state) => state is AuthSignedIn;

/// Encodes a protected path into the sign-in `from` query value.
String encodeSignInFrom(String matchedLocation) {
  switch (matchedLocation) {
    case '/profile':
      return 'profile';
    case '/credits':
      return 'credits';
    case '/subscription':
      return 'subscription';
    default:
      return Uri.encodeComponent(matchedLocation);
  }
}

/// Builds `/sign-in` with an optional `from` query for post-auth navigation.
String buildSignInRedirect(String matchedLocation) {
  if (matchedLocation == '/sign-in') return '/sign-in';
  final from = encodeSignInFrom(matchedLocation);
  return '/sign-in?from=$from';
}

/// Resolves the post-sign-in navigation target from a `from` query parameter.
String resolvePostSignInPath(String? from) {
  final trimmed = from?.trim();
  if (trimmed == null || trimmed.isEmpty) return '/';
  switch (trimmed) {
    case 'profile':
      return '/profile';
    case 'credits':
      return '/credits';
    case 'subscription':
      return '/subscription';
    default:
      final decoded = Uri.decodeComponent(trimmed);
      if (decoded.startsWith('/') && !decoded.startsWith('/sign-in')) {
        return decoded;
      }
      return '/';
  }
}

/// Auth redirect target, or `null` when [matchedLocation] should render as-is.
///
/// Platform-specific redirects (cloud library alias, keyboard settings, etc.)
/// are handled in [app_router.dart] before this helper runs.
String? resolveAuthRedirect({
  required String matchedLocation,
  required AsyncValue<AuthState> auth,
}) {
  if (isSignInAllowlisted(matchedLocation)) {
    if (auth.isLoading || auth.hasError) return null;
    if (isAuthenticated(auth.valueOrNull)) return '/';
    return null;
  }

  if (auth.isLoading || auth.hasError) {
    return buildSignInRedirect(matchedLocation);
  }

  if (isAuthenticated(auth.valueOrNull)) return null;

  return buildSignInRedirect(matchedLocation);
}
