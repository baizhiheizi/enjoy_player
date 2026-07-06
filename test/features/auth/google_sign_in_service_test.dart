import 'package:enjoy_player/features/auth/data/google_sign_in_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoogleSignInService.signInForIdToken', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test(
      'throws before touching the native SDK on iOS while '
      'kGoogleNativeSignInConfiguredOnApple is false, instead of letting '
      'GIDSignIn.signIn() crash the process with an uncatchable native '
      'exception',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        final service = GoogleSignInService();

        await expectLater(
          service.signInForIdToken(),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'throws the same guard on macOS',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        final service = GoogleSignInService();

        await expectLater(
          service.signInForIdToken(),
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}
