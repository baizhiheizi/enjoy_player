/// OAuth PKCE callback URI parsing for Enjoy account auth.
library;

class AuthCallbackParams {
  const AuthCallbackParams({required this.code, required this.state});

  final String code;
  final String state;
}

bool isAuthCallbackUri(Uri uri) {
  if (uri.scheme == 'enjoyplayer' &&
      uri.host == 'auth' &&
      uri.path == '/callback') {
    return true;
  }
  if (uri.scheme == 'https' &&
      uri.host == 'enjoy.bot' &&
      uri.path == '/app/auth/callback') {
    return true;
  }
  return false;
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
