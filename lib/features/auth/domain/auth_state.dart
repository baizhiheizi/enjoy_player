/// High-level auth / session state for the UI.
library;

import 'package:enjoy_player/features/auth/domain/user_profile.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

/// User entered email; waiting for OTP entry.
final class AuthAwaitingOtp extends AuthState {
  const AuthAwaitingOtp({
    required this.requestId,
    required this.email,
    required this.resendAfterSeconds,
    required this.startedAt,
  });

  final String requestId;
  final String email;
  final int resendAfterSeconds;
  final DateTime startedAt;
}

/// OAuth PKCE web fallback — waiting for deep-link callback.
final class AuthSigningInWebPkce extends AuthState {
  const AuthSigningInWebPkce({
    required this.oauthState,
    required this.codeVerifier,
    required this.redirectUri,
    required this.startedAt,
  });

  final String oauthState;
  final String codeVerifier;
  final String redirectUri;
  final DateTime startedAt;
}

final class AuthSignedIn extends AuthState {
  const AuthSignedIn({required this.profile});

  final UserProfile profile;
}

/// True while any in-flight sign-in flow is active.
bool authFlowInProgress(AuthState state) =>
    state is AuthAwaitingOtp || state is AuthSigningInWebPkce;
