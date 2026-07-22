# Quickstart: Validate App Auto-Renew & Credits Packages

**Feature**: `027-auto-renew-credit-packages`  
**Date**: 2026-07-22

Validation guide for implementers. Server contracts: [api-v1-subscriptions-auto-renew.md](./contracts/api-v1-subscriptions-auto-renew.md), [api-v1-credits-packages.md](./contracts/api-v1-credits-packages.md), [worker-credits-summary.md](./contracts/worker-credits-summary.md). Domain: [data-model.md](./data-model.md).

## Prerequisites

- Enjoy Player checkout with signed-in test user against an environment where Rails has Stripe Price ids for `pro_month` / `pro_year` and credits packages enabled
- Desktop or Linux build for purchase paths; iOS/Android simulator/device for gates
- Ability to complete or abandon Stripe Checkout in an external browser

## Automated checks (after implementation)

```bash
cd /home/an-lee/projects/enjoy_player

# After adding @Riverpod / Freezed / Drift annotations:
dart run build_runner build

flutter analyze
flutter test test/features/subscription test/features/credits test/core/platform/subscription_purchase_capability_test.dart

# Before push:
bash .github/scripts/validate_ci_gates.sh
# or: bash .github/scripts/validate_ci_gates.sh --fix
```

Expected: format + codegen drift clean; analyze/tests green for new JSON parsers, repository methods, platform gate (Linux true), widget coverage for plan/package/cancel/mobile blocked purchase.

## Manual scenarios

### A. Auto-renew monthly / yearly (desktop or Linux)

1. Sign in as free user → open `/subscription`.
2. Confirm monthly ($9.99) and yearly ($99.99) plans appear when catalog configured.
3. Start **monthly** → confirm amount/interval → external checkout opens.
4. Complete payment → return/resume app → status shows Pro, auto-renew on, interval month, period end.
5. Repeat with a clean user for **yearly**.

**Pass**: Status matches [data-model](./data-model.md) `AutoRenewBilling`; free→Pro celebration once.

### B. Cancel auto-renew (any platform)

1. As active auto-renew subscriber, open `/subscription` → Cancel.
2. Confirm → notice shows access-through date; auto-renew off / `cancelAtPeriodEnd`.
3. Pro remains until period end.

**Pass**: Refresh matches Rails; failure leaves prior state.

### C. Credits package (desktop or Linux)

1. Note Worker summary `permanentAvailable` (UI or debug).
2. Buy `$5` package → confirm credits (500,000) → external checkout.
3. Complete payment → resume → permanent credits increase by 500,000; subscription unchanged.
4. Abandon a second checkout → permanent credits unchanged.

**Pass**: SC-004 style outcome; no false Pro grant.

### D. Mobile purchase gates

1. On iOS or Android, tap auto-renew subscribe and package buy.
2. **Pass**: Coming-soon dialog; no external `payUrl`.
3. Cancel still available if subscribed via web/desktop.

### E. Conflict & prepaid coexistence

1. With active auto-renew, attempt second auto-renew → conflict message (`409`).
2. Free user without auto-renew can still use prepaid months sheet (secondary path).

### F. Web → app reconcile

1. Subscribe or cancel on web → resume app → status matches without re-sign-in.

## Smoke checklist

| # | Check | OK |
|---|-------|----|
| 1 | Plans list + start auto-renew `payUrl` | |
| 2 | Status shows interval + auto-renew flags | |
| 3 | Cancel at period end | |
| 4 | Package list + purchase `payUrl` | |
| 5 | Summary `permanentAvailable` updates | |
| 6 | Mobile never opens digital unlock checkout | |
| 7 | Linux purchase enabled | |
| 8 | Docs updated (`subscription.md`, credits docs, ADR-0032) | |
