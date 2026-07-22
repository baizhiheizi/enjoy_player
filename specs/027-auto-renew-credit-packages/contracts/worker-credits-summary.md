# Contract: Worker `GET /credits/summary` — Flutter client

**Feature**: `027-auto-renew-credit-packages`  
**Consumer**: Worker `CreditsApi` (`aiApiClientProvider`)  
**Parity**: enjoy `@enjoy/ai` `createCreditsApi().getSummary()` → `CreditsSummary`  
**Auth**: Worker bearer (existing AI client)

---

## GET `/credits/summary`

### Response `200` (client camelCase)

```json
{
  "tier": "free",
  "dailyUsed": 1200,
  "dailyLimit": 1000,
  "dailyRemaining": 0,
  "permanentAvailable": 500000,
  "resetAt": 1721692800000
}
```

| Field | Type | Use in this feature |
|-------|------|---------------------|
| `dailyUsed` / `dailyLimit` / `dailyRemaining` | int | Optional standing display; 402 context |
| `permanentAvailable` | int | **Primary** post–package-purchase verification |
| `tier` | string | Display only; Pro gates still use subscription status |
| `resetAt` | number | Optional daily reset copy |

| Client method | Notes |
|---------------|--------|
| `CreditsApi.getSummary()` | New; provider e.g. `creditsSummaryProvider` |

### Client behavior after package checkout

1. Snapshot `permanentAvailable` before launch (if available).
2. On resume with package pending: invalidate/poll summary until value increases by expected package credits **or** any increase with soft timeout (~30s) + user-visible verifying/timeout notices (mirror Pro reconcile tone).
3. Success notice when permanent balance reflects the grant.

### Errors

- `401` → auth path
- Network failures → retryable error on credits/subscription surfaces

### Non-goals

- Replacing `/credits/usages` audit screen
- Changing Worker grant semantics
