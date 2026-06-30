# Quickstart: Pro Upgrade & Subscription Management

**Feature**: `002-pro-upgrade` | **Date**: 2026-06-30

Validation guide after implementation. See [contracts/](./contracts/) for behavioral contracts and [data-model.md](./data-model.md) for entities.

## Prerequisites

- Flutter SDK matching `pubspec.yaml`
- Enjoy API reachable (`api.base_url` configured)
- Test Enjoy account — Free tier for upgrade tests; optional second account or web purchase for Pro status test
- **Desktop**: Windows or macOS build for checkout validation
- **Mobile**: iOS Simulator or Android emulator for coming-soon guardrail test

## Setup

```bash
cd c:/Users/me/dev/enjoy_player
flutter pub get
dart run build_runner build
flutter gen-l10n
```

## Automated verification

```bash
flutter analyze
flutter test test/features/subscription/
flutter test test/core/platform/subscription_purchase_capability_test.dart
flutter test
```

**Expected**: All tests pass; analyzer clean on touched files.

## Manual scenarios

### QS-1 — Subscription status (all platforms, SC-001)

1. Sign in as Free user.
2. Profile → Subscription (or navigate to `/subscription`).

**Expected**:

- Tier: Free, daily credits 1,000
- Free plan marked current in comparison
- Pro plan visible with feature bullets

### QS-2 — Pro status from cross-device purchase (SC-007)

1. Upgrade same account on web or desktop (outside this test if needed).
2. Open `/subscription` on iOS Simulator.

**Expected**: Pro tier, 60,000 credits limit, expiration shown; no purchase required on iOS.

### QS-3 — Desktop external checkout (SC-002)

**Platform**: Windows or macOS only.

1. Sign in as Free user.
2. Subscription → Upgrade to Pro.
3. Select 1 month, Stripe, Continue to Payment.

**Expected**:

- External browser opens with checkout URL
- In-app loading/confirmation feedback
- Return to app → pull refresh or resume → status updates after payment completes

### QS-4 — Desktop balance purchase (SC-003)

**Platform**: Windows or macOS; account with positive balance.

1. Subscription → Use Balance tab → confirm.

**Expected**: Success notice; Pro status updated; profile balance reduced per server.

### QS-5 — iOS purchase guardrail (SC-006)

**Platform**: iOS Simulator.

1. Sign in as Free user.
2. Subscription → Upgrade to Pro.

**Expected**:

- “Coming soon” dialog (or equivalent)
- **No** external browser opens
- **No** Stripe/Mixin URL launched

Repeat on Android emulator (QS-5b).

### QS-6 — Credits failure CTA (SC-004)

1. As Free user, trigger AI action that returns 402 (or mock in debug).
2. Tap upgrade/view plans action.

**Expected**: Navigates to `/subscription`.

### QS-7 — Auth gate

1. Sign out.
2. Attempt `/subscription`.

**Expected**: Redirect to `/sign-in?from=subscription`; after sign-in, land on subscription screen.

### QS-8 — Error + retry

1. Disconnect network.
2. Open `/subscription`.

**Expected**: Error state with Retry; no stale tier data presented as current.

## Platform matrix

| Scenario | Windows | macOS | iOS | Android |
|----------|---------|-------|-----|---------|
| QS-1 status | Required | Required | Required | Required |
| QS-3 checkout | Required | Required | N/A | N/A |
| QS-5 guardrail | N/A | N/A | Required | Required |
| QS-5b guardrail | N/A | N/A | Optional | Required |

## Failure triage

| Symptom | Likely cause |
|---------|--------------|
| 401 on subscription GET | Token expired; check auth refresh |
| Empty payUrl on desktop | Server response; show error per contract |
| Browser opens on iOS | Missing platform guard — fix capability check |
| Profile tier stale after purchase | Forgot to invalidate `authCtrlProvider` / fetchProfile |
| Route not found | `/subscription` not registered in router |

## Done criteria

- [ ] QS-1, QS-5, QS-7 pass on primary dev platform
- [ ] QS-3 pass on Windows or macOS with test payment (or staging)
- [ ] Automated subscription tests green
- [ ] `docs/features/subscription.md` and ADR-0032 published
- [ ] `flutter gen-l10n` run after ARB updates

## Next milestone

iOS StoreKit purchase — separate spec (`003-ios-storekit-upgrade`) after this ships.
