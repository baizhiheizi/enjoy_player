/// Wall-clock resend cooldown for email OTP sign-in.
library;

/// Seconds until OTP resend is allowed; `0` when cooldown has elapsed.
int otpResendSecondsRemaining({
  required DateTime startedAt,
  required int resendAfterSeconds,
  DateTime? now,
}) {
  if (resendAfterSeconds <= 0) return 0;
  final clock = now ?? DateTime.now();
  final elapsed = clock.difference(startedAt).inSeconds;
  if (elapsed < 0) return resendAfterSeconds;
  final remaining = resendAfterSeconds - elapsed;
  if (remaining <= 0) return 0;
  return remaining;
}
