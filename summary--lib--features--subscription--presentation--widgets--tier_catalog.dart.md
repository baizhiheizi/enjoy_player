<hash>size:26651</hash>

# `lib/features/subscription/presentation/widgets/tier_catalog.dart`

- `TierCatalog` renders unified Free, Lite, and Pro selection with monthly/yearly intervals.
- Paid cards invoke `onChoosePaid(SubscriptionTier, CatalogInterval)`; the older Pro-only callback remains deprecated.
- Plan prices and annual savings derive from `subscriptionPlansProvider`; unloaded plans render skeleton state.
- The catalog is hidden while a non-terminal auto-renew subscription is active.
