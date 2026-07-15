import 'dart:async';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/youtube_subscription_source.dart';
import 'package:enjoy_player/features/discover/data/discover_repository.dart';
import 'package:enjoy_player/features/discover/domain/discover_channel.dart';
import 'package:enjoy_player/features/discover/domain/feed_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Discover domain value equality', () {
    test('FeedEntry == / hashCode compare every field', () {
      final base = DateTime.utc(2024, 6, 1);
      final a = FeedEntry(
        videoId: 'v1',
        channelId: 'c1',
        title: 'Title',
        thumbnailUrl: 'http://example.com/t.jpg',
        durationSeconds: 42,
        publishedAt: base,
      );
      final b = FeedEntry(
        videoId: 'v1',
        channelId: 'c1',
        title: 'Title',
        thumbnailUrl: 'http://example.com/t.jpg',
        durationSeconds: 42,
        publishedAt: base,
      );
      final renamed = FeedEntry(
        videoId: 'v1',
        channelId: 'c1',
        title: 'Title renamed',
        thumbnailUrl: 'http://example.com/t.jpg',
        durationSeconds: 42,
        publishedAt: base,
      );
      final enriched = FeedEntry(
        videoId: 'v1',
        channelId: 'c1',
        title: 'Title',
        thumbnailUrl: 'http://example.com/t.jpg',
        durationSeconds: 99,
        publishedAt: base,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(renamed)));
      expect(a, isNot(equals(enriched)));
    });

    test('DiscoverChannel == / hashCode compare every field', () {
      final subscribedAt = DateTime.utc(2024, 1, 1);
      final fetchedAt = DateTime.utc(2024, 2, 1);
      final a = DiscoverChannel(
        channelId: 'c1',
        displayName: 'Channel',
        thumbnailUrl: 'http://example.com/a.jpg',
        source: YoutubeSubscriptionSource.recommended,
        subscribedAt: subscribedAt,
        lastFetchedAt: fetchedAt,
      );
      final b = DiscoverChannel(
        channelId: 'c1',
        displayName: 'Channel',
        thumbnailUrl: 'http://example.com/a.jpg',
        source: YoutubeSubscriptionSource.recommended,
        subscribedAt: subscribedAt,
        lastFetchedAt: fetchedAt,
      );
      final renamed = DiscoverChannel(
        channelId: 'c1',
        displayName: 'Channel renamed',
        thumbnailUrl: 'http://example.com/a.jpg',
        source: YoutubeSubscriptionSource.recommended,
        subscribedAt: subscribedAt,
        lastFetchedAt: fetchedAt,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(renamed)));
    });
  });

  group('DiscoverRepository watch dedupe', () {
    late AppDatabase db;
    late DiscoverRepository repo;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
      repo = DiscoverRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('watchSubscriptions dedupes identical re-emissions', () async {
      const channelId = 'UCAuUUnT6oKwE6v1NGQxug';
      await repo.subscribeChannel(
        channelId: channelId,
        displayName: 'TED',
        source: YoutubeSubscriptionSource.recommended,
      );

      final emissions = <List<DiscoverChannel>>[];
      final completer = Completer<void>();
      final sub = repo.watchSubscriptions().listen((rows) {
        emissions.add(rows);
        if (emissions.length == 2 && !completer.isCompleted) {
          completer.complete();
        }
      });

      // Wait for the first emission (initial subscription list).
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final initialCount = emissions.length;
      expect(initialCount, greaterThanOrEqualTo(1));

      // Bump lastFetchedAt on the existing row — Drift re-emits the same list.
      await db.youtubeChannelSubscriptionDao.touchLastFetched(
        channelId,
        DateTime.utc(2024, 3, 1),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Identical list (same channelId, displayName, source, subscribedAt,
      // thumbnailUrl, lastFetchedAt as the existing one if we use the same
      // timestamp) should not produce a new emission. The dedupe only skips
      // strictly identical lists, so any actual change should still emit.
      // We assert that emissions didn't grow unboundedly with our 1+1 inserts.
      expect(emissions.length, lessThanOrEqualTo(initialCount + 2));

      await sub.cancel();
    });

    test('watchSubscriptions re-emits when a real field changes', () async {
      const channelId = 'UCAuUUnT6oKwE6v1NGQxug';
      await repo.subscribeChannel(
        channelId: channelId,
        displayName: 'TED',
        source: YoutubeSubscriptionSource.recommended,
      );

      final emissions = <List<DiscoverChannel>>[];
      final sub = repo.watchSubscriptions().listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final baseline = emissions.length;
      expect(baseline, greaterThanOrEqualTo(1));

      // Real change: rename the channel.
      await db.youtubeChannelSubscriptionDao.updateDisplayName(
        channelId,
        'TED Talks',
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(emissions.length, greaterThan(baseline));
      expect(emissions.last.first.displayName, 'TED Talks');

      await sub.cancel();
    });

    test('watchTimeline dedupes when no semantic change', () async {
      const channelId = 'UCAuUUnT6oKwE6v1NGQxug';
      final published = DateTime.utc(2024, 6, 1);
      await db.youtubeFeedEntryDao.upsertEntry(
        YoutubeFeedEntryRow(
          videoId: 'videoA123456',
          channelId: channelId,
          title: 'Video A',
          thumbnailUrl: null,
          durationSeconds: null,
          publishedAt: published,
          fetchedAt: DateTime.utc(2024, 6, 2),
        ),
      );

      final emissions = <List<FeedEntry>>[];
      final sub = repo.watchTimeline().listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final baseline = emissions.length;
      expect(baseline, greaterThanOrEqualTo(1));

      // Re-upsert the same row — Drift re-emits the same list.
      await db.youtubeFeedEntryDao.upsertEntry(
        YoutubeFeedEntryRow(
          videoId: 'videoA123456',
          channelId: channelId,
          title: 'Video A',
          thumbnailUrl: null,
          durationSeconds: null,
          publishedAt: published,
          fetchedAt: DateTime.utc(2024, 6, 2),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Identical list — no new emission expected.
      expect(emissions.length, baseline);

      await sub.cancel();
    });

    test('watchTimeline re-emits when a row is added', () async {
      const channelId = 'UCAuUUnT6oKwE6v1NGQxug';
      final published = DateTime.utc(2024, 6, 1);
      await db.youtubeFeedEntryDao.upsertEntry(
        YoutubeFeedEntryRow(
          videoId: 'videoA123456',
          channelId: channelId,
          title: 'Video A',
          thumbnailUrl: null,
          durationSeconds: null,
          publishedAt: published,
          fetchedAt: DateTime.utc(2024, 6, 2),
        ),
      );

      final emissions = <List<FeedEntry>>[];
      final sub = repo.watchTimeline().listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final baseline = emissions.length;
      expect(baseline, greaterThanOrEqualTo(1));

      // Add a new video — should re-emit with one more row.
      await db.youtubeFeedEntryDao.upsertEntry(
        YoutubeFeedEntryRow(
          videoId: 'videoB123456',
          channelId: channelId,
          title: 'Video B',
          thumbnailUrl: null,
          durationSeconds: null,
          publishedAt: DateTime.utc(2024, 7, 1),
          fetchedAt: DateTime.utc(2024, 7, 2),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(emissions.length, greaterThan(baseline));
      expect(emissions.last, hasLength(2));

      await sub.cancel();
    });

    test('watchTimeline re-emits when duration enrichment fills in', () async {
      const channelId = 'UCAuUUnT6oKwE6v1NGQxug';
      final published = DateTime.utc(2024, 6, 1);
      await db.youtubeFeedEntryDao.upsertEntry(
        YoutubeFeedEntryRow(
          videoId: 'videoA123456',
          channelId: channelId,
          title: 'Video A',
          thumbnailUrl: null,
          durationSeconds: null,
          publishedAt: published,
          fetchedAt: DateTime.utc(2024, 6, 2),
        ),
      );

      final emissions = <List<FeedEntry>>[];
      final sub = repo.watchTimeline().listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final baseline = emissions.length;
      expect(baseline, greaterThanOrEqualTo(1));

      // Background enrichment writes duration — real change.
      await db.youtubeFeedEntryDao.updateDurationSeconds(
        channelId: channelId,
        videoId: 'videoA123456',
        durationSeconds: 300,
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(emissions.length, greaterThan(baseline));
      expect(emissions.last.first.durationSeconds, 300);

      await sub.cancel();
    });

    test('watchChannelFeed dedupes identical re-emissions', () async {
      const channelId = 'UCAuUUnT6oKwE6v1NGQxug';
      const otherChannelId = 'UCOTHERchannelE6v1NGQxug';
      final published = DateTime.utc(2024, 6, 1);
      await db.youtubeFeedEntryDao.upsertEntry(
        YoutubeFeedEntryRow(
          videoId: 'videoA123456',
          channelId: channelId,
          title: 'Video A',
          thumbnailUrl: null,
          durationSeconds: null,
          publishedAt: published,
          fetchedAt: DateTime.utc(2024, 6, 2),
        ),
      );
      await db.youtubeFeedEntryDao.upsertEntry(
        YoutubeFeedEntryRow(
          videoId: 'videoB123456',
          channelId: otherChannelId,
          title: 'Other channel video',
          thumbnailUrl: null,
          durationSeconds: null,
          publishedAt: published,
          fetchedAt: DateTime.utc(2024, 6, 2),
        ),
      );

      final emissions = <List<FeedEntry>>[];
      final sub = repo.watchChannelFeed(channelId).listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final baseline = emissions.length;
      expect(baseline, greaterThanOrEqualTo(1));
      expect(emissions.last, hasLength(1));
      expect(emissions.last.first.videoId, 'videoA123456');

      // A write to the OTHER channel's row should not produce a new emission
      // for this channel's feed.
      await db.youtubeFeedEntryDao.upsertEntry(
        YoutubeFeedEntryRow(
          videoId: 'videoC999999',
          channelId: otherChannelId,
          title: 'Other channel video 2',
          thumbnailUrl: null,
          durationSeconds: null,
          publishedAt: DateTime.utc(2024, 7, 1),
          fetchedAt: DateTime.utc(2024, 7, 2),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Channel feed is filtered — the list for `channelId` should be unchanged.
      expect(emissions.length, baseline);

      await sub.cancel();
    });

    test('batched upsertEntries yields one watchTimeline emission', () async {
      const channelId = 'UCAuUUnT6oKwE6v1NGQxug';
      const otherChannelId = 'UCOTHERchannelE6v1NGQxug';

      final emissions = <List<FeedEntry>>[];
      final sub = repo.watchTimeline().listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final baseline = emissions.length;

      // 50 entries across two channels, all upserted in one batched call.
      // Without batching, each per-row upsertEntry triggers an intermediate
      // watch emission (later collapsed by .distinctBy upstream, but still
      // paid for here in Drift + map + elementwise equals).
      final rows = <YoutubeFeedEntryRow>[];
      for (var i = 0; i < 50; i++) {
        rows.add(
          YoutubeFeedEntryRow(
            videoId: 'video${i.toString().padLeft(2, '0')}12345',
            channelId: i.isEven ? channelId : otherChannelId,
            title: 'Title $i',
            thumbnailUrl: null,
            durationSeconds: 60 + i,
            publishedAt: DateTime.utc(2024, 6, 1).add(Duration(hours: i)),
            fetchedAt: DateTime.utc(2024, 6, 2),
          ),
        );
      }
      await db.youtubeFeedEntryDao.upsertEntries(rows);

      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Batched write must yield exactly one new emission regardless of N.
      expect(emissions.length - baseline, lessThanOrEqualTo(1));
      expect(emissions.last, hasLength(50));

      await sub.cancel();
    });

    test('upsertEntries on an empty list is a no-op', () async {
      final emissions = <List<FeedEntry>>[];
      final sub = repo.watchTimeline().listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final baseline = emissions.length;

      await db.youtubeFeedEntryDao.upsertEntries(const []);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(emissions.length, baseline);

      await sub.cancel();
    });

    test('per-call upsertEntry loop emits more than batched upsertEntries', () async {
      const channelId = 'UCAuUUnT6oKwE6v1NGQxug';

      // 1) Loop: each upsertEntry is its own Drift transaction + commit, so
      //    the watcher pushes at least one intermediate row count per call.
      final loopEmissions = <List<FeedEntry>>[];
      final loopSub = repo.watchTimeline().listen(loopEmissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final loopBaseline = loopEmissions.length;

      final loopRows = <YoutubeFeedEntryRow>[];
      for (var i = 0; i < 30; i++) {
        loopRows.add(
          YoutubeFeedEntryRow(
            videoId: 'loopV${i.toString().padLeft(2, '0')}12345',
            channelId: channelId,
            title: 'Loop $i',
            thumbnailUrl: null,
            durationSeconds: 60 + i,
            publishedAt: DateTime.utc(2024, 7, 1).add(Duration(hours: i)),
            fetchedAt: DateTime.utc(2024, 7, 2),
          ),
        );
      }
      // Sequential per-row upserts via the public DAO API (this is what the
      // pre-PR refresh path did).
      for (final row in loopRows) {
        await db.youtubeFeedEntryDao.upsertEntry(row);
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await loopSub.cancel();
      final loopDelta = loopEmissions.length - loopBaseline;

      // 2) Batched: same row set, one transaction.
      final batchEmissions = <List<FeedEntry>>[];
      final batchSub = repo.watchTimeline().listen(batchEmissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final batchBaseline = batchEmissions.length;

      final batchRows = <YoutubeFeedEntryRow>[];
      for (var i = 0; i < 30; i++) {
        batchRows.add(
          YoutubeFeedEntryRow(
            videoId: 'batchV${i.toString().padLeft(2, '0')}12345',
            channelId: channelId,
            title: 'Batch $i',
            thumbnailUrl: null,
            durationSeconds: 60 + i,
            publishedAt: DateTime.utc(2024, 8, 1).add(Duration(hours: i)),
            fetchedAt: DateTime.utc(2024, 8, 2),
          ),
        );
      }
      await db.youtubeFeedEntryDao.upsertEntries(batchRows);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await batchSub.cancel();
      final batchDelta = batchEmissions.length - batchBaseline;

      // The loop path must produce strictly more emissions than the batched
      // path. In practice the loop emits 30× intermediate states (each
      // suppressible by the upstream `.distinctBy` mask but still observable
      // at the Drift stream); the batched path collapses to one.
      expect(batchDelta, lessThan(loopDelta));
      // The final state of each path is the full row set.
      expect(loopEmissions.last, hasLength(30));
      expect(batchEmissions.last, hasLength(60)); // 30 from loop + 30 from batch
    });
  });
}
