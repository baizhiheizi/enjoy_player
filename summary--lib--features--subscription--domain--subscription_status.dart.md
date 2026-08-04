<hash>size:2282</hash>

# `lib/features/subscription/domain/subscription_status.dart`

- `SubscriptionStatus` parses live tier, activity, expiration, and optional auto-renew details.
- Derived getters: `isPro`, `isLite`, `isPaidTier`, and `hasActiveAutoRenewPlan`.
- Daily credit limits are Free 1,000, Lite 12,000, and Pro 60,000 for active tiers.
- Unknown or missing tier values fall back to `SubscriptionTier.free`.
