## 1. Shared chrome and helpers

- [x] 1.1 Extract `_SignInFlowScaffold` (gradient + centered max-width + optional AppBar) shared by email flow and reusable from hub patterns
- [x] 1.2 Add `otpResendSecondsRemaining()` helper using `AuthAwaitingOtp.startedAt` and unit-test edge cases (elapsed, zero, future skew)

## 2. OTP pin widget

- [x] 2.1 Implement `OtpPinField` widget (6 slots, auto-advance, backspace, semantics)
- [x] 2.2 Add paste handling for 6-digit clipboard content and `onCompleted` callback
- [x] 2.3 Add error/disabled visual states for failed verify and busy in-flight

## 3. Unified email OTP flow

- [x] 3.1 Create `EmailOtpSignInFlow` with email step (validated field, send code, hub-matching card layout)
- [x] 3.2 Add OTP step (email chip, `OtpPinField`, verify button, resend with wall-clock countdown, change email)
- [x] 3.3 Wire `AnimatedSwitcher` transition between steps; remove `context.pop()` after `sendOtp`
- [x] 3.4 Replace `EmailEntryScreen` body with `EmailOtpSignInFlow`; remove `_OtpEntryPane` from hub

## 4. Hub resume behavior

- [x] 4.1 When `/sign-in` loads with `AuthAwaitingOtp`, show resume card linking to `/sign-in/email` instead of inline OTP pane
- [x] 4.2 Ensure sidebar in-progress sign-in tap lands on email OTP route when state is `AuthAwaitingOtp`

## 5. Localization and docs

- [x] 5.1 Add l10n strings (`authChangeEmail`, resume copy if needed) to `app_en.arb`, `app_zh.arb`, `app_zh_CN.arb`
- [x] 5.2 Run `flutter gen-l10n`
- [x] 5.3 Update `docs/features/auth.md` email OTP UX section

## 6. Verification

- [x] 6.1 Widget test: email step → send → OTP step on same route (mocked auth notifier)
- [x] 6.2 Widget test: resend disabled during cooldown; enabled after elapsed time
- [x] 6.3 Widget test: change email returns to step A and calls cancel
- [x] 6.4 Run `flutter analyze` and `flutter test`
