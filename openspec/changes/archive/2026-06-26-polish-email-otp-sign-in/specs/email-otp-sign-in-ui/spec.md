## ADDED Requirements

### Requirement: Unified email and OTP sign-in screen

The app SHALL present email entry and OTP verification as two steps on a single sign-in route (`/sign-in/email`). The user SHALL NOT be navigated away from this route when transitioning from email send to OTP entry.

#### Scenario: Send code stays on same screen

- **WHEN** the user submits a valid email and the send OTP request succeeds
- **THEN** the app SHALL remain on `/sign-in/email` and SHALL show the OTP verification step

#### Scenario: Visual consistency with sign-in hub

- **WHEN** the user views the email OTP sign-in screen at any step
- **THEN** the app SHALL use the same gradient background, centered max-width layout (~400px), and Enjoy design tokens as the native sign-in hub

### Requirement: Email display during OTP step

During OTP verification, the app SHALL display the email address the code was sent to. The user SHALL be able to change the email and return to the email entry step.

#### Scenario: Email shown on OTP step

- **WHEN** auth state is `AuthAwaitingOtp`
- **THEN** the app SHALL show the email from `AuthAwaitingOtp.email` prominently on the OTP step

#### Scenario: Change email

- **WHEN** the user chooses to change email from the OTP step
- **THEN** the app SHALL return to the email entry step with the email field pre-filled
- **THEN** the app SHALL cancel the in-flight OTP session (`cancelSignIn`) so a new send creates a fresh OTP request

### Requirement: OTP pin input

The app SHALL provide a native 6-digit OTP input optimized for one-time codes.

#### Scenario: Six-box entry

- **WHEN** the user is on the OTP verification step
- **THEN** the app SHALL show a 6-digit pin input (individual digit slots or equivalent)

#### Scenario: Auto-advance and paste

- **WHEN** the user enters a digit in a pin slot
- **THEN** focus SHALL advance to the next slot
- **WHEN** the user pastes a 6-digit code into the pin input
- **THEN** the app SHALL fill all slots and attempt verification

#### Scenario: Auto-verify on complete

- **WHEN** all 6 digits are entered
- **THEN** the app SHALL submit verification without requiring an extra tap (verify button remains available as fallback)

### Requirement: OTP resend cooldown

The app SHALL enforce resend cooldown using server-provided timing and SHALL show remaining time to the user.

#### Scenario: Resend disabled during cooldown

- **WHEN** fewer than `resendAfterSeconds` have elapsed since `AuthAwaitingOtp.startedAt`
- **THEN** the resend control SHALL be disabled
- **THEN** the app SHALL display remaining seconds (or formatted countdown) using localized strings

#### Scenario: Resend enabled after cooldown

- **WHEN** the cooldown has elapsed
- **THEN** the app SHALL enable resend
- **WHEN** the user taps resend and the request succeeds
- **THEN** the app SHALL reset the cooldown from the new `startedAt` and `resendAfterSeconds` in auth state

#### Scenario: Cooldown survives rebuild

- **WHEN** the OTP step widget is rebuilt or the user navigates away and returns while still `AuthAwaitingOtp`
- **THEN** the remaining cooldown SHALL be computed from wall-clock time (`startedAt`), not reset to the full interval

### Requirement: Hub resume for in-flight OTP

When the user opens the sign-in hub while an email OTP flow is in progress, the app SHALL guide them to resume verification rather than showing a duplicate OTP form on the hub.

#### Scenario: Resume from hub

- **WHEN** auth state is `AuthAwaitingOtp` and the user opens `/sign-in`
- **THEN** the app SHALL offer to continue verification (e.g. navigate to or highlight `/sign-in/email`) instead of rendering a separate OTP entry pane on the hub

### Requirement: Localization

All new user-visible strings for the unified email OTP flow SHALL be added to English and Chinese ARB files and generated via `flutter gen-l10n`.

#### Scenario: Change email label localized

- **WHEN** the OTP step is shown in any supported locale
- **THEN** the change-email action and any new countdown copy SHALL use generated `AppLocalizations` strings
