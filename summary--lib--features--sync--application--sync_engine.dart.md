<hash>size:4891</hash>

# `lib/features/sync/application/sync_engine.dart`

- Drains eligible queue rows in batches of ten with exponential retry timing and a five-attempt cap.
- Upload/delete implementations cover audio, video, and recordings.
- `youtube_subscription` is recognized but remote processing is deferred.
- `fullSync` intentionally does not mirror the remote library.
