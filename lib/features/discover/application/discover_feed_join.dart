/// Feed ⨝ library join for the Discover feed (issue #764 candidate 6).
///
/// The feed used to answer "is this video in my library?" per tile, with a
/// widget-local `setState` cache and a manual `ref.invalidate` after every
/// add. That is UI-locality where repo-locality belongs: N indexed `SELECT`s
/// per scroll burst, and membership that only stayed correct because a widget
/// remembered to invalidate a provider.
///
/// Here the join is one stream, owned by the discover data module, and it sits
/// strictly *above* the append-only feed cache (ADR-0046) — no insert, prune,
/// or `deleteForChannel` path is touched.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/features/discover/domain/discover_channel.dart';
import 'package:enjoy_player/features/discover/domain/feed_entry.dart';

/// Display name used when an entry's channel is no longer subscribed.
const String kDiscoverFeedFallbackChannelName = 'YouTube';

/// One feed entry plus whether it is already in the library and the channel
/// display fields the meta row renders (issue #810 G) — resolved by the same
/// join as [inLibrary] so tiles never watch or scan the subscription list.
@immutable
class DiscoverFeedItem {
  const DiscoverFeedItem({
    required this.entry,
    required this.inLibrary,
    required this.channelName,
    required this.channelAvatarUrl,
  });

  final FeedEntry entry;
  final bool inLibrary;
  final String channelName;
  final String? channelAvatarUrl;

  @override
  bool operator ==(Object other) =>
      other is DiscoverFeedItem &&
      other.entry.videoId == entry.videoId &&
      other.inLibrary == inLibrary &&
      other.channelName == channelName &&
      other.channelAvatarUrl == channelAvatarUrl;

  @override
  int get hashCode =>
      Object.hash(entry.videoId, inLibrary, channelName, channelAvatarUrl);
}

/// Joins [sources] into a projection over their latest values, emitting only
/// once *every* stream has produced at least one value.
///
/// [combine] is re-run whenever any input emits, so a write on one side
/// updates the projection without the other sides re-emitting. The typed
/// arity wrappers ([joinLatest3]) keep call sites free of element casts.
Stream<R> joinLatestN<A, R>(
  List<Stream<A>> sources,
  R Function(List<A> values) combine,
) {
  return Stream<R>.multi((controller) {
    final latest = List<A?>.filled(sources.length, null);
    final received = List<bool>.filled(sources.length, false);
    var pending = sources.length;
    final subs = <StreamSubscription<A>>[];

    void push() {
      if (pending > 0) return;
      controller.add(combine(List<A>.from(latest)));
    }

    for (var i = 0; i < sources.length; i++) {
      subs.add(
        sources[i].listen(
          (value) {
            if (!received[i]) {
              received[i] = true;
              pending--;
            }
            latest[i] = value;
            push();
          },
          onError: controller.addError,
          onDone: controller.close,
        ),
      );
    }

    controller.onCancel = () {
      for (final sub in subs) {
        unawaited(sub.cancel());
      }
    };
  });
}

/// [joinLatestN] for three inputs: emits only once every stream has produced
/// at least one value, re-running [combine] whenever any input emits.
///
/// Waits for all first values on purpose: emitting a feed list against an
/// unknown membership set would paint every tile as "not in library" and then
/// flip them all on the library's first delivery — the exact flicker the
/// per-tile probe avoided by awaiting its own future.
Stream<R> joinLatest3<A, B, C, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  R Function(A a, B b, C c) combine,
) {
  return joinLatestN<Object?, R>([
    a,
    b,
    c,
  ], (values) => combine(values[0] as A, values[1] as B, values[2] as C));
}

/// Projects a feed entry list onto the library's YouTube vid set and the
/// subscribed channels' display fields.
List<DiscoverFeedItem> projectDiscoverFeedItems(
  List<FeedEntry> entries,
  Set<String> libraryVideoIds,
  List<DiscoverChannel> subscriptions,
) {
  final channelsById = <String, DiscoverChannel>{
    for (final sub in subscriptions) sub.channelId: sub,
  };
  return [
    for (final entry in entries)
      DiscoverFeedItem(
        entry: entry,
        inLibrary: libraryVideoIds.contains(entry.videoId),
        channelName:
            channelsById[entry.channelId]?.displayName ??
            kDiscoverFeedFallbackChannelName,
        channelAvatarUrl: remoteThumbnailForCard(
          channelsById[entry.channelId]?.thumbnailUrl,
        ),
      ),
  ];
}
