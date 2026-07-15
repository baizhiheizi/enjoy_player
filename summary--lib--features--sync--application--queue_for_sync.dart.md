<hash>size:2617</hash>

# `lib/features/sync/application/queue_for_sync.dart`

- Serializes local create/update rows and inserts or coalesces outbound queue work.
- Marks audio/video/recording rows pending and serializes YouTube subscription metadata.
- Starts an asynchronous queue drain when authenticated.
