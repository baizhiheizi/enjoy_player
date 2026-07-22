# Contract: Rails `/api/v1/credits/packages` — Flutter client

**Feature**: `027-auto-renew-credit-packages`  
**Consumer**: new Rails credits-packages API service + credits feature providers  
**Server source of truth**: enjoy_web `specs/004-credits-packages/contracts/api-v1-credits-packages.md`  
**Auth**: Bearer JWT via Rails `ApiClient` (not Worker)  
**Wire format**: snake_case ↔ camelCase via `ApiClient`

---

## GET `/api/v1/credits/packages`

### Response `200`

```json
{
  "packages": [
    {
      "id": "credits_2",
      "amount": "2.00",
      "currency": "USD",
      "credits": 200000,
      "rate": { "usd": 1, "credits": 100000 }
    },
    {
      "id": "credits_5",
      "amount": "5.00",
      "currency": "USD",
      "credits": 500000,
      "rate": { "usd": 1, "credits": 100000 }
    },
    {
      "id": "credits_50",
      "amount": "50.00",
      "currency": "USD",
      "credits": 5000000,
      "rate": { "usd": 1, "credits": 100000 }
    }
  ]
}
```

| Client method | Notes |
|---------------|--------|
| `listPackages()` | Map to `List<CreditsPackage>`; `amount` stays string |

### Errors

- `401` Unauthorized

---

## POST `/api/v1/credits/packages/purchases`

### Request

```json
{ "packageId": "credits_5" }
```

### Response `200`

```json
{
  "id": "payment-uuid",
  "status": "pending",
  "paymentType": "credits_package",
  "amount": "5.00",
  "payUrl": "https://checkout.stripe.com/c/pay/cs_...",
  "package": {
    "id": "credits_5",
    "amount": "5.00",
    "currency": "USD",
    "credits": 500000
  }
}
```

### Client behavior

1. Show `package.amount` + `package.credits` before leave-app.
2. Purchase-capable platforms only; mobile → coming soon (no `payUrl`).
3. Launch `payUrl` externally; mark package-purchase pending; on resume poll Worker credits summary until `permanentAvailable` increases or soft timeout.
4. Do not claim credits granted until summary (or explicit success path) confirms.

### Errors

| Status | Client handling |
|--------|-----------------|
| `422` / `400` | Invalid/missing `packageId` |
| `503` / `502` | Checkout unavailable; retry |
| `401` | Auth failure |

### Non-goals

- Client does not call Worker grant APIs.
- Package purchase must not mutate subscription tier fields.
