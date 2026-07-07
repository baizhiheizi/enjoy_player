<size>8405</size>

# `lib/core/recovery/recovery_surface.dart`

- `RecoverySurface` — UI shown when `appPreferencesCtrlProvider` fails to resolve.
- Accepts an injectable `onReset` callback.
- Two actions: **Copy error** (uses `copyErrorToClipboard`) and **Reset** (invokes `performRecoveryReset`).
- Localized strings (en / zh / zh-CN) updated to reflect in-place reload on successful reset.
