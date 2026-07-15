<hash>size:10164</hash>

# `docs/features/discover.md`

- Discover supports recommended channels plus local subscriptions to channels, handles, and playlists.
- Feeds come only from the Worker RSSHub proxy as JSON Feed v1.1.
- Refresh is one-hour throttled, four-source concurrent, partial-failure tolerant, and append-only until unsubscribe.
- Cached entries can be imported into the local library.
