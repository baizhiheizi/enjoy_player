# Feature Specification: App Auto-Renew Subscription & Credits Packages

**Feature Branch**: `027-auto-renew-credit-packages`

**Created**: 2026-07-22

**Status**: Draft

**Input**: User description: "Implement the auto-renew subscription and credit packages in app side, similar to the web have already done."

## Platform Scope

This milestone brings **web billing parity into Enjoy Player** for status, plan selection, auto-renew management, and credits packages. Purchase initiation follows the same platform policy as `002-pro-upgrade`.

| Capability | Windows | macOS | Linux | iOS | Android |
|------------|---------|-------|-------|-----|---------|
| View subscription status (incl. auto-renew / plan interval) | Yes | Yes | Yes | Yes | Yes |
| View monthly / yearly auto-renew catalog | Yes | Yes | Yes | Yes | Yes |
| Start auto-renew checkout (external) | Yes | Yes | Yes | No | No |
| Cancel auto-renew | Yes | Yes | Yes | Yes* | Yes* |
| Keep prepaid one-time Pro months | Yes | Yes | Yes | No** | No** |
| View credits packages catalog | Yes | Yes | Yes | Yes | Yes |
| Buy credits package (external checkout) | Yes | Yes | Yes | No | No |
| In-app store purchase (StoreKit / Play / RevenueCat) | No | No | No | Deferred | Deferred |

\* Cancel is allowed wherever the account service supports it for the user’s active Stripe (or equivalent) auto-renew source; the app surfaces the action and refreshes status. Users who subscribed on web/desktop can cancel from the app on any platform.

\*\* Prepaid multi-month and balance conversion remain desktop-only purchase paths, consistent with `002-pro-upgrade`. Mobile continues to show status only for those prepaid flows.

**Rationale**: Backend auto-renew and credits packages already exist on Enjoy Web. The app must offer the same catalog and management UX; external checkout remains appropriate for direct-download desktop/Linux. Native store IAP stays deferred.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Choose monthly or yearly auto-renew Pro (Priority: P1)

**Platforms**: Purchase on Windows / macOS / Linux; catalog and status on all platforms

A signed-in learner who wants Pro without paying month-by-month opens subscription management, sees two clear auto-renew options (monthly at $9.99 and yearly at $99.99), picks one, confirms price and billing interval, completes payment in the external checkout, and returns to the app with Pro active and auto-renew on for the chosen interval.

**Why this priority**: This is the core web parity gap—today’s app still emphasizes prepaid month packs without first-class auto-renew plan choice.

**Independent Test**: On desktop, open subscription, select monthly auto-renew, complete checkout (or simulated success), verify Pro status shows monthly auto-renew on and period end; repeat with yearly for a separate account.

**Acceptance Scenarios**:

1. **Given** a signed-in free (or expired) user on any platform, **When** they open subscription management, **Then** they see monthly ($9.99 / month) and yearly ($99.99 / year) auto-renew plans when those plans are available from the account service.
2. **Given** a free user on desktop, **When** they successfully start the monthly auto-renew plan and complete first payment, **Then** they become Pro for one month, auto-renew is on for monthly, and status shows monthly at $9.99 with access end or next renewal.
3. **Given** a free user on desktop, **When** they successfully start the yearly auto-renew plan and complete first payment, **Then** they become Pro for one year, auto-renew is on for yearly, and status shows yearly at $99.99.
4. **Given** either plan on desktop, **When** the user confirms checkout, **Then** they see amount and billing interval before the external payment page opens.
5. **Given** a free user on iOS or Android, **When** they tap subscribe on an auto-renew plan, **Then** they see that mobile in-app purchase is not yet available and no external payment URL is opened.

---

### User Story 2 - Cancel auto-renew without losing paid time (Priority: P1)

**Platforms**: All (management); entitlement refresh on all

A subscriber no longer wants automatic charges. They cancel auto-renew in the app; they keep Pro until the end of the period already paid for, are told the access-through date, and are not charged again for that subscription.

**Why this priority**: Trust and web parity require clear cancel-at-period-end behavior in the native app.

**Independent Test**: As an active auto-renew subscriber, cancel from the subscription screen; verify auto-renew off, access-through date shown, and Pro remains until that date after refresh.

**Acceptance Scenarios**:

1. **Given** an active auto-renewing subscriber, **When** they cancel auto-renew and confirm, **Then** auto-renew turns off, they are told the date Pro remains available through, and status refreshes to match the account service.
2. **Given** a canceled subscription still within the paid period, **When** they view status, **Then** they see auto-renew off, plan interval, and the access end date.
3. **Given** cancel fails (network or server), **When** the user confirms cancel, **Then** they see a clear error, auto-renew state is unchanged, and they can retry.

---

### User Story 3 - Buy a credits package without (or in addition to) subscribing (Priority: P1)

**Platforms**: Purchase on Windows / macOS / Linux; catalog and balances on all platforms

A signed-in learner who prefers pay-as-you-go—or who hit the daily credits limit—opens credits or billing offers, sees three one-time packages ($2, $5, $50) with permanent credits each grants, picks one, completes payment, and permanent credits increase without changing subscription tier or auto-renew state.

**Why this priority**: Web already ships packages for users who will not subscribe or who need top-ups after the daily cap; the app must unblock the same moment of need.

**Independent Test**: As a free-tier desktop user, purchase each package size in separate runs; verify permanent credits rise by the catalog amount and tier remains free. As a Pro user at daily limit, purchase one package and resume an AI action that spends permanent credits.

**Acceptance Scenarios**:

1. **Given** a signed-in user viewing credits or package offers, **When** they browse packages, **Then** they see three one-time options at $2, $5, and $50 with permanent credits clearly shown (200,000 / 500,000 / 5,000,000).
2. **Given** a free-tier desktop user, **When** they successfully purchase any package, **Then** permanent credits increase by that package’s amount, they can spend those credits on AI features, and subscription status is unchanged.
3. **Given** an active Pro subscriber at daily limit on desktop, **When** they purchase a package, **Then** permanent credits increase and tier, period, and auto-renew state stay unchanged.
4. **Given** any package on desktop, **When** the user confirms checkout, **Then** they see USD price and permanent credits to be granted before the external payment page opens.
5. **Given** a user on iOS or Android, **When** they attempt to buy a package, **Then** they see that mobile purchase is not yet available and no external payment URL is opened.
6. **Given** package offers and subscription plans on the same or related surfaces, **When** the user compares them, **Then** packages are clearly one-time permanent-credit top-ups, not subscription plans.

---

### User Story 4 - See rich subscription status after web or app billing changes (Priority: P2)

**Platforms**: All

A signed-in learner opens subscription management (or returns to the app after paying on web) and sees accurate tier, plan interval (monthly/yearly when on auto-renew), auto-renew on/off, provider/channel when available, access end or next renewal, and daily credits limit—without needing to re-sign-in.

**Why this priority**: Users often subscribe or cancel on web; the app must reflect the same entitlement model.

**Independent Test**: Subscribe or cancel on web; resume the app; verify status matches without re-login. Also verify prepaid-only Pro users still see correct expiry without false auto-renew on.

**Acceptance Scenarios**:

1. **Given** an active monthly or yearly auto-renew subscriber, **When** they open subscription management, **Then** they see tier, interval, catalog price for that plan, auto-renew on/off, and access end or next renewal date.
2. **Given** a prepaid-only Pro user (no auto-renew), **When** they open subscription management, **Then** they see Pro with expiration and auto-renew off or not applicable—not presented as an active recurring plan.
3. **Given** a billing change completed on web, **When** the user resumes or refreshes the app, **Then** status reconciles to the account service (including free→Pro celebration rules already used for upgrades).
4. **Given** status cannot be loaded, **When** the screen is shown, **Then** the user sees a clear error and retry without stale misleading auto-renew or package data.

---

### User Story 5 - Keep prepaid one-time Pro purchase as an alternative (Priority: P2)

**Platforms**: Desktop purchase; status on all

Users who prefer buying a fixed number of months (or using existing balance conversion) can still complete prepaid Pro purchase on desktop. Prepaid remains available alongside auto-renew; starting auto-renew while prepaid time remains follows the account service’s stacking rules without confusing double-charge messaging in the app.

**Why this priority**: Avoid regressing `002-pro-upgrade` prepaid/desktop flows while adding auto-renew.

**Independent Test**: On desktop, complete a one-time multi-month Pro purchase; verify expiry extends. Confirm auto-renew and prepaid options are both discoverable but clearly labeled.

**Acceptance Scenarios**:

1. **Given** a desktop user without a blocking active auto-renew conflict, **When** they complete a one-time prepaid Pro purchase for N months, **Then** Pro expiry extends by N months as today.
2. **Given** subscription options, **When** monthly auto-renew is shown, **Then** its list price is $9.99 per month and is consistent with the prepaid monthly unit used for one-time Pro month math.
3. **Given** the user already has a non-terminal auto-renew source, **When** they attempt to start another auto-renew plan, **Then** the app surfaces the account service’s conflict clearly (cannot run two auto-renew sources) instead of opening a second checkout silently.

---

### User Story 6 - Discover packages when credits are exhausted (Priority: P3)

**Platforms**: All for discovery; desktop for purchase

A signed-in user whose AI request is blocked for credits/billing reasons can open subscription or credits offers and see both upgrade/auto-renew options and credits packages as distinct ways to continue.

**Why this priority**: Completes the “stuck at daily limit” journey already partially covered by upgrade CTAs.

**Independent Test**: Trigger a credits-limit surface; open the linked destination; verify packages and subscription options are both reachable and distinctly labeled on desktop.

**Acceptance Scenarios**:

1. **Given** a signed-in user blocked for credits reasons, **When** the app surfaces the failure, **Then** they have a path to subscription/credits offers (not a dead end).
2. **Given** they open that path on desktop, **When** offers load, **Then** they can choose auto-renew Pro or a credits package without conflating the two products.

---

### Edge Cases

- User starts auto-renew while prepaid Pro time remains — app shows status from the account service; messaging must not imply an immediate second charge for overlapping access beyond what the service documents.
- User tries to start a second auto-renew while one is already active — blocked with a clear message.
- User on monthly wants yearly (or reverse) mid-cycle — no in-app mid-cycle switch; cancel (keep paid time) then start the other plan when allowed.
- User abandons external checkout for auto-renew or a package — returning to the app shows last known status/balance; no false Pro or credit grant.
- Payment succeeds but refresh is slow — existing purchase-pending / resume reconcile behavior applies; soft timeout messaging remains honest.
- Package purchase succeeds but permanent credits take a moment to appear — app refreshes credits summary; user is not left with a silent “paid but unchanged” state without retry/refresh guidance.
- Failed or abandoned package checkout — permanent credits unchanged.
- iOS / Android upgrade or package tap — informational “coming soon”; never open external payment URLs for digital unlock in this milestone.
- One catalog plan missing from the service — only configured plans are offered; the other plan may still appear.
- Offline / slow network — loading then error with retry; no fabricated plan prices or credit amounts.
- Signed-out users — subscription and package purchase routes require sign-in.

## Requirements *(mandatory)*

### Functional Requirements

#### Cross-platform (all targets)

- **FR-001**: The app MUST display subscription status including tier, active/inactive, access end or expiration, daily credits limit, and—when applicable—auto-renew on/off, plan interval (monthly | yearly), and catalog price for the active plan.
- **FR-002**: The app MUST present the Pro auto-renew catalog with monthly ($9.99 / month) and yearly ($99.99 / year) plans when the account service returns them, including enough information to start checkout for a chosen plan on platforms that allow purchase.
- **FR-003**: The app MUST allow users with an active auto-renewing subscription to cancel auto-renew, then show access-through date and refreshed status; cancel MUST NOT remove paid time already purchased.
- **FR-004**: The app MUST offer three one-time credits packages at $2, $5, and $50 USD with permanent credits of 200,000 / 500,000 / 5,000,000 respectively (100,000 credits per $1), clearly labeled as one-time permanent-credit top-ups distinct from subscriptions.
- **FR-005**: Package purchase MUST NOT grant or extend a paid subscription tier by itself; auto-renew subscribe MUST NOT grant credits-package balances by itself.
- **FR-006**: Packages MUST be available to signed-in users whether or not they have an active subscription and whether or not daily allotment is exhausted (subject to platform purchase rules).
- **FR-007**: After successful payment (auto-renew or package), or when the user resumes the app after paying elsewhere, the app MUST refresh status and/or credits so the user sees updated standing without re-sign-in.
- **FR-008**: Prepaid-only Pro users MUST remain accurately represented (expiry, no false auto-renew-on).
- **FR-009**: On iOS and Android, the app MUST NOT initiate external payment checkout for auto-renew or credits packages in this milestone; attempts MUST show clear “mobile purchase coming soon” (or equivalent) copy.
- **FR-010**: User-visible strings MUST be localized for all supported app languages.
- **FR-011**: Loading, error, and retry states MUST cover status, plan catalog, package catalog, cancel, and purchase initiation failures without showing stale misleading billing data.
- **FR-012**: Credits-limit / billing-limit failure surfaces in scope MUST continue to link users to subscription/credits offers, now including package discovery where those offers are shown.

#### Desktop / Linux purchase

- **FR-013**: On Windows, macOS, and Linux, users MUST be able to start auto-renew checkout for a chosen plan via the account service’s external payment URL; the app MUST NOT collect card or wallet credentials in-app.
- **FR-014**: On Windows, macOS, and Linux, users MUST be able to start credits-package checkout the same way (external payment URL), seeing price and credits granted before leaving the app.
- **FR-015**: Existing desktop prepaid Pro month purchase and balance-conversion paths MUST remain available and clearly distinguishable from auto-renew.
- **FR-016**: Before confirming auto-renew or package checkout, the app MUST show price (and interval or credits granted) so the user can abandon without charge.
- **FR-017**: If the account service rejects a second auto-renew while one is active, the app MUST surface that conflict and MUST NOT pretend checkout succeeded.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve feature-first architecture and shared UI / localization / haptics patterns.
- **QR-002**: Changed behavior MUST have automated tests or a documented manual verification reason.
- **QR-003**: Primary subscription and package offer content SHOULD load within 2 seconds on a typical broadband connection; purchase/cancel actions MUST show in-progress feedback within 300 ms of confirmation.
- **QR-004**: Feature behavior changes MUST update `docs/features/subscription.md` (and credits-related feature docs if packages live outside that page).

### Key Entities

- **Subscription status (client view)**: Tier, active flag, access/period end, daily credits limit, auto-renew intent, plan interval, plan price, provider/channel when provided by the account service.
- **Subscription plan (catalog offer)**: Sellable auto-renew option (Pro monthly / Pro yearly) with interval and list price.
- **Auto-renewing subscription**: Ongoing billing relationship managed by the account service; app displays and can start/cancel, not invent a parallel entitlement.
- **Credits package (catalog offer)**: One-time SKU ($2 / $5 / $50) granting permanent credits.
- **Permanent credits wallet**: Non-daily credit balance increased by package purchases; spent after daily allotment per existing product rules.
- **Prepaid purchase intent**: Existing one-time Pro months / balance conversion on desktop; remains available alongside auto-renew.
- **Payment session**: External checkout reference; success is reflected by refreshed status/credits after return or resume.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On desktop, users can identify monthly vs yearly auto-renew and start checkout for a chosen plan in under 1 minute from the subscription surface (excluding time in the payment provider).
- **SC-002**: 100% of successful monthly and yearly subscribe test cases (desktop) result in Pro status with the correct interval and auto-renew on after status refresh.
- **SC-003**: 100% of cancel test cases show auto-renew off and an access-through date, with Pro retained until that date.
- **SC-004**: On desktop, a signed-in user can complete a package purchase path and see matching permanent credits within 2 minutes of successful payment under normal conditions (excluding provider page time).
- **SC-005**: In validation runs, abandoned/failed package or auto-renew checkouts grant no false Pro time and no false permanent credits in the app’s refreshed view.
- **SC-006**: At least 90% of review participants shown the offers can correctly distinguish auto-renew plans from one-time credits packages before paying.
- **SC-007**: iOS/Android users attempting auto-renew or package purchase see the mobile “coming soon” message 100% of the time in this milestone—never an external digital-unlock checkout link.
- **SC-008**: Users who subscribe or cancel on web see matching status in the app after resume/refresh without re-sign-in in 100% of reconciliation test cases.

## Assumptions

- Enjoy Web / account backend already implements auto-renew (monthly/yearly) and credits packages; this feature is **client parity** in Enjoy Player, not a new billing backend.
- Catalog list prices match web: Pro monthly $9.99, Pro yearly $99.99; packages $2 / $5 / $50 at 100,000 permanent credits per $1.
- Platform purchase policy matches `002-pro-upgrade` / ADR-0032: external checkout on desktop (including Linux); StoreKit / Play Billing / RevenueCat deferred.
- Cancel auto-renew from the app is supported by the existing account API for the user’s active non-store auto-renew source; store-managed subscriptions are out of scope until IAP lands.
- Mid-cycle monthly↔yearly switch is out of scope (same as web delivery).
- Prepaid one-time Pro months and balance conversion remain; they are not removed by this feature.
- Tier reconciliation and free→Pro celebration behavior from ADR-0041 remain the mechanism for post-checkout confirmation.
- Guests never see purchase UI (login-only app).
- Tax, receipts, refunds, and provider-hosted pages follow existing account payment practices; the app does not redesign tax localization.

## Out of Scope

- Native App Store / Play Billing / RevenueCat purchase UI and store receipt sync
- Selling non-Pro tiers (e.g. Lite) even if the backend model is tier-aware
- Mid-cycle plan switching while keeping the same continuous auto-renew source
- Changing server-side entitlement, renewal, or package fulfillment rules
- Promotional pricing, trials, family sharing
- Mixin/legacy deposit redesign beyond what prepaid already uses on desktop
