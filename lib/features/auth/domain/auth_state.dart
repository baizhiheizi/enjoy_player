/// High-level auth / session state for the UI.
library;

import 'package:enjoy_player/features/auth/domain/user_profile.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

final class AuthSigningIn extends AuthState {
  const AuthSigningIn({
    required this.requestId,
    required this.verificationUrl,
    required this.startedAt,
  });

  final String requestId;
  final String verificationUrl;
  final DateTime startedAt;
}

final class AuthSignedIn extends AuthState {
  const AuthSignedIn({required this.profile});

  final UserProfile profile;
}
