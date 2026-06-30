# Subscription & Pro upgrade

## Behavior

Signed-in users open **Subscription** from Profile → Account or navigate to `/subscription`.

### All platforms

- Live status from `GET /api/v1/subscriptions` (tier, active/inactive, expiration, daily credits limit).
- Free vs Pro comparison with feature bullets aligned to the Enjoy web app.
- Pull-to-refresh and automatic refresh when the app returns to foreground (e.g. after desktop checkout in an external browser).
- AI credits-limit errors (HTTP 402) in lookup translation include **View plans** → `/subscription`.

### Desktop (Windows, macOS)

- **Upgrade to Pro** / **Extend subscription** opens a purchase sheet:
  - Duration 1–12 months
  - Stripe or Mixin processor
  - External checkout via system browser (`payUrl`)
  - **Use balance** tab converts account balance to subscription time (with confirmation)

### Mobile (iOS, Android)

- Status and comparison only in this milestone.
- Upgrade taps show **Mobile purchase coming soon** — no external payment URLs (App Store / Play policy).
- StoreKit / Play Billing deferred to a follow-up spec.

## API (client)

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/v1/subscriptions` | Current subscription status |
| POST | `/api/v1/subscriptions` | Start checkout (`months`, `processor`) |
| POST | `/api/v1/subscriptions/balance` | Convert balance to subscription |

Rails API base URL (`apiClientProvider`); bearer auth required.

## Related

- Profile tier chip uses cached `UserProfile.subscriptionTier`; refreshed after balance purchase.
- [ADR-0032](../decisions/0032-platform-scoped-subscription-purchase.md) — platform-scoped purchase policy.
