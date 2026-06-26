import 'package:enjoy_player/features/auth/domain/otp_resend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final startedAt = DateTime(2026, 6, 26, 12, 0, 0);

  test('returns full interval when clock equals start', () {
    expect(
      otpResendSecondsRemaining(
        startedAt: startedAt,
        resendAfterSeconds: 30,
        now: startedAt,
      ),
      30,
    );
  });

  test('returns zero when cooldown elapsed', () {
    expect(
      otpResendSecondsRemaining(
        startedAt: startedAt,
        resendAfterSeconds: 30,
        now: startedAt.add(const Duration(seconds: 30)),
      ),
      0,
    );
  });

  test('returns remaining seconds mid-cooldown', () {
    expect(
      otpResendSecondsRemaining(
        startedAt: startedAt,
        resendAfterSeconds: 30,
        now: startedAt.add(const Duration(seconds: 11)),
      ),
      19,
    );
  });

  test('returns zero when resendAfterSeconds is zero', () {
    expect(
      otpResendSecondsRemaining(
        startedAt: startedAt,
        resendAfterSeconds: 0,
        now: startedAt,
      ),
      0,
    );
  });

  test('returns zero when clock is before start (skew)', () {
    expect(
      otpResendSecondsRemaining(
        startedAt: startedAt,
        resendAfterSeconds: 30,
        now: startedAt.subtract(const Duration(seconds: 5)),
      ),
      30,
    );
  });
}
