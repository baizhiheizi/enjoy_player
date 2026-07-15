<hash>size:1690</hash>

# `lib/core/utils/stream_distinct.dart`

- `StreamDistinctExt<T>.distinctBy(equals)` forwards only values unequal to the last forwarded emission.
- Dedupe state is per subscriber.
- Used by transcript and other long-lived Drift streams before Riverpod notification.
