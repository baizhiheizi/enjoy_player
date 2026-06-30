# ADR-0032: Platform-scoped subscription purchase

## Status

Accepted — 2026-06-30

## Context

Enjoy web sells Pro subscriptions via Stripe/Mixin external checkout. Enjoy Player must port subscription management while respecting mobile store policies:

- **Apple App Store** requires StoreKit for digital Pro unlocks consumed in the app.
- **Google Play** has similar requirements for Play-distributed builds.
- **Windows / macOS** direct-download builds can use the same external checkout as the web app.

Product decision **B**: ship shared status/comparison on all platforms in v1; defer iOS/Android in-app purchase to a follow-up spec.

## Decision

1. **Cross-platform**: `/subscription` screen, status API, tier comparison, profile entry, credits-limit upgrade navigation.
2. **Desktop only (Windows + macOS)**: external checkout + balance conversion via existing Enjoy Rails API.
3. **iOS / Android v1**: show “mobile purchase coming soon”; never launch external `payUrl` for Pro upgrade.
4. **Follow-up**: StoreKit (iOS) and Play Billing (Android) in a separate feature spec.

Platform gate lives in `lib/core/platform/subscription_purchase_capability.dart` (explicit Windows || macOS — not `isDesktop`, which includes Linux).

## Consequences

- Positive: App Review–safe mobile build; desktop revenue path matches web quickly.
- Positive: Single subscription status source of truth on server; cross-device Pro display works immediately.
- Negative: iOS/Android users cannot purchase in-app until follow-up; must upgrade on web/desktop first.
- Negative: Two purchase adapters long-term (external checkout + store IAP).

## Alternatives considered

| Alternative | Rejected because |
|-------------|------------------|
| External checkout on all platforms | iOS rejection risk |
| Hide subscription on mobile | Users need status; Pro purchased elsewhere must display |
| StoreKit in same milestone | Larger scope; user chose deferral |

## Related

- Feature spec: `specs/002-pro-upgrade/spec.md`
- `docs/features/subscription.md`
