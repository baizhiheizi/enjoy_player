## Context

Native auth v2 ([`native-auth-v2`](../../native-auth-v2/)) ships email OTP with working backend integration (`sendOtp`, `verifyOtp`, `resendOtp`) and basic UI in [`sign_in_screen.dart`](../../../lib/features/auth/presentation/sign_in_screen.dart). Today:

- **Hub** (`/sign-in`): polished — gradient, logo, `maxWidth: 400`, `EnjoyButton`.
- **Email entry** (`/sign-in/email`): unstyled — plain `Scaffold`, full-bleed `TextField`, stretches across the desktop shell content area.
- **OTP entry** (`_OtpEntryPane` on hub): centered and usable, but reached only after `sendOtp` + `context.pop()`, so users never see email and OTP together.

`AuthAwaitingOtp` already carries `email`, `resendAfterSeconds`, `startedAt`, and `requestId`. No controller or API changes are required.

Design tokens and shared widgets exist: `EnjoyThemeTokens`, `EnjoyCard`, `EnjoyButton`, gradient used by `_SignInHub`.

## Goals / Non-Goals

**Goals:**

- Single-route email sign-in with two in-place steps: **enter email** → **verify OTP**.
- Visual parity with the sign-in hub (gradient, centered card, logo, token spacing).
- Prominent email display during OTP step; **Change email** returns to step A with email pre-filled.
- 6-digit OTP pin input with auto-advance, paste, and auto-submit at 6 digits.
- Resend cooldown accurate via `startedAt + resendAfterSeconds` (survives rebuilds).
- Animated step transition; accessible labels and semantics.

**Non-Goals:**

- Backend OTP API changes, new auth providers, or PKCE / Google / Apple UI changes.
- Flutter web auth.
- Replacing the sign-in hub layout or sidebar account chip behavior beyond OTP resume routing.

## Decisions

### 1. Unified widget on `/sign-in/email` route

Introduce `EmailOtpSignInFlow` (name TBD) as the sole content of `/sign-in/email`. Hub continues to `context.push('/sign-in/email')`.

**Step derivation:**

| Condition | Step |
|-----------|------|
| `authCtrlProvider` is `AuthSignedOut` (or no OTP in flight) | **Email** — editable field + Send code |
| `authCtrlProvider` is `AuthAwaitingOtp` | **OTP** — pin field, email chip, resend, verify |

On successful `sendOtp`, **do not** `context.pop()`. Widget rebuilds into OTP step on the same route.

*Alternative considered:* Inline expansion on hub — rejected to keep hub focused on provider choice and avoid a tall scroll on mobile.

### 2. Shared chrome wrapper

Extract a private `_SignInFlowScaffold` (or reuse hub gradient stack) wrapping email/OTP content:

```
Stack(gradient) → Center → ConstrainedBox(maxWidth: 400) → EnjoyCard → step content
```

AppBar: back on email step → pop to hub; back on OTP step → local step A (see decision 3). Close (X) on hub route only; email route uses back chevron.

*Alternative considered:* Duplicate gradient in each screen — rejected; one wrapper reduces drift.

### 3. Change email behavior — local step back (Option A)

**Change email** on OTP step:

1. Navigate UI to email step locally.
2. Pre-fill email from `AuthAwaitingOtp.email`.
3. Call `cancelSignIn()` to discard in-flight OTP/`requestId` so a new send creates a fresh session.

User edits email and taps Send again. No API call on "Change email" alone.

*Alternative considered:* Keep OTP session when changing email — rejected; `requestId` is bound to the sent email on the backend.

### 4. OTP pin field — custom widget, no new package

Build `OtpPinField` under `lib/features/auth/presentation/widgets/`:

- 6 individual boxes (or 6-slot `TextField` with hidden master input pattern used by many pin UIs).
- `TextInputType.number`, one digit per box, auto-focus next, backspace to previous.
- Paste: if clipboard is 6 digits, fill all boxes and trigger verify.
- `onCompleted(String code)` when length == 6.
- Error state: red border + optional shake via `AnimatedContainer` / short `AnimationController`.

*Alternative considered:* `pinput` package — rejected to avoid dependency for a single screen.

### 5. Resend countdown — wall-clock helper

Add a small pure function (e.g. in `lib/features/auth/domain/otp_resend.dart`):

```dart
int otpResendSecondsRemaining({
  required DateTime startedAt,
  required int resendAfterSeconds,
  DateTime? now,
});
```

UI uses `Timer.periodic(1s)` or `Ticker` to rebuild countdown label. Resend button disabled while `remaining > 0`. Label: existing `authOtpResendIn(seconds)` or new `mm:ss` variant if needed.

On successful `resendOtp`, state updates with new `startedAt` / `resendAfterSeconds` from API — timer resets automatically.

*Alternative considered:* Recursive `Future.delayed` (current `_OtpEntryPane`) — rejected; drifts and resets incorrectly on rebuild.

### 6. Hub behavior when OTP in flight

When user opens `/sign-in` while `AuthAwaitingOtp`:

- **Option (chosen):** Auto-redirect or replace body with a compact card: "Continue verifying {email}" → button pushes `/sign-in/email` (or use `context.go('/sign-in/email')` if already the natural resume path).
- Sidebar `authFlowInProgress` already shows OTP/waiting label linking to `/sign-in` — ensure that link lands on email route when state is `AuthAwaitingOtp`.

Remove standalone `_OtpEntryPane` from hub body to avoid duplicate OTP UIs.

### 7. Animation

Use `AnimatedSwitcher` with `FadeTransition` + slight `SlideTransition` (0, 0.02) between email and OTP steps, matching [`app_router.dart`](../../../lib/core/routing/app_router.dart) shell transitions (~180ms, `Curves.easeOutCubic`).

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| User taps Change email then abandons — stale signed-out state | Acceptable; `AuthSignedOut` is correct until they send again |
| Pin field accessibility on desktop | Single hidden field fallback + Semantics labels on each digit |
| Double verify if auto-submit races manual button | Guard with `_busy` flag; ignore duplicate calls |
| Route `/sign-in/email` bookmarked mid-OTP after app restart | Cold start loses `AuthAwaitingOtp`; show email step — acceptable |

## Migration Plan

1. Implement `EmailOtpSignInFlow` + `OtpPinField` behind existing route.
2. Remove `EmailEntryScreen` body and `_OtpEntryPane` from hub.
3. Update l10n; run `flutter gen-l10n`.
4. Widget tests; manual pass on Windows (primary reporter) + one mobile width.
5. Brief note in `docs/features/auth.md`.

Rollback: revert UI files only; no schema or API migration.

## Open Questions

- None blocking. Optional polish (post-MVP): haptic on digit entry, confetti on success (hub already handles signed-in redirect).
