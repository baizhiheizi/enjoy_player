/// Sign in with Apple wrapper for Enjoy account auth.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

part 'apple_sign_in_service.g.dart';

class AppleSignInCredentials {
  const AppleSignInCredentials({
    required this.identityToken,
    required this.authorizationCode,
    this.fullName,
  });

  final String identityToken;
  final String authorizationCode;
  final Map<String, String>? fullName;
}

@Riverpod(keepAlive: true)
AppleSignInService appleSignInService(Ref ref) {
  return AppleSignInService();
}

class AppleSignInService {
  /// Returns credentials, or `null` when the user cancels.
  Future<AppleSignInCredentials?> signIn() async {
    final available = await SignInWithApple.isAvailable();
    if (!available) {
      throw StateError('Sign in with Apple is not available');
    }
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final identityToken = credential.identityToken;
    final authorizationCode = credential.authorizationCode;
    if (identityToken == null ||
        identityToken.isEmpty ||
        authorizationCode.isEmpty) {
      throw StateError('Apple Sign-In returned incomplete credentials');
    }
    Map<String, String>? fullName;
    final given = credential.givenName;
    final family = credential.familyName;
    if (given != null || family != null) {
      fullName = {'givenName': ?given, 'familyName': ?family};
    }
    return AppleSignInCredentials(
      identityToken: identityToken,
      authorizationCode: authorizationCode,
      fullName: fullName,
    );
  }
}
