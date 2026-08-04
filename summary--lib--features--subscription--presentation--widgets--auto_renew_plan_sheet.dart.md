<hash>size:27214</hash>

# `lib/features/subscription/presentation/widgets/auto_renew_plan_sheet.dart`

- `showUnifiedPurchaseSheet` accepts a selected Lite/Pro tier and monthly/yearly interval.
- Compact layouts use a bottom sheet; wide layouts use an adaptive centered dialog.
- Auto-renew is the default primary path; prepaid months and processor selection are secondary.
- Mobile shows an unavailable dialog, and unsupported platforms do not launch external checkout.
- The sheet resolves the matching server plan and preserves subscription-conflict failures.
