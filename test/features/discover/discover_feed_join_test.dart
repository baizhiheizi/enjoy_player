import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/discover/application/discover_feed_join.dart';
import 'package:enjoy_player/features/discover/domain/discover_channel.dart';
import 'package:enjoy_player/data/db/youtube_subscription_source.dart';
import 'package:enjoy_player/features/discover/domain/feed_entry.dart';

FeedEntry entry(String videoId) => FeedEntry(
  videoId: videoId,
  channelId: 'channel-1',
  title: 'Video $videoId',
  publishedAt: DateTime.utc(2024, 1, 1),
);

DiscoverChannel channel(String channelId, String name, {String? avatarUrl}) =>
    DiscoverChannel(
      channelId: channelId,
      displayName: name,
      thumbnailUrl: avatarUrl,
      source: YoutubeSubscriptionSource.user,
      subscribedAt: DateTime.utc(2024, 1, 1),
    );

/// A broadcast source the test drives by hand, so emissions are ordered
/// deliberately instead of racing an async gap.
class _Source<T> {
  final StreamController<T> controller = StreamController<T>.broadcast();
  Stream<T> get stream => controller.stream;

  void emit(T value) => controller.add(value);
}

void main() {
  group('projectDiscoverFeedItems', () {
    test('marks entries whose vid is in the library', () {
      final items = projectDiscoverFeedItems(
        [entry('a'), entry('b'), entry('c')],
        {'b'},
        const <DiscoverChannel>[],
      );
      expect(items.map((i) => (i.entry.videoId, i.inLibrary)), [
        ('a', false),
        ('b', true),
        ('c', false),
      ]);
    });

    test('an empty library marks everything absent', () {
      final items = projectDiscoverFeedItems(
        [entry('a')],
        const <String>{},
        const <DiscoverChannel>[],
      );
      expect(items.single.inLibrary, isFalse);
    });

    test('an unrelated vid does not mark an entry', () {
      final items = projectDiscoverFeedItems(
        [entry('a')],
        {'other'},
        const <DiscoverChannel>[],
      );
      expect(items.single.inLibrary, isFalse);
    });

    test('membership is per video, not positional', () {
      final items = projectDiscoverFeedItems(
        [entry('a'), entry('b')],
        {'b'},
        const <DiscoverChannel>[],
      );
      expect(items.first.inLibrary, isFalse);
      expect(items.last.inLibrary, isTrue);
    });

    test('joins the subscribed channel name and avatar (issue #810 G)', () {
      final items = projectDiscoverFeedItems(
        [entry('a')],
        const <String>{},
        [
          channel('channel-1', 'TED', avatarUrl: 'https://example.com/a.jpg'),
          channel('other', 'Other Channel'),
        ],
      );
      expect(items.single.channelName, 'TED');
      expect(items.single.channelAvatarUrl, isNotNull);
    });

    test('unsubscribed channel falls back without avatar', () {
      final items = projectDiscoverFeedItems(
        [entry('a')],
        const <String>{},
        [channel('other', 'Other Channel')],
      );
      expect(items.single.channelName, kDiscoverFeedFallbackChannelName);
      expect(items.single.channelAvatarUrl, isNull);
    });

    test('channel display fields participate in equality', () {
      const base = <String>{'a'};
      final subsA = [channel('channel-1', 'TED')];
      final subsB = [channel('channel-1', 'TED Talks')];
      final a = projectDiscoverFeedItems([entry('a')], base, subsA);
      final b = projectDiscoverFeedItems([entry('a')], base, subsB);
      final c = projectDiscoverFeedItems([entry('a')], base, subsA);
      expect(a, isNot(equals(b)));
      expect(a, equals(c));
    });
  });

  group('joinLatest3', () {
    late _Source<List<FeedEntry>> feed;
    late _Source<Set<String>> library;
    late _Source<List<DiscoverChannel>> subs;
    late List<List<DiscoverFeedItem>> emissions;
    late StreamSubscription<List<DiscoverFeedItem>> sub;

    setUp(() {
      feed = _Source<List<FeedEntry>>();
      library = _Source<Set<String>>();
      subs = _Source<List<DiscoverChannel>>();
      emissions = [];
      sub = joinLatest3(
        feed.stream,
        library.stream,
        subs.stream,
        projectDiscoverFeedItems,
      ).listen(emissions.add);
    });

    tearDown(() async {
      await sub.cancel();
      await feed.controller.close();
      await library.controller.close();
      await subs.controller.close();
    });

    test('waits for all three sides before emitting', () async {
      feed.emit([entry('a')]);
      library.emit({'a'});
      await pumpEventQueue();
      expect(emissions, isEmpty, reason: 'feed + library cannot answer yet');

      subs.emit([channel('channel-1', 'TED')]);
      await pumpEventQueue();
      expect(emissions, hasLength(1));
      expect(emissions.single.single.inLibrary, isTrue);
      expect(emissions.single.single.channelName, 'TED');
    });

    test('a subscription rename re-emits without a feed write', () async {
      feed.emit([entry('a')]);
      library.emit(const <String>{});
      subs.emit([channel('channel-1', 'TED')]);
      await pumpEventQueue();
      expect(emissions.single.single.channelName, 'TED');

      subs.emit([channel('channel-1', 'TED Talks')]);
      await pumpEventQueue();
      expect(emissions, hasLength(2));
      expect(emissions.last.single.channelName, 'TED Talks');
    });

    test(
      'a library write updates membership without a feed emission',
      () async {
        feed.emit([entry('a'), entry('b')]);
        library.emit(const <String>{});
        subs.emit(const <DiscoverChannel>[]);
        await pumpEventQueue();
        expect(emissions.single.map((i) => i.inLibrary), [false, false]);

        library.emit({'b'});
        await pumpEventQueue();
        expect(emissions, hasLength(2));
        expect(emissions.last.map((i) => (i.entry.videoId, i.inLibrary)), [
          ('a', false),
          ('b', true),
        ]);
      },
    );

    test('a feed write lands against current membership', () async {
      library.emit({'x'});
      subs.emit(const <DiscoverChannel>[]);
      feed.emit([entry('x'), entry('y')]);
      await pumpEventQueue();
      expect(emissions.single.map((i) => i.inLibrary), [true, false]);
    });

    test('un-importing a video flips the flag back', () async {
      feed.emit([entry('a')]);
      library.emit({'a'});
      subs.emit(const <DiscoverChannel>[]);
      await pumpEventQueue();
      expect(emissions.single.single.inLibrary, isTrue);

      library.emit(const <String>{});
      await pumpEventQueue();
      expect(emissions.last.single.inLibrary, isFalse);
    });

    test('cancelling the join stops both source subscriptions', () async {
      var feedEvents = 0;
      var libraryEvents = 0;
      final probeA = feed.stream.listen((_) => feedEvents++);
      final probeB = library.stream.listen((_) => libraryEvents++);
      addTearDown(probeA.cancel);
      addTearDown(probeB.cancel);

      feed.emit([entry('a')]);
      library.emit({'a'});
      subs.emit(const <DiscoverChannel>[]);
      await pumpEventQueue();
      expect(feedEvents, 1);
      expect(libraryEvents, 1);

      await sub.cancel();
      feed.emit([entry('b')]);
      library.emit({'b'});
      await pumpEventQueue();
      expect(feedEvents, 2, reason: 'the probe is still listening');
      expect(libraryEvents, 2);
    });
  });
}
