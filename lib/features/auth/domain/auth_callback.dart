/// OAuth PKCE callback URI parsing for Enjoy account auth.
library;

import 'package:enjoy_player/core/application/app_links.dart';

class AuthCallbackParams {
  const AuthCallbackParams({required this.code, required this.state});

  final String code;
  final String state;
}

bool isAuthCallbackUri(Uri uri) {
  return uri.scheme == kEnjoyPlayerUrlScheme &&
      uri.host == 'auth' &&
      uri.path == '/callback';
}

AuthCallbackParams? parseAuthCallbackUri(Uri uri) {
  if (!isAuthCallbackUri(uri)) return null;
  final state = uri.queryParameters['state'];
  final code = uri.queryParameters['code'];
  if (state == null || state.isEmpty || code == null || code.isEmpty) {
    return null;
  }
  return AuthCallbackParams(code: code, state: state);
}
