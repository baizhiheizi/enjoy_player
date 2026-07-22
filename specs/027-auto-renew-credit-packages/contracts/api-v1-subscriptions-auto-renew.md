# Contract: Rails `/api/v1/subscriptions` (auto-renew + plans) — Flutter client

**Feature**: `027-auto-renew-credit-packages`  
**Consumer**: `SubscriptionApi` / `SubscriptionRepository`  
**Server source of truth**: enjoy_web `specs/002-subscription-pricing-plans/contracts/api-v1-subscriptions.md`  
**Auth**: Bearer JWT via existing `ApiClient`  
**Wire format**: Rails snake_case; client models use camelCase after `ApiClient` conversion

Prepaid `POST /api/v1/subscriptions` remains as in `002-pro-upgrade/contracts/subscription-api.md`.

---

## GET `/api/v1/subscriptions/plans`

### Response `200` (client camelCase)

```json
{
  "plans": [
    {
      "id": "pro_month",
      "tier": "pro",
      "interval": "month",
      "amount": 9.99,
      "currencyNote": "Final charge amount shown on Stripe Checkout"
    },
    {
      "id": "pro_year",
      "tier": "pro",
      "interval": "year",
      "amount": 99.99,
      "currencyNote": "Final charge amount shown on Stripe Checkout"
    }
  ]
}
```

| Client method | Notes |
|---------------|--------|
| `SubscriptionApi.listPlans()` | Map to `List<SubscriptionPlan>` |

### Errors

- `401` → signed-out / auth failure path

---

## GET `/api/v1/subscriptions`

### Response `200` (additive)

Existing fields plus nullable `autoRenew`:

```json
{
  "subscriptionActive": true,
  "subscriptionTier": "pro",
  "subscriptionExpireDate": "2027-07-20T00:00:00.000Z",
  "autoRenew": {
    "active": true,
    "provider": "stripe",
    "status": "active",
    "autoRenew": true,
    "currentPeriodEnd": "2027-07-20T00:00:00.000Z",
    "cancelAtPeriodEnd": false,
    "payUrl": null,
    "planId": "pro_year",
    "tier": "pro",
    "interval": "year",
    "amount": 99.99
  }
}
```

When no non-terminal billing subscription: `autoRenew` is `null`.

| Client method | Notes |
|---------------|--------|
| `SubscriptionApi.getStatus()` | Extend `SubscriptionStatus.fromJson` |

---

## POST `/api/v1/subscriptions/auto_renew`

### Request

```json
{ "planId": "pro_month" }
```

(Wire: `plan_id`. Prefer `planId` over tier+interval.)

### Response `200`

```json
{
  "id": "uuid",
  "provider": "stripe",
  "status": "incomplete",
  "autoRenew": true,
  "payUrl": "https://checkout.stripe.com/c/pay/cs_...",
  "currentPeriodEnd": null,
  "planId": "pro_month",
  "tier": "pro",
  "interval": "month",
  "price": {
    "interval": "month",
    "amount": 9.99,
    "currencyNote": "Final charge amount shown on Stripe Checkout"
  }
}
```

### Client behavior

1. Purchase-capable platforms only (`supportsExternalSubscriptionPurchase`).
2. If `payUrl` non-empty → `launchUrl` external + `markPurchasePending()`.
3. Empty `payUrl` → error notice; do not claim success.

### Errors

| Status | Client handling |
|--------|-----------------|
| `400` | Show message; keep plan selection |
| `409` | Distinct “already subscribed” / conflict copy |
| `401` | Auth failure |

---

## POST `/api/v1/subscriptions/cancel`

### Request

Empty body.

### Response `200`

Billing subscription payload including `autoRenew` / `cancelAtPeriodEnd` / `currentPeriodEnd` plus entitlement fields (`subscriptionActive`, `subscriptionExpireDate`, plan snapshot fields when present).

### Client behavior

1. Confirm dialog with access-through expectation.
2. On success → invalidate `subscriptionStatusProvider` (+ profile refresh if used).
3. Show notice with access-through date.

### Errors

| Status | Client handling |
|--------|-----------------|
| `404` | Nothing to cancel |
| `400` | Not cancelable / processor error |
| `401` | Auth failure |
