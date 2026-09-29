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

/// Joins two streams into a projection over both, emitting only once *both*
/// sides have produced at least one value.
///
/// [combine] is re-run whenever either input emits, so a library write updates
/// the `inLibrary` flags without the feed stream re-emitting, and a feed write
/// lands with the current membership without waiting for the library stream.
///
/// Waits for both first values on purpose: emitting a feed list against an
/// unknown membership set would paint every tile as "not in library" and then
/// flip them all on the library's first delivery — the exact flicker the
/// per-tile probe avoided by awaiting its own future.
Stream<R> joinLatest<A, B, R>(
  Stream<A> a,
  Stream<B> b,
  R Function(A a, B b) combine,
) {
  return Stream<R>.multi((controller) {
    A? latestA;
    B? latestB;
    var hasA = false;
    var hasB = false;

    void push() {
      if (!hasA || !hasB) return;
      controller.add(combine(latestA as A, latestB as B));
    }

    final subA = a.listen(
      (value) {
        latestA = value;
        hasA = true;
        push();
      },
      onError: controller.addError,
      onDone: controller.close,
    );
    final subB = b.listen(
      (value) {
        latestB = value;
        hasB = true;
        push();
      },
      onError: controller.addError,
      onDone: controller.close,
    );

    controller.onCancel = () {
      unawaited(subA.cancel());
      unawaited(subB.cancel());
    };
  });
}

/// Same contract as [joinLatest] for three inputs: emits only once every
/// stream has produced at least one value, re-running [combine] whenever any
/// input emits.
Stream<R> joinLatest3<A, B, C, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  R Function(A a, B b, C c) combine,
) {
  return Stream<R>.multi((controller) {
    A? latestA;
    B? latestB;
    C? latestC;
    var hasA = false;
    var hasB = false;
    var hasC = false;

    void push() {
      if (!hasA || !hasB || !hasC) return;
      controller.add(combine(latestA as A, latestB as B, latestC as C));
    }

    final subA = a.listen(
      (value) {
        latestA = value;
        hasA = true;
        push();
      },
      onError: controller.addError,
      onDone: controller.close,
    );
    final subB = b.listen(
      (value) {
        latestB = value;
        hasB = true;
        push();
      },
      onError: controller.addError,
      onDone: controller.close,
    );
    final subC = c.listen(
      (value) {
        latestC = value;
        hasC = true;
        push();
      },
      onError: controller.addError,
      onDone: controller.close,
    );

    controller.onCancel = () {
      unawaited(subA.cancel());
      unawaited(subB.cancel());
      unawaited(subC.cancel());
    };
  });
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
