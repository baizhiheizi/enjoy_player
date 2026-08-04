<hash>size:14538</hash>

# `lib/features/subscription/presentation/widgets/subscription_status_card.dart`

- `SubscriptionStatusCard` renders a basic Free card or a rich paid-membership card for Lite and Pro.
- Paid cards show tier-aware title/badge, billing interval and amount, renewal/expiry date, and daily credits.
- Cancel auto-renew is available only when billing is cancelable; extension is hidden during active renewal.
- Cancellation refreshes live status and reports localized success/failure notices.
