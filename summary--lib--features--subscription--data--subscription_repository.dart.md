<hash>size:2741</hash>

# `lib/features/subscription/data/subscription_repository.dart`

- Riverpod-backed `SubscriptionRepository` wraps status, plan, purchase, auto-renew start, and cancel calls.
- Prepaid purchase forwards `months`, `processor`, and `tier` from `PurchaseRequest`.
- Parses nested or top-level auto-renew cancellation responses.
- Maps HTTP 402 to `CreditsFailure`, 409 to `SubscriptionConflictFailure`, and other API errors to `NetworkFailure`.
