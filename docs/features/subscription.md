# Subscription & Pro upgrade

## Behavior

Signed-in users open **Subscription** from any of:

- Sidebar account row — Free users see an inline **Upgrade** pill that routes to `/subscription`.
- Profile → Account → **Subscription**.
- Direct route `/subscription`.

### All platforms

- Live status from `GET /api/v1/subscriptions` (tier, active/inactive, expiration, daily credits limit).
- Free vs Pro comparison with feature bullets aligned to the Enjoy web app.
- Pull-to-refresh on the subscription screen; automatic tier reconciliation on app resume and cold start (see [ADR-0041](../decisions/0041-unified-tier-reconciliation.md)).
- AI credits-limit errors (HTTP 402) in lookup translation include **View plans** → `/subscription`.

### Tier source of truth

All tier indicators (sidebar chip, profile hero card, subscription screen) read the single synchronous `currentTierProvider`, which prefers live `subscriptionStatusProvider` and falls back to the cached `UserProfile.subscriptionTier` while the live status is loading on cold start. Never read `UserProfile.subscriptionTier` directly in UI — it is a cache, not the source of truth.

### Reconciliation & celebration

- `TierReconcileHost` (mounted in `RootShell`) is a global `WidgetsBindingObserver`. On `AppLifecycleState.resumed` and on (re)sign-in it runs `TierReconcileCtrl.reconcile()`, which refreshes **both** the live status and the cached profile. This means a Pro upgrade made anywhere — app-initiated desktop checkout, or directly on the web — surfaces on the next resume or cold start without a manual refresh.
- When a genuine `free → pro` transition is detected, an `AppNotice.success` snackbar ("You're now Pro — enjoy!") is shown. Already-Pro users are never re-celebrated.
- For app-initiated purchases, `markPurchasePending()` arms an **eager** resume reconcile that polls the status endpoint for fast confirmation, showing a "Verifying your upgrade…" notice and a soft timeout message if confirmation takes longer than ~30 s (the debounced background reconcile still catches it).

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

- Tier UI reads `currentTierProvider` (single source of truth); reconciliation is owned by `TierReconcileCtrl` + `TierReconcileHost`.
- `SidebarAccountChip` (`lib/features/auth/presentation/widgets/sidebar_account_chip.dart`) — sidebar entry that opens `/profile` on tap and exposes an inline `/subscription` Upgrade pill for Free users.
- [ADR-0032](../decisions/0032-platform-scoped-subscription-purchase.md) — platform-scoped purchase policy.
- [ADR-0041](../decisions/0041-unified-tier-reconciliation.md) — unified tier reconciliation.
