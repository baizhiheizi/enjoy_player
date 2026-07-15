<hash>size:3600</hash>

# `lib/features/sync/application/sync_controller.dart`

- `SyncCtrl` starts a full queue drain after sign-in and a five-minute authenticated timer.
- Sign-out cancels periodic work; `kickDrain` triggers a non-blocking queue pass.
- Successful full sync records `sync.last_full_sync_at` in settings.
