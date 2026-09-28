# ADR-0088: Discover feed owns library membership (one merged watch)

## Status

Accepted

## Context

Issue `#764` (architecture review, pass 2) listed "Discover — own the merge,
invert the binding" as a module-deepening candidate. The audit's framing was
partly wrong and is corrected here:

- **There was no circular discover↔library dependency.** Discover data already
  imported the library repository one-way. The "late-bound runtime rebind"
  (`bindLibraryRepository`, called from inside the provider body) ran once per
  repository construction, not "on every watch" as the audit claimed — a
  keep-alive provider rebuilds only when a dependency changes.
- The defect underneath that framing was real, and is what this ADR decides:
  **library membership was a widget concern.**

`DiscoverFeedTile` answered "is this video already in my library?" by awaiting
`isVideoInLibrary` in `initState` (and again in `didUpdateWidget` when the
video id changed), caching the answer in a widget-local `bool? _inLibrary`, and
correcting it after an import with two `ref.invalidate` calls from inside the
tile. Consequences:

- **N queries per scroll burst.** A discover grid renders roughly 15–25 live
  tiles (1–4 columns, plus sliver `cacheExtent` prefetch), so a scroll issued
  that many indexed `SELECT`s, each behind its own async gap.
- **Correctness depended on a widget remembering.** `ref.invalidate(libraryMediaProvider)`
  in `_addToLibrary` was the only thing keeping the badge honest. Any other
  path that changed library membership left the tile stale.
- **UI-locality where repo-locality belongs.** A rendering decision depended on
  an async probe resolving.

## Decision

1. **The join is owned by the discover application layer.**
   `discoverFeedItemsProvider` / `discoverChannelFeedItemsProvider` join the feed
   stream with `MediaRegistry.watchYoutubeVideoIds()` through `joinLatest` in
   [`discover_feed_join.dart`](../../lib/features/discover/application/discover_feed_join.dart).
   Each emission is a `DiscoverFeedItem` carrying `entry` + `inLibrary`.
2. **Tiles render; they do not probe.** `DiscoverFeedTile` takes `inLibrary` as
   a required constructor argument and carries no membership state, no probe
   lifecycle, and no `ref.invalidate`.
3. **The join waits for both first values** before emitting, so the grid never
   paints every tile as "not in library" and then flips them on the library's
   first delivery.
4. **`.distinctBy` on the projected list**, because the merged stream also
   fires on library writes.
5. **The library dependency is a required constructor argument.**
   `bindLibraryRepository` and its `StateError('... not bound')` path are
   deleted: a repository that cannot import is not representable.

## Consequences

- One subscription serves the whole grid instead of one query per tile.
- Membership after "add to library" arrives through the registry stream, so the
  manual invalidation is gone rather than merely relocated.
- **ADR-0046 is untouched.** The join sits strictly above the append-only feed
  cache — no insert, prune, or `deleteForChannel` path changed. The merge is a
  read-side projection.
- `MediaRegistry.watchYoutubeVideoIds` watches the `videos` table only, so an
  audio-only library write does not rebuild the feed.
- That membership stream is **broadcast**, unlike `watchAll`, because the merged
  timeline and a channel view can both be subscribed at once (the timeline
  provider is keep-alive, so opening a channel does not tear it down) and a
  single-subscription stream would throw on the second listener. Each listener
  carries its **own** drift subscription and its **own** dedupe state — hoisting
  that state out of the `Stream.multi` callback makes the second listener of the
  same returned stream dedupe against the first and silently receive nothing.
  `media_registry_test.dart` pins that with two listeners on one stream object.
- `DiscoverRepository`'s constructor gained a required named parameter. That is
  deliberate constructor-level churn across direct-construction test sites: it
  is what makes the unwired state unrepresentable.
- Deleting the duplicated `filteredDiscoverTimelineProvider` (byte-identical to
  `discoverTimelineProvider`) removes a second name for one stream.

## Related

- Issue `#764` candidate 6; MediaRegistry seam from #765
- [ADR-0046](0046-discover-feed-append-only.md) — append-only feed cache (unchanged by this merge)
- [ADR-0002](0002-persistence-drift.md) — persistence stays in the data layer
- [`docs/features/discover.md`](../features/discover.md)
