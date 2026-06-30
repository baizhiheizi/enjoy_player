# Feature Specification: Pro Upgrade & Subscription Management

**Feature Branch**: `002-pro-upgrade`

**Created**: 2026-06-30

**Status**: Draft

**Input**: User description: "Let's implement the upgrade feature in the app. User would like to upgrade to use pro features. Similar feature has been implemented in the webapp. Port subscription management to the native app; purchase flows are platform-scoped (see Platform Scope)."

## Platform Scope

This milestone delivers **shared subscription management on all supported platforms**, with **purchase limited to desktop** until store-compliant mobile billing is ready.

| Capability | Windows | macOS | iOS | Android |
|------------|---------|-------|-----|---------|
| View subscription status | Yes | Yes | Yes | Yes |
| Free vs Pro plan comparison | Yes | Yes | Yes | Yes |
| Navigation from profile / credits errors | Yes | Yes | Yes | Yes |
| External checkout (Stripe / Mixin) | Yes | Yes | No | No |
| Balance → subscription conversion | Yes | Yes | No | No |
| In-app purchase (StoreKit / Play Billing) | No | No | **Deferred** | **Deferred** |

**Rationale**: App Store policy requires StoreKit for digital Pro unlocks on iOS. External checkout (as used on the Enjoy web app) is appropriate for direct-download desktop builds but not for iOS in-app upgrade. **iOS (and Play-distributed Android) purchase is deferred to a follow-up specification** (`003-ios-storekit-upgrade` or equivalent).

**iOS v1 behavior**: Users see accurate status and plan comparison. Upgrade / extend actions show clear copy that in-app purchase on iOS is coming soon. Users who already have Pro (purchased on web or desktop) see full Pro status. No external payment links or balance purchase on iOS in this milestone.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View subscription status and compare plans (Priority: P1)

**Platforms**: All (Windows, macOS, iOS, Android)

A signed-in learner opens subscription management from their account area to see whether they are on Free or Pro, when Pro expires (if applicable), their daily AI credits allowance, and a side-by-side comparison of Free vs Pro benefits.

**Why this priority**: Users must understand what they have today and what Pro unlocks. This works on every platform and delivers value even before mobile purchase is available.

**Independent Test**: Sign in as a Free user on any platform, open the subscription screen, and verify tier, status, expiration, credits limit, and plan comparison render correctly with the current plan highlighted.

**Acceptance Scenarios**:

1. **Given** a signed-in Free user, **When** they open subscription management, **Then** they see their tier as Free, inactive or active status as returned by the account, expiration (or “never expires” when none), daily credits limit of 1,000, and Free marked as the current plan.
2. **Given** a signed-in Pro user with an expiration date, **When** they open subscription management, **Then** they see Pro as the current plan, active status, formatted expiration date, and daily credits limit of 60,000.
3. **Given** subscription status cannot be loaded, **When** the screen is shown, **Then** the user sees a clear error message and a retry action without stale or misleading plan data.
4. **Given** a signed-in Pro user on iOS who purchased on web or desktop, **When** they open subscription management, **Then** they see Pro status and benefits without needing to purchase again on iOS.

---

### User Story 2 - Upgrade or extend Pro via external checkout (Priority: P1)

**Platforms**: Windows and macOS only

A signed-in learner on desktop chooses to upgrade from Free or extend an existing Pro subscription by selecting a duration (1–12 months), choosing a payment method (card/WeChat/Google Pay via Stripe, or cryptocurrency via Mixin), reviewing the total price, and continuing to a secure external checkout page to complete payment.

**Why this priority**: This is the core revenue path for direct-download desktop builds where external checkout is permitted.

**Independent Test**: On Windows or macOS, from the subscription screen, tap Upgrade, select 3 months and Stripe, confirm purchase, and verify the app opens the checkout URL and subscription status refreshes after return.

**Acceptance Scenarios**:

1. **Given** a signed-in Free user on desktop, **When** they tap “Upgrade to Pro”, select 1 month and Stripe, and confirm, **Then** the app opens the payment checkout URL in an external browser and shows a brief confirmation that payment is in progress.
2. **Given** a signed-in Pro user on desktop, **When** they tap “Extend Subscription” and complete the same flow, **Then** the purchase proceeds identically and subscription status refreshes after they return to the app.
3. **Given** a purchase request succeeds but no checkout URL is returned, **When** the user confirms purchase, **Then** they see a clear error and can retry without losing their selections.
4. **Given** a purchase request fails (network or server error), **When** the user confirms purchase, **Then** they see a user-friendly error and the form remains editable.
5. **Given** a signed-in Free user on iOS or Android, **When** they view the subscription screen, **Then** upgrade / extend actions do not launch external checkout and instead show that mobile in-app purchase is not yet available.

---

### User Story 3 - Upgrade using account balance (Priority: P2)

**Platforms**: Windows and macOS only

A signed-in learner with a positive Enjoy account balance converts that balance into Pro subscription time in one confirmed action, without leaving the app for external checkout.

**Why this priority**: Web parity for desktop users with existing account balance.

**Independent Test**: On desktop, sign in with positive balance, open the purchase flow, choose “Use Balance”, confirm, and verify subscription status updates.

**Acceptance Scenarios**:

1. **Given** a signed-in desktop user with balance greater than zero, **When** they choose balance purchase and confirm, **Then** subscription status updates (tier, expiration) and a success confirmation is shown.
2. **Given** a signed-in desktop user with zero balance, **When** they open the balance tab, **Then** balance purchase is disabled with an explanatory message.
3. **Given** balance purchase fails, **When** the user confirms, **Then** they see an error, subscription status is unchanged, and they can retry or switch to external checkout.
4. **Given** a signed-in iOS or Android user, **When** they open subscription management, **Then** balance purchase is not offered in this milestone.

---

### User Story 4 - Discover upgrade when Pro is needed (Priority: P2)

**Platforms**: All

A signed-in Free user who hits AI usage limits or credits exhaustion is guided toward subscription information instead of hitting a dead end.

**Why this priority**: Upgrade discovery at the moment of need reduces confusion even when mobile purchase is deferred.

**Independent Test**: Trigger a credits-limit scenario on iOS and desktop; verify the error includes an action to open subscription management; on desktop, complete purchase from there.

**Acceptance Scenarios**:

1. **Given** a signed-in Free user whose AI request is blocked for billing or credits reasons, **When** the app surfaces the failure, **Then** the message includes an action to view subscription / upgrade options.
2. **Given** a desktop user taps that action, **When** navigation completes, **Then** they land on the subscription screen ready to purchase.
3. **Given** an iOS user taps that action, **When** navigation completes, **Then** they land on the subscription screen with plan comparison and a clear message that iOS in-app purchase is coming soon.

---

### User Story 5 - Access subscription from account navigation (Priority: P3)

**Platforms**: All

A signed-in learner can reach subscription management from profile / account entry points, see a Pro badge or tier indicator where appropriate, and return to their previous task.

**Why this priority**: Makes the feature discoverable on every platform.

**Independent Test**: From profile on iOS and desktop, open subscription, navigate back without losing auth state.

**Acceptance Scenarios**:

1. **Given** a signed-in user on the profile screen, **When** they choose subscription / upgrade, **Then** they reach the subscription management screen.
2. **Given** a Pro user in the account menu, **When** account chrome is shown, **Then** Pro tier is visually indicated consistent with profile tier display.

---

### Edge Cases

- **iOS / Android**: User taps Upgrade but purchase is unavailable — show non-dismissive informational copy; do not open external payment URLs.
- User starts checkout on desktop but abandons payment: returning to the app shows last known status; user can refresh or retry.
- User’s Pro subscription expires while the app is open: refreshed status shows inactive/expired; upgrade CTA behavior follows platform scope (purchase on desktop, informational on iOS).
- User has cached profile showing Free but server returns Pro after payment elsewhere: subscription screen reflects server status after refresh on all platforms.
- User is signed out: subscription routes redirect to sign-in; post-sign-in returns to intended destination when applicable.
- Slow or offline network: loading skeleton, then error with retry; no partial fake data.
- Balance purchase with fractional-month conversion: server determines converted time (desktop only).
- Large text / accessibility: plan comparison and purchase sheet remain readable on phone and desktop window sizes.
- Platform input: keyboard navigation and tooltips follow existing app interaction standards.

## Requirements *(mandatory)*

### Functional Requirements

#### Cross-platform (all targets)

- **FR-001**: The app MUST provide a dedicated subscription management experience for signed-in users only.
- **FR-002**: The app MUST display current subscription tier (Free or Pro), active/inactive status, expiration date (or equivalent “no expiration” copy), and daily AI credits limit aligned with tier (1,000 Free / 60,000 Pro).
- **FR-003**: The app MUST show a Free vs Pro plan comparison including feature summaries and pricing ($9.99/month for Pro) matching the Enjoy web product definition.
- **FR-004**: The app MUST highlight the user’s current plan in the comparison.
- **FR-011**: The app MUST surface loading, error, and empty states for subscription status fetch failures with retry.
- **FR-012**: The app MUST link users from AI credits or billing-limit failures to subscription management with clear upgrade-oriented copy.
- **FR-013**: The app MUST expose navigation to subscription management from the profile / account area.
- **FR-014**: The app MUST keep subscription tier visible in account/profile summary consistent with cached and refreshed profile data.
- **FR-015**: User-visible strings for this feature MUST be localized for all supported app languages.
- **FR-016**: On iOS and Android, the app MUST NOT initiate external payment checkout or balance-to-subscription conversion in this milestone.
- **FR-017**: On iOS and Android, when the user attempts to upgrade or extend, the app MUST show clear copy that in-app purchase on mobile is not yet available (without linking to external payment for digital unlock).

#### Desktop only (Windows, macOS)

- **FR-004a**: On desktop, the app MUST show “Upgrade to Pro” for Free users or “Extend Subscription” for Pro users as actionable purchase entry points.
- **FR-005**: On desktop, the app MUST allow purchase of 1–12 months of Pro subscription per transaction.
- **FR-006**: On desktop, the app MUST offer payment via Stripe (card, WeChat Pay, Google Pay) and Mixin (USDT, BTC, ETH, DOGE) as selectable options before checkout.
- **FR-007**: On desktop, the app MUST initiate external secure checkout using the payment URL returned by the Enjoy account service and MUST NOT collect card or wallet credentials inside the app.
- **FR-008**: On desktop, the app MUST refresh subscription status after purchase initiation, when the user returns from checkout, and on explicit retry/pull-to-refresh where applicable.
- **FR-009**: On desktop, the app MUST support converting available account balance into Pro subscription time with a confirmation step.
- **FR-010**: On desktop, the app MUST disable balance purchase when balance is zero and explain why.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve Enjoy Player's feature-first architecture and avoid feature-to-feature shortcuts unless the plan documents an exception.
- **QR-002**: Changed behavior MUST have automated tests or a documented manual verification reason.
- **QR-003**: User-facing strings, controls, haptics, tooltips, and keyboard affordances MUST follow existing localization and shared UI patterns.
- **QR-004**: Subscription status SHOULD load and render primary content within 2 seconds on a typical broadband connection; desktop purchase actions MUST show in-progress feedback within 300 ms of user confirmation.
- **QR-005**: Feature behavior changes MUST update the matching documentation under `docs/features/`.

### Key Entities

- **Subscription status**: User’s current tier (Free/Pro), whether subscription is active, expiration timestamp, and implied daily credits ceiling.
- **Plan tier**: Marketing definition of Free vs Pro capabilities and price used in comparison UI.
- **Purchase intent** (desktop only): Selected duration (months), chosen payment processor, computed total price, and resulting checkout session or balance conversion outcome.
- **Account balance** (desktop only for conversion): Spendable Enjoy account balance that may be converted to subscription time.
- **Payment session** (desktop only): External checkout reference with status (pending, succeeded, expired) managed by Enjoy payment infrastructure.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 90% of signed-in users who open subscription management see accurate tier and status on first load without manual refresh under normal network conditions (all platforms).
- **SC-002**: Desktop users can reach external checkout from purchase confirmation in under 30 seconds (excluding time spent in the payment provider).
- **SC-003**: After a successful desktop balance purchase, 100% of test cases show updated Pro status within one refresh cycle without requiring re-sign-in.
- **SC-004**: 100% of AI billing-limit error surfaces in scope include a visible path to subscription management during acceptance testing (all platforms).
- **SC-005**: Plan comparison renders without layout breakage on Android, iOS, macOS, and Windows at default window sizes; desktop purchase flow completes successfully on Windows and macOS.
- **SC-006**: iOS users attempting upgrade see the “coming soon” mobile purchase message 100% of the time—never an external checkout link for digital Pro unlock in this milestone.
- **SC-007**: Pro users who purchased on web or desktop see correct Pro status on iOS without additional purchase steps.

## Assumptions

- Enjoy account backend and payment infrastructure for **desktop external checkout** are unchanged from the web app: same subscription status semantics, checkout URL flow, balance conversion rules, and pricing ($9.99/month, 1–12 month terms).
- Desktop checkout uses external browser / system browser (not embedded WebView payment forms), matching the web client’s security model.
- Account profile snapshot (tier, expiration, balance) remains available for quick display; the dedicated subscription status source provides authoritative live status on the subscription screen.
- Pro-gated AI capabilities and daily credits enforcement remain server-side; this feature focuses on discovery, status, and desktop purchase—not reimplementing quota logic locally.
- **iOS StoreKit and Android Play Billing are explicitly out of scope for this milestone** and will be specified in a follow-up feature (`003-*` or similar).
- Signed-in access is required; guests never see subscription UI (consistent with login-only app access).
- Localization strings will align with web subscription copy where concepts match, adapted for mobile/desktop layout constraints.

## Out of Scope (follow-up specs)

- StoreKit in-app purchase and receipt validation on iOS
- Google Play Billing on Play-distributed Android builds
- Cross-platform subscription restoration flows beyond displaying server-side status
- Promotional pricing, trials, or family sharing
