import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/discover/application/discover_feed_join.dart';
import 'package:enjoy_player/features/discover/domain/feed_entry.dart';

FeedEntry entry(String videoId) => FeedEntry(
  videoId: videoId,
  channelId: 'channel-1',
  title: 'Video $videoId',
  publishedAt: DateTime.utc(2024, 1, 1),
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
      );
      expect(items.map((i) => (i.entry.videoId, i.inLibrary)), [
        ('a', false),
        ('b', true),
        ('c', false),
      ]);
    });

    test('an empty library marks everything absent', () {
      final items = projectDiscoverFeedItems([entry('a')], const <String>{});
      expect(items.single.inLibrary, isFalse);
    });

    test('an unrelated vid does not mark an entry', () {
      final items = projectDiscoverFeedItems([entry('a')], {'other'});
      expect(items.single.inLibrary, isFalse);
    });

    test('membership is per video, not positional', () {
      final items = projectDiscoverFeedItems([entry('a'), entry('b')], {'b'});
      expect(items.first.inLibrary, isFalse);
      expect(items.last.inLibrary, isTrue);
    });
  });

  group('joinLatest', () {
    late _Source<List<FeedEntry>> feed;
    late _Source<Set<String>> library;
    late List<List<DiscoverFeedItem>> emissions;
    late StreamSubscription<List<DiscoverFeedItem>> sub;

    setUp(() {
      feed = _Source<List<FeedEntry>>();
      library = _Source<Set<String>>();
      emissions = [];
      sub = joinLatest(
        feed.stream,
        library.stream,
        projectDiscoverFeedItems,
      ).listen(emissions.add);
    });

    tearDown(() async {
      await sub.cancel();
      await feed.controller.close();
      await library.controller.close();
    });

    test('waits for both sides before emitting', () async {
      feed.emit([entry('a')]);
      await pumpEventQueue();
      expect(emissions, isEmpty, reason: 'feed alone cannot answer membership');

      library.emit({'a'});
      await pumpEventQueue();
      expect(emissions, hasLength(1));
      expect(emissions.single.single.inLibrary, isTrue);
    });

    test(
      'a library write updates membership without a feed emission',
      () async {
        feed.emit([entry('a'), entry('b')]);
        library.emit(const <String>{});
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
      feed.emit([entry('x'), entry('y')]);
      await pumpEventQueue();
      expect(emissions.single.map((i) => i.inLibrary), [true, false]);
    });

    test('un-importing a video flips the flag back', () async {
      feed.emit([entry('a')]);
      library.emit({'a'});
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
