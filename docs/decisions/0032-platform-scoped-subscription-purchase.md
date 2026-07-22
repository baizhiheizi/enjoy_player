# ADR-0032: Platform-scoped subscription purchase

## Status

Accepted — 2026-06-30  
**Amended** — 2026-07-22 (Linux external checkout)

## Context

Enjoy web sells Pro subscriptions via Stripe/Mixin external checkout. Enjoy Player must port subscription management while respecting mobile store policies:

- **Apple App Store** requires StoreKit for digital Pro unlocks consumed in the app.
- **Google Play** has similar requirements for Play-distributed builds.
- **Windows / macOS / Linux** direct-download builds can use the same external checkout as the web app.

Product decision **B**: ship shared status/comparison on all platforms in v1; defer iOS/Android in-app purchase to a follow-up spec.

Linux was initially excluded from external checkout in the v1 helper (`windows || macOS` only). After Linux became a first-class desktop target ([ADR-0048](0048-linux-platform-support.md)) and billing parity feature `027-auto-renew-credit-packages`, Linux direct-download builds should use the same external checkout path as Windows and macOS.

## Decision

1. **Cross-platform**: `/subscription` screen, status API, tier comparison, profile entry, credits-limit upgrade navigation; auto-renew cancel where the account service allows.
2. **Desktop external checkout (Windows + macOS + Linux)**: Stripe/Mixin prepaid months, Stripe auto-renew, and credits-package checkout via existing Enjoy Rails API + system browser `payUrl`.
3. **iOS / Android v1**: show “mobile purchase coming soon”; never launch external `payUrl` for digital unlock (Pro or credits packages). Cancel auto-renew remains allowed (no payment URL).
4. **Follow-up**: StoreKit (iOS) and Play Billing (Android) / RevenueCat in a separate feature spec.

Platform gate lives in `lib/core/platform/subscription_purchase_capability.dart` (explicit `windows || macOS || linux` — not a vague “desktop” heuristic that could drift).

## Consequences

- Positive: App Review–safe mobile build; desktop (including Linux) revenue path matches web.
- Positive: Single subscription status source of truth on server; cross-device Pro display works immediately.
- Negative: iOS/Android users cannot purchase in-app until follow-up; must upgrade on web/desktop first.
- Negative: Two purchase adapters long-term (external checkout + store IAP).

## Alternatives considered

| Alternative | Rejected because |
|-------------|------------------|
| External checkout on all platforms | iOS rejection risk |
| Hide subscription on mobile | Users need status; Pro purchased elsewhere must display |
| StoreKit in same milestone | Larger scope; deferred |
| Keep Linux blocked | Contradicts first-class Linux desktop + `027` parity |

## Related

- Feature specs: `specs/002-pro-upgrade/spec.md`, `specs/027-auto-renew-credit-packages/spec.md`
- `docs/features/subscription.md`
- [ADR-0048](0048-linux-platform-support.md)
