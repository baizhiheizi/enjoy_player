# Subscription & Pro upgrade

## Behavior

Signed-in users open **Subscription** from any of:

- Sidebar account row — Free users see an inline **Upgrade** pill that routes to `/subscription`.
- Profile → Account → **Subscription**.
- Direct route `/subscription`.

### All platforms

- Live status from `GET /api/v1/subscriptions` (tier, active/inactive, expiration, daily credits limit).
- Free vs Pro comparison with feature bullets aligned to the Enjoy web app.
- Pull-to-refresh and automatic refresh when the app returns to foreground (e.g. after desktop checkout in an external browser).
- AI credits-limit errors (HTTP 402) in lookup translation include **View plans** → `/subscription`.

### Desktop (Windows, macOS)

- **Upgrade to Pro** / **Extend subscription** opens a purchase sheet:
  - Duration presets (1 month, 1 season, 1 year, or custom 1–12 months)
  - Processor picker:
    - **Stripe** — Card (Mastercard), WeChat Pay, Alipay, Google Pay
    - **Cryptocurrency** — USDT, USDC, BTC, ETH, DOGE, *and more*
  - External checkout via system browser (`payUrl`)

> **Note** — the `mixin` value is preserved on the wire (Rails API still expects `processor=mixin`); only the UI label is **Cryptocurrency** (en) / **虚拟货币** (zh). `PaymentProcessor.fromJson` continues to accept the `mixin` string.

### Mobile (iOS, Android)

- Status and comparison only in this milestone.
- Upgrade taps show **Mobile purchase coming soon** — no external payment URLs (App Store / Play policy).
- StoreKit / Play Billing deferred to a follow-up spec.

## API (client)

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/v1/subscriptions` | Current subscription status |
| POST | `/api/v1/subscriptions` | Start checkout (`months`, `processor`) — `processor` accepts `stripe` or `mixin` |

Rails API base URL (`apiClientProvider`); bearer auth required.

## Related

- Profile tier chip uses cached `UserProfile.subscriptionTier`.
- `SidebarAccountChip` (`lib/features/auth/presentation/widgets/sidebar_account_chip.dart`) — sidebar entry that opens `/profile` on tap and exposes an inline `/subscription` Upgrade pill for Free users.
- [ADR-0032](../decisions/0032-platform-scoped-subscription-purchase.md) — platform-scoped purchase policy.
