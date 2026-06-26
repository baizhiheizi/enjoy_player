## Why

The email OTP sign-in path ships as two disconnected screens: a bare full-width email form at `/sign-in/email` and a separate OTP pane on the main sign-in route after a navigation pop. The email step does not match the polished sign-in hub (no gradient, no max-width card, no design tokens), and splitting email entry from OTP verification feels broken on desktop where the form stretches across the shell. Users need a single, professional email sign-in flow with visible email context, resend cooldown, and OTP entry on the same page.

## What Changes

- Replace the split email + OTP navigation with a **unified email sign-in flow** on one screen (two visual steps, one route).
- Match the sign-in hub visual language: gradient background, centered `EnjoyCard`, logo, token spacing, and `EnjoyButton` actions.
- Add a **6-box OTP pin field** with auto-advance, paste support, and auto-verify when complete.
- Show the **current email** prominently during OTP entry with a **Change email** action that returns to step A without leaving the page.
- Drive resend cooldown from `AuthAwaitingOtp.startedAt` so the freeze timer stays accurate across rebuilds and navigation.
- Remove `context.pop()` after OTP send; step B appears in-place with an animated transition.
- Retire duplicate OTP UI on the sign-in hub (hub delegates in-progress OTP to the unified flow or shows a resume affordance).
- Add l10n strings for change-email and any new copy; widget tests for step transitions and resend gating.

## Capabilities

### New Capabilities

- `email-otp-sign-in-ui`: Unified email + OTP sign-in presentation, interaction, resend cooldown, and navigation behavior.

### Modified Capabilities

- (none — `native-auth-v2` change spec covers backend OTP requirements; this change refines client UX only)

## Impact

- **UI**: `lib/features/auth/presentation/sign_in_screen.dart` (major refactor), new widgets under `lib/features/auth/presentation/widgets/` (e.g. OTP pin field, email flow).
- **Routing**: `/sign-in/email` route retained but renders unified flow; hub email button unchanged.
- **State**: No API or `AuthCtrl` contract changes; uses existing `sendOtp`, `verifyOtp`, `resendOtp`, `cancelSignIn`.
- **l10n**: New/updated strings in `app_en.arb`, `app_zh.arb`, `app_zh_CN.arb`.
- **Tests**: Widget tests for email OTP flow; optional unit test for resend remaining time helper.
- **Docs**: Update `docs/features/auth.md` UX section briefly.
