import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/email_otp_sign_in_flow.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

class _EmailOtpAuthCtrl extends AuthCtrl {
  _EmailOtpAuthCtrl(this._state);

  AuthState _state;
  int cancelCount = 0;

  @override
  Future<AuthState> build() async => _state;

  void _emit(AuthState next) {
    _state = next;
    state = AsyncData(next);
  }

  @override
  Future<void> sendOtp({required String email}) async {
    _emit(
      AuthAwaitingOtp(
        requestId: 'req-1',
        email: email,
        resendAfterSeconds: 30,
        startedAt: DateTime.now(),
      ),
    );
  }

  @override
  void cancelSignIn() {
    cancelCount++;
    _emit(const AuthSignedOut());
  }

  @override
  Future<void> resendOtp() async {
    final current = state.valueOrNull;
    if (current is! AuthAwaitingOtp) return;
    _emit(
      AuthAwaitingOtp(
        requestId: 'req-2',
        email: current.email,
        resendAfterSeconds: 30,
        startedAt: DateTime.now(),
      ),
    );
  }
}

Widget _flowHarness({
  required _EmailOtpAuthCtrl auth,
  List<Override> overrides = const [],
}) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
  return ProviderScope(
    overrides: [authCtrlProvider.overrideWith(() => auth), ...overrides],
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: scheme,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: EmailOtpSignInFlow()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('email step transitions to OTP step on same screen', (
    tester,
  ) async {
    final auth = _EmailOtpAuthCtrl(const AuthSignedOut());
    await tester.pumpWidget(_flowHarness(auth: auth));
    await tester.pumpAndSettle();

    expect(find.text('Send code'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'user@example.com');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    expect(find.text('Enter verification code'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.text('Change email'), findsOneWidget);
  });

  testWidgets('resend shows countdown while cooling down', (tester) async {
    final auth = _EmailOtpAuthCtrl(
      AuthAwaitingOtp(
        requestId: 'req-1',
        email: 'user@example.com',
        resendAfterSeconds: 30,
        startedAt: DateTime.now(),
      ),
    );
    await tester.pumpWidget(_flowHarness(auth: auth));
    await tester.pumpAndSettle();

    final resendFinder = find.textContaining('Resend in');
    expect(resendFinder, findsOneWidget);
    final resendButton = tester.widget<TextButton>(
      find.ancestor(of: resendFinder, matching: find.byType(TextButton)),
    );
    expect(resendButton.onPressed, isNull);
  });

  testWidgets('resend enabled after cooldown elapsed', (tester) async {
    final auth = _EmailOtpAuthCtrl(
      AuthAwaitingOtp(
        requestId: 'req-1',
        email: 'user@example.com',
        resendAfterSeconds: 30,
        startedAt: DateTime.now().subtract(const Duration(seconds: 45)),
      ),
    );
    await tester.pumpWidget(_flowHarness(auth: auth));
    await tester.pumpAndSettle();

    final enabledResend = find.text('Resend code');
    expect(enabledResend, findsOneWidget);
    expect(
      tester
          .widget<TextButton>(
            find.ancestor(of: enabledResend, matching: find.byType(TextButton)),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('change email returns to email step and cancels OTP session', (
    tester,
  ) async {
    final auth = _EmailOtpAuthCtrl(
      AuthAwaitingOtp(
        requestId: 'req-1',
        email: 'user@example.com',
        resendAfterSeconds: 30,
        startedAt: DateTime.now(),
      ),
    );
    await tester.pumpWidget(_flowHarness(auth: auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change email'));
    await tester.pumpAndSettle();

    expect(find.text('Send code'), findsOneWidget);
    expect(auth.cancelCount, 1);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'user@example.com',
    );
  });
}
