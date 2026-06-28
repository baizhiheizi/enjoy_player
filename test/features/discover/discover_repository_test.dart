import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:enjoy_player/features/discover/data/discover_repository.dart';
import 'package:enjoy_player/features/discover/data/youtube_fetch.dart';
import 'package:enjoy_player/features/discover/data/youtube_rss_parser.dart';
import 'package:enjoy_player/data/db/youtube_subscription_source.dart';
import 'package:enjoy_player/features/discover/domain/feed_entry.dart';
import 'package:enjoy_player/features/library/data/library_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _rss = '''
<feed xmlns:yt="http://www.youtube.com/xml/schemas/2015" xmlns:media="http://search.yahoo.com/mrss/" xmlns="http://www.w3.org/2005/Atom">
  <entry>
    <yt:videoId>videoA123456</yt:videoId>
    <title>Older</title>
    <published>2024-01-01T00:00:00+00:00</published>
  </entry>
  <entry>
    <yt:videoId>videoB123456</yt:videoId>
    <title>Newer</title>
    <published>2024-06-01T00:00:00+00:00</published>
  </entry>
</feed>
''';

void main() {
  group('DiscoverRepository', () {
    late AppDatabase db;
    late DiscoverRepository repo;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
      repo = DiscoverRepository(
        db,
        httpClient: MockClient((request) async {
          if (request.url.toString().contains('feeds/videos.xml')) {
            expect(request.headers['User-Agent'], YoutubeFetch.userAgent);
            return http.Response(_rss, 200);
          }
          return http.Response('', 404);
        }),
        rssParser: const YoutubeRssParser(),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('refresh upserts timeline ordered by published desc', () async {
      await repo.subscribeChannel(
        channelId: 'UCAuUUnT6oDeKwE6v1NGQxug',
        displayName: 'TED',
        source: YoutubeSubscriptionSource.recommended,
      );

      final result = await repo.refreshFeeds(force: true);
      expect(result.refreshedChannels, 1);

      final timeline = await repo.watchTimeline().first;
      expect(timeline, hasLength(2));
      expect(timeline.first.videoId, 'videoB123456');
      expect(timeline.last.videoId, 'videoA123456');
    });

    test(
      'subscribe preserves lastFetchedAt and subscribedAt on re-subscribe',
      () async {
        const channelId = 'UCAuUUnT6oDeKwE6v1NGQxug';
        final subscribedAt = DateTime.utc(2024, 1, 1);
        final fetchedAt = DateTime.utc(2024, 2, 1);
        await db.youtubeChannelSubscriptionDao.upsert(
          YoutubeChannelSubscriptionRow(
            channelId: channelId,
            displayName: 'TED',
            source: YoutubeSubscriptionSource.recommended,
            subscribedAt: subscribedAt,
            lastFetchedAt: fetchedAt,
          ),
        );

        await repo.subscribeChannel(
          channelId: channelId,
          displayName: 'TED Talks',
          source: YoutubeSubscriptionSource.user,
        );

        final row = await db.youtubeChannelSubscriptionDao.getByChannelId(
          channelId,
        );
        expect(row!.displayName, 'TED Talks');
        expect(row.subscribedAt.toUtc(), subscribedAt);
        expect(row.lastFetchedAt!.toUtc(), fetchedAt);
      },
    );

    test('refresh prunes feed entries missing from RSS', () async {
      const channelId = 'UCAuUUnT6oDeKwE6v1NGQxug';
      await repo.subscribeChannel(
        channelId: channelId,
        displayName: 'TED',
        source: YoutubeSubscriptionSource.recommended,
      );
      await db.youtubeFeedEntryDao.upsertEntry(
        YoutubeFeedEntryRow(
          videoId: 'staleVideo123456',
          channelId: channelId,
          title: 'Stale',
          publishedAt: DateTime.utc(2023, 1, 1),
          fetchedAt: DateTime.utc(2023, 1, 2),
        ),
      );

      await repo.refreshFeeds(force: true);

      final timeline = await repo.watchTimeline().first;
      expect(timeline.every((e) => e.videoId != 'staleVideo123456'), isTrue);
      expect(timeline, hasLength(2));
    });

    test('repairs legacy catalog channel ids before refresh', () async {
      const oldId = 'UCsooa4yRKGN_ee_M0Iv4CbQ';
      const newId = 'UCAuUUnT6oDeKwE6v1NGQxug';
      await repo.subscribeChannel(
        channelId: oldId,
        displayName: 'TED',
        source: YoutubeSubscriptionSource.recommended,
      );

      final result = await repo.refreshFeeds(force: true);
      expect(result.refreshedChannels, 1);
      expect(result.failedChannelIds, isEmpty);

      expect(
        await db.youtubeChannelSubscriptionDao.getByChannelId(oldId),
        isNull,
      );
      expect(
        await db.youtubeChannelSubscriptionDao.getByChannelId(newId),
        isNotNull,
      );
    });

    test('bot block HTML does not wipe cached entries', () async {
      const channelId = 'UCAuUUnT6oDeKwE6v1NGQxug';
      await repo.subscribeChannel(
        channelId: channelId,
        displayName: 'TED',
        source: YoutubeSubscriptionSource.recommended,
      );
      await db.youtubeFeedEntryDao.upsertEntry(
        YoutubeFeedEntryRow(
          videoId: 'cachedVideo12345',
          channelId: channelId,
          title: 'Cached',
          publishedAt: DateTime.utc(2024, 3, 1),
          fetchedAt: DateTime.utc(2024, 3, 2),
        ),
      );

      final failingRepo = DiscoverRepository(
        db,
        httpClient: MockClient((request) async {
          if (request.url.toString().contains('feeds/videos.xml')) {
            return http.Response(
              '<!DOCTYPE html><html>Sorry, unusual traffic</html>',
              200,
            );
          }
          return http.Response('', 404);
        }),
        rssParser: const YoutubeRssParser(),
      );

      final result = await failingRepo.refreshFeeds(force: true);
      expect(result.failedChannelIds, contains(channelId));

      final timeline = await repo.watchTimeline().first;
      expect(timeline.any((e) => e.videoId == 'cachedVideo12345'), isTrue);
    });

    test('addFeedEntryToLibrary uses RSS title without oEmbed', () async {
      const vid = 'dQw4w9WgXcQ';
      final library = MediaLibraryRepository(
        db,
        FileStorage(),
        oembedClient: MockClient((_) async => http.Response('', 500)),
      );
      repo = DiscoverRepository(
        db,
        httpClient: MockClient((_) async => http.Response('', 404)),
        rssParser: const YoutubeRssParser(),
        libraryRepository: library,
      );

      final id = await repo.addFeedEntryToLibrary(
        FeedEntry(
          videoId: vid,
          channelId: 'UCtestchannel1',
          title: 'Discover RSS Title',
          thumbnailUrl: 'https://i.ytimg.com/vi/$vid/hqdefault.jpg',
          publishedAt: DateTime.utc(2024, 6, 1),
        ),
      );

      final row = await db.videoDao.getById(id);
      expect(row!.title, 'Discover RSS Title');
      expect(row.thumbnailUrl, 'https://i.ytimg.com/vi/$vid/hqdefault.jpg');
    });
  });
}
