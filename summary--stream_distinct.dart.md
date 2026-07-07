<size>1690</size>

# `lib/core/utils/stream_distinct.dart`

- Shared extension `StreamDistinctExt<T>` on `Stream<T>`.
- `distinctBy(bool Function(T previous, T current) equals)` — returns a stream that forwards emissions for which `equals` returns `false` against the last forwarded value.
- Per-subscriber dedupe state (matches Drift's per-subscriber semantics).
- Used by transcript tracks, transcript lines, and other repositories that need to suppress redundant re-emissions before they reach Riverpod listeners.
