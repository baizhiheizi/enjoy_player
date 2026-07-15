<hash>size:15674</hash>

# `lib/features/discover/data/discover_repository.dart`

- Stores subscriptions and feed entries in Drift and bridges feed entries into library imports.
- Resolves user input, canonicalizes handles, and persists source type/feed URL metadata.
- Refreshes eligible sources in batches of four, upserts entries, updates source metadata, and reports partial failures.
- Uses a bounded TTL avatar cache.
