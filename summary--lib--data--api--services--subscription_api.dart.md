<hash>size:1005</hash>

# `lib/data/api/services/subscription_api.dart`

- `SubscriptionApi` targets `/api/v1/subscriptions`.
- Supports status and plan-list GETs plus prepaid purchase, auto-renew start, and cancellation POSTs.
- Prepaid purchase body includes `months`, processor API value, and selected `tier`.
