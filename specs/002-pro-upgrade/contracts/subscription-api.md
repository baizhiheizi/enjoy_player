# Contract: Subscription API

**Feature**: `002-pro-upgrade` | **Consumer**: `SubscriptionApi` / `SubscriptionRepository` | **Version**: 1.0

## Base URL

Enjoy Rails API — same origin as `AuthApi` (`apiClientProvider` / `SettingsKeys.apiBaseUrl`).

## Authentication

All endpoints require bearer token (existing `ApiClient` behavior).

## Endpoints

### GET `/api/v1/subscriptions`

**Response** (camelCase JSON):

```json
{
  "subscriptionActive": true,
  "subscriptionTier": "pro",
  "subscriptionExpireDate": "2026-12-31T00:00:00.000Z"
}
```

| Field | Type | Notes |
|-------|------|-------|
| `subscriptionActive` | boolean | |
| `subscriptionTier` | `"free"` \| `"pro"` | |
| `subscriptionExpireDate` | string \| null | ISO 8601 |

### POST `/api/v1/subscriptions`

**Request**:

```json
{
  "months": 3,
  "processor": "stripe"
}
```

| Field | Required | Validation |
|-------|----------|------------|
| `months` | yes | 1–12 |
| `processor` | no | `"stripe"` \| `"mixin"`; default server-side if omitted |

**Response**:

```json
{
  "id": "uuid",
  "paymentType": "subscription",
  "processor": "stripe",
  "status": "pending",
  "payUrl": "https://checkout.stripe.com/...",
  "createdAt": "2026-06-30T12:00:00.000Z"
}
```

**Client behavior (desktop only)**:

- If `payUrl` non-empty → launch external browser.
- If `payUrl` empty → show error toast/notice.
- Invalidate subscription status provider after initiation.

### POST `/api/v1/subscriptions/balance`

**Request**: empty body

**Response**: same shape as GET status (updated subscription after conversion).

**Client behavior (desktop only)**:

- Requires confirmation dialog before POST.
- On success: refresh status + profile; show success notice.
- On error: show `AppFailure` message.

## Error handling

| Status | Mapping |
|--------|---------|
| 401 | Existing refresh → sign-out path |
| 4xx/5xx | `NetworkFailure` or message-bearing `AppFailure` |

## Reference

Web implementation: `C:\Users\me\dev\enjoy\packages\api\src\services\subscription.ts`
