<size>5173</size>

# `lib/features/sync/application/sync_controller.dart`

- `SyncCtrl` drains `sync_queue` and pulls recording metadata per target when the user is signed in and the player opens media.
- Re-keys pending imports, drains outbound queue, and (when applicable) pulls recordings for the active `targetType` + `targetId`.
- Local-first: the queue is preserved on connectivity loss and retry runs on the next eligible window.
