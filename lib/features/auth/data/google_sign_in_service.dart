/// Google Sign-In wrapper for Enjoy account auth.
library;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/features/auth/domain/google_auth_config.dart';

part 'google_sign_in_service.g.dart';

bool get _isApplePlatform =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

@Riverpod(keepAlive: true)
GoogleSignInService googleSignInService(Ref ref) {
  return GoogleSignInService();
}

class GoogleSignInService {
  GoogleSignInService();

  static const _scopes = ['email', 'profile'];
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _initialization;

  static Future<void> _ensureInitialized() {
    return _initialization ??= _googleSignIn.initialize(
      // Android only returns a non-null idToken when a serverClientId
      // (a Web application type OAuth client) is supplied; the token's
      // `aud` claim then equals this value. iOS/macOS derive their
      // client ID from Info.plist's GIDClientID instead.
      serverClientId: defaultTargetPlatform == TargetPlatform.android
          ? kGoogleWebClientId
          : null,
    );
  }

  /// Returns Google ID token, or `null` when the user cancels.
  ///
  /// Guards against calling into the native SDK on iOS/macOS before
  /// Info.plist has a real OAuth client configured: `GIDSignIn.signIn()`
  /// throws an uncatchable native exception in that state (see
  /// [kGoogleNativeSignInConfiguredOnApple]), so this must be checked
  /// *before* the native call rather than relying on a `try`/`catch` here.
  Future<String?> signInForIdToken() async {
    if (_isApplePlatform && !kGoogleNativeSignInConfiguredOnApple) {
      throw StateError(
        'Google Sign-In is not configured for this platform yet: '
        'ios/Runner/Info.plist (or macos/Runner/Info.plist) still has the '
        'placeholder GIDClientID/CFBundleURLSchemes.',
      );
    }
    await _ensureInitialized();
    late final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate(scopeHint: _scopes);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
    final auth = account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google Sign-In returned no idToken');
    }
    return idToken;
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await _googleSignIn.signOut();
  }
}
