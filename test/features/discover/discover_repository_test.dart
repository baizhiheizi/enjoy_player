import 'dart:convert';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:enjoy_player/features/discover/data/discover_repository.dart';
import 'package:enjoy_player/features/discover/data/youtube_fetch.dart';
import 'package:enjoy_player/features/discover/data/youtube_rss_parser.dart';
import 'package:enjoy_player/data/db/youtube_subscription_source.dart';
import 'package:enjoy_player/features/discover/domain/feed_entry.dart';
import 'package:enjoy_player/features/discover/domain/recommended_channel.dart';
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

/// Build a minimal YouTube Atom RSS payload from a list of (videoId, publishedAt)
/// pairs. Used by the append-only cache tests (T004–T006).
String _rssFor(Iterable<({String videoId, DateTime publishedAt})> entries) {
  final inner = entries
      .map(
        (e) =>
            '''
  <entry>
    <yt:videoId>${e.videoId}</yt:videoId>
    <title>${e.videoId}</title>
    <published>${e.publishedAt.toUtc().toIso8601String()}</published>
  </entry>''',
      )
      .join();
  return '''
<feed xmlns:yt="http://www.youtube.com/xml/schemas/2015" xmlns:media="http://search.yahoo.com/mrss/" xmlns="http://www.w3.org/2005/Atom">$inner
</feed>
''';
}

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
            language: 'en',
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

    test(
      // Behavior flipped in spec 016-append-only-discover-feed (ADR-0046):
      // refresh is now append-only; a feed entry that fell out of the latest
      // RSS window stays in the cache.
      'refresh keeps cached entries that fell out of the RSS window',
      () async {
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
        expect(timeline.any((e) => e.videoId == 'staleVideo123456'), isTrue);
        expect(timeline, hasLength(3));
      },
    );

    test(
      'append-only: refresh against identical RSS payload is a no-op for cache size',
      () async {
        const channelId = 'UCapptest00000001';
        await repo.subscribeChannel(
          channelId: channelId,
          displayName: 'AppendOnly',
          source: YoutubeSubscriptionSource.recommended,
        );

        final entries = List.generate(10, (i) {
          return (
            videoId: 'v${i.toString().padLeft(11, '0')}',
            publishedAt: DateTime.utc(2024, 1, 1 + i),
          );
        });
        for (final e in entries) {
          await db.youtubeFeedEntryDao.upsertEntry(
            YoutubeFeedEntryRow(
              videoId: e.videoId,
              channelId: channelId,
              title: e.videoId,
              publishedAt: e.publishedAt,
              fetchedAt: DateTime.utc(2024, 1, 2),
            ),
          );
        }

        final localRepo = DiscoverRepository(
          db,
          httpClient: MockClient((request) async {
            if (request.url.toString().contains('feeds/videos.xml')) {
              return http.Response(_rssFor(entries), 200);
            }
            return http.Response('', 404);
          }),
          rssParser: const YoutubeRssParser(),
        );

        await localRepo.refreshFeeds(force: true);

        final timeline = await localRepo.watchTimeline().first;
        final ours = timeline.where((e) => e.channelId == channelId);
        expect(ours, hasLength(10));
      },
    );

    test('append-only: cache grows only by genuinely new entries', () async {
      const channelId = 'UCapptest00000002';
      await repo.subscribeChannel(
        channelId: channelId,
        displayName: 'AppendOnly',
        source: YoutubeSubscriptionSource.recommended,
      );

      final initial = List.generate(10, (i) {
        return (
          videoId: 'i${i.toString().padLeft(11, '0')}',
          publishedAt: DateTime.utc(2024, 2, 1 + i),
        );
      });
      for (final e in initial) {
        await db.youtubeFeedEntryDao.upsertEntry(
          YoutubeFeedEntryRow(
            videoId: e.videoId,
            channelId: channelId,
            title: e.videoId,
            publishedAt: e.publishedAt,
            fetchedAt: DateTime.utc(2024, 2, 2),
          ),
        );
      }

      final fresh = (
        videoId: 'n0000000000n',
        publishedAt: DateTime.utc(2024, 3, 1),
      );
      final another = (
        videoId: 'n0000000001n',
        publishedAt: DateTime.utc(2024, 3, 2),
      );
      final payload = [...initial, fresh, another];

      final localRepo = DiscoverRepository(
        db,
        httpClient: MockClient((request) async {
          if (request.url.toString().contains('feeds/videos.xml')) {
            return http.Response(_rssFor(payload), 200);
          }
          return http.Response('', 404);
        }),
        rssParser: const YoutubeRssParser(),
      );

      await localRepo.refreshFeeds(force: true);

      final timeline = await localRepo.watchTimeline().first;
      final ours = timeline.where((e) => e.channelId == channelId);
      expect(ours, hasLength(12));
      expect(ours.any((e) => e.videoId == fresh.videoId), isTrue);
      expect(ours.any((e) => e.videoId == another.videoId), isTrue);
      for (final e in initial) {
        expect(ours.any((x) => x.videoId == e.videoId), isTrue);
      }
    });

    test('append-only: RSS omitting entries does not delete them', () async {
      const channelId = 'UCapptest00000003';
      await repo.subscribeChannel(
        channelId: channelId,
        displayName: 'AppendOnly',
        source: YoutubeSubscriptionSource.recommended,
      );

      final all = List.generate(30, (i) {
        return (
          videoId: 'a${i.toString().padLeft(11, '0')}',
          publishedAt: DateTime.utc(2024, 1, 1 + i),
        );
      });
      for (final e in all) {
        await db.youtubeFeedEntryDao.upsertEntry(
          YoutubeFeedEntryRow(
            videoId: e.videoId,
            channelId: channelId,
            title: e.videoId,
            publishedAt: e.publishedAt,
            fetchedAt: DateTime.utc(2024, 1, 2),
          ),
        );
      }

      final newest15 = all.sublist(all.length - 15);

      final localRepo = DiscoverRepository(
        db,
        httpClient: MockClient((request) async {
          if (request.url.toString().contains('feeds/videos.xml')) {
            return http.Response(_rssFor(newest15), 200);
          }
          return http.Response('', 404);
        }),
        rssParser: const YoutubeRssParser(),
      );

      await localRepo.refreshFeeds(force: true);

      final timeline = await localRepo.watchTimeline().first;
      final ours = timeline.where((e) => e.channelId == channelId);
      expect(ours, hasLength(30));
    });

    test('unsubscribe deletes every cached entry for that channel', () async {
      const channelA = 'UCunsubAAAA000000001';
      const channelB = 'UCunsubBBBB000000002';
      await repo.subscribeChannel(
        channelId: channelA,
        displayName: 'Channel A',
        source: YoutubeSubscriptionSource.recommended,
      );
      await repo.subscribeChannel(
        channelId: channelB,
        displayName: 'Channel B',
        source: YoutubeSubscriptionSource.recommended,
      );

      for (var i = 0; i < 10; i++) {
        await db.youtubeFeedEntryDao.upsertEntry(
          YoutubeFeedEntryRow(
            videoId: 'a${i.toString().padLeft(11, '0')}',
            channelId: channelA,
            title: 'A $i',
            publishedAt: DateTime.utc(2024, 1, 1 + i),
            fetchedAt: DateTime.utc(2024, 1, 2),
          ),
        );
      }
      for (var i = 0; i < 5; i++) {
        await db.youtubeFeedEntryDao.upsertEntry(
          YoutubeFeedEntryRow(
            videoId: 'b${i.toString().padLeft(11, '0')}',
            channelId: channelB,
            title: 'B $i',
            publishedAt: DateTime.utc(2024, 1, 1 + i),
            fetchedAt: DateTime.utc(2024, 1, 2),
          ),
        );
      }

      await repo.unsubscribe(channelA);

      final aTimeline = await repo.watchChannelFeed(channelA).first;
      expect(aTimeline, isEmpty);
      final bTimeline = await repo.watchChannelFeed(channelB).first;
      expect(bTimeline, hasLength(5));
      expect(
        await db.youtubeChannelSubscriptionDao.getByChannelId(channelA),
        isNull,
      );
      expect(
        await db.youtubeChannelSubscriptionDao.getByChannelId(channelB),
        isNotNull,
      );
    });

    test('periodic refresh skips unsubscribed channels', () async {
      const channelA = 'UCunsubAAAA000000003';
      await repo.subscribeChannel(
        channelId: channelA,
        displayName: 'Channel A',
        source: YoutubeSubscriptionSource.recommended,
      );
      for (var i = 0; i < 3; i++) {
        await db.youtubeFeedEntryDao.upsertEntry(
          YoutubeFeedEntryRow(
            videoId: 'p${i.toString().padLeft(11, '0')}',
            channelId: channelA,
            title: 'Pre-existing',
            publishedAt: DateTime.utc(2024, 1, 1 + i),
            fetchedAt: DateTime.utc(2024, 1, 2),
          ),
        );
      }

      await repo.unsubscribe(channelA);

      var rssHitCount = 0;
      final localRepo = DiscoverRepository(
        db,
        httpClient: MockClient((request) async {
          if (request.url.toString().contains('feeds/videos.xml')) {
            rssHitCount += 1;
            return http.Response(_rss, 200);
          }
          return http.Response('', 404);
        }),
        rssParser: const YoutubeRssParser(),
      );

      final result = await localRepo.refreshFeeds(force: true);
      expect(rssHitCount, 0);
      expect(result.refreshedChannels, 0);
      expect(result.failedChannelIds, isEmpty);
      final timeline = await localRepo.watchTimeline().first;
      expect(timeline.where((e) => e.channelId == channelA), isEmpty);
    });

    test(
      'successful refresh updates lastFetchedAt and appends new entries',
      () async {
        const channelId = 'UCidemp000000000001';
        await repo.subscribeChannel(
          channelId: channelId,
          displayName: 'Idempotent',
          source: YoutubeSubscriptionSource.recommended,
        );

        final before = await db.youtubeChannelSubscriptionDao.getByChannelId(
          channelId,
        );
        expect(before?.lastFetchedAt, isNull);

        final newPayload = [
          (videoId: 'n0000000000n', publishedAt: DateTime.utc(2024, 4, 1)),
        ];
        final localRepo = DiscoverRepository(
          db,
          httpClient: MockClient((request) async {
            if (request.url.toString().contains('feeds/videos.xml')) {
              return http.Response(_rssFor(newPayload), 200);
            }
            return http.Response('', 404);
          }),
          rssParser: const YoutubeRssParser(),
        );

        await localRepo.refreshFeeds(force: true);

        final after = await db.youtubeChannelSubscriptionDao.getByChannelId(
          channelId,
        );
        expect(after?.lastFetchedAt, isNotNull);

        final timeline = await localRepo.watchTimeline().first;
        expect(timeline.any((e) => e.videoId == 'n0000000000n'), isTrue);
      },
    );

    test('failed refresh leaves cache and lastFetchedAt untouched', () async {
      const channelId = 'UCidemp000000000002';
      await repo.subscribeChannel(
        channelId: channelId,
        displayName: 'FailThenOk',
        source: YoutubeSubscriptionSource.recommended,
      );
      await db.youtubeFeedEntryDao.upsertEntry(
        YoutubeFeedEntryRow(
          videoId: 'keep00000000k',
          channelId: channelId,
          title: 'Keep me',
          publishedAt: DateTime.utc(2024, 1, 1),
          fetchedAt: DateTime.utc(2024, 1, 2),
        ),
      );

      final before = await db.youtubeChannelSubscriptionDao.getByChannelId(
        channelId,
      );
      expect(before?.lastFetchedAt, isNull);

      final failingRepo = DiscoverRepository(
        db,
        httpClient: MockClient((request) async {
          if (request.url.toString().contains('feeds/videos.xml')) {
            return http.Response('not an atom feed', 500);
          }
          return http.Response('', 404);
        }),
        rssParser: const YoutubeRssParser(),
      );

      final result = await failingRepo.refreshFeeds(force: true);
      expect(result.failedChannelIds, contains(channelId));
      expect(result.refreshedChannels, 0);

      final after = await db.youtubeChannelSubscriptionDao.getByChannelId(
        channelId,
      );
      expect(after?.lastFetchedAt, isNull);

      final timeline = await failingRepo.watchTimeline().first;
      expect(timeline.any((e) => e.videoId == 'keep00000000k'), isTrue);
    });

    test(
      '1-hour cooldown skips re-fetch when lastFetchedAt is fresh',
      () async {
        const channelId = 'UCidemp000000000003';
        final freshFetchedAt = DateTime.now().toUtc().subtract(
          const Duration(minutes: 30),
        );
        await db.youtubeChannelSubscriptionDao.upsert(
          YoutubeChannelSubscriptionRow(
            channelId: channelId,
            displayName: 'Cooldown',
            source: YoutubeSubscriptionSource.recommended,
            subscribedAt: DateTime.utc(2024, 1, 1),
            lastFetchedAt: freshFetchedAt,
            language: 'und',
          ),
        );
        await db.youtubeFeedEntryDao.upsertEntry(
          YoutubeFeedEntryRow(
            videoId: 'c0000000000c',
            channelId: channelId,
            title: 'Cached',
            publishedAt: DateTime.utc(2024, 1, 1),
            fetchedAt: freshFetchedAt,
          ),
        );

        var rssHitCount = 0;
        final localRepo = DiscoverRepository(
          db,
          httpClient: MockClient((request) async {
            if (request.url.toString().contains('feeds/videos.xml')) {
              rssHitCount += 1;
              return http.Response(_rss, 200);
            }
            return http.Response('', 404);
          }),
          rssParser: const YoutubeRssParser(),
        );

        final result = await localRepo.refreshFeeds(force: false);
        expect(rssHitCount, 0);
        expect(result.refreshedChannels, 0);

        final timeline = await localRepo.watchTimeline().first;
        expect(timeline.any((e) => e.videoId == 'c0000000000c'), isTrue);
      },
    );

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

    test('subscribeRecommended persists channel language', () async {
      await repo.subscribeRecommended(
        const RecommendedChannel(
          channelId: 'UCja123456789',
          name: 'Japanese Channel',
          language: 'ja',
          tags: ['education'],
        ),
      );

      final row = await db.youtubeChannelSubscriptionDao.getByChannelId(
        'UCja123456789',
      );
      expect(row!.language, 'ja-JP');
    });

    test('addFeedEntryToLibrary defaults to subscription language', () async {
      const vid = 'dQw4w9WgXcQ';
      const channelId = 'UCko123456789';
      await db.youtubeChannelSubscriptionDao.upsert(
        YoutubeChannelSubscriptionRow(
          channelId: channelId,
          displayName: 'Korean Channel',
          source: YoutubeSubscriptionSource.user,
          subscribedAt: DateTime.utc(2024, 1, 1),
          language: 'ko',
        ),
      );

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
          channelId: channelId,
          title: 'Korean clip',
          publishedAt: DateTime.utc(2024, 6, 1),
        ),
      );

      final row = await db.videoDao.getById(id);
      expect(row!.language, 'ko-KR');
    });

    test('updateSubscriptionLanguage updates persisted language', () async {
      const channelId = 'UCfr123456789';
      await repo.subscribeChannel(
        channelId: channelId,
        displayName: 'French Channel',
        source: YoutubeSubscriptionSource.user,
        language: 'und',
      );

      await repo.updateSubscriptionLanguage(channelId, 'fr');
      final row = await db.youtubeChannelSubscriptionDao.getByChannelId(
        channelId,
      );
      expect(row!.language, 'fr-FR');
    });

    test('InnerTube primary success writes rows from browse response', () async {
      const channelId = 'UCbrowsesuccess01';
      await repo.subscribeChannel(
        channelId: channelId,
        displayName: 'BrowseSuccess',
        source: YoutubeSubscriptionSource.recommended,
      );

      final localRepo = DiscoverRepository(
        db,
        httpClient: MockClient((req) async {
          if (req.method == 'POST' &&
              req.url.host == 'youtubei.googleapis.com') {
            final body = jsonDecode(req.body) as Map<String, dynamic>;
            final clientName =
                (body['context'] as Map<String, dynamic>)['client']
                    as Map<String, dynamic>;
            // only WEB is configured for this test
            expect(clientName['clientName'], 'WEB');
            return http.Response(
              jsonEncode({
                'contents': {
                  'twoColumnBrowseResultsRenderer': {
                    'tabs': [
                      {
                        'tabRenderer': {
                          'content': {
                            'richGridRenderer': {
                              'contents': [
                                {
                                  'richItemRenderer': {
                                    'content': {
                                      'videoRenderer': {
                                        'videoId': 'browseVid0000001',
                                        'title': {
                                          'runs': [
                                            {'text': 'Browse Video One'},
                                          ],
                                        },
                                        'thumbnail': {
                                          'thumbnails': [
                                            {
                                              'url':
                                                  'https://i.ytimg.com/vi/browseVid0000001/hqdefault.jpg',
                                            },
                                          ],
                                        },
                                        'lengthText': {'simpleText': '12:34'},
                                        'publishedTimeText': {
                                          'simpleText': '3 days ago',
                                        },
                                        'viewCountText': {
                                          'simpleText': '1.2K views',
                                        },
                                      },
                                    },
                                  },
                                },
                              ],
                            },
                          },
                        },
                      },
                    ],
                  },
                },
              }),
              200,
            );
          }
          return http.Response('', 404);
        }),
        rssParser: const YoutubeRssParser(),
      );

      final result = await localRepo.refreshFeeds(force: true);
      expect(result.refreshedChannels, 1);
      expect(result.failedChannelIds, isEmpty);

      final timeline = await localRepo.watchTimeline().first;
      final ours = timeline.where((e) => e.channelId == channelId);
      expect(ours, hasLength(1));
      final entry = ours.single;
      expect(entry.videoId, 'browseVid0000001');
      expect(entry.title, 'Browse Video One');
      expect(
        entry.thumbnailUrl,
        'https://i.ytimg.com/vi/browseVid0000001/hqdefault.jpg',
      );
      expect(entry.durationSeconds, 754);
    });

    test('InnerTube failure falls back to RSS', () async {
      const channelId = 'UCbrowsefallsback01';
      await repo.subscribeChannel(
        channelId: channelId,
        displayName: 'BrowseFallsBack',
        source: YoutubeSubscriptionSource.recommended,
      );

      var rssHits = 0;
      final localRepo = DiscoverRepository(
        db,
        httpClient: MockClient((req) async {
          if (req.method == 'POST' &&
              req.url.host == 'youtubei.googleapis.com') {
            return http.Response('', 401);
          }
          if (req.url.toString().contains('feeds/videos.xml')) {
            rssHits += 1;
            return http.Response(_rss, 200);
          }
          return http.Response('', 404);
        }),
        rssParser: const YoutubeRssParser(),
      );

      final result = await localRepo.refreshFeeds(force: true);
      expect(result.refreshedChannels, 1);
      expect(result.failedChannelIds, isEmpty);
      expect(rssHits, 1);

      final timeline = await localRepo.watchTimeline().first;
      final ours = timeline.where((e) => e.channelId == channelId);
      expect(ours, hasLength(2));
      expect(
        ours.map((e) => e.videoId),
        containsAll(['videoA123456', 'videoB123456']),
      );
    });

    test('dual failure preserves cache and lastFetchedAt', () async {
      const channelId = 'UCdualfailure001';
      final previousFetchedAt = DateTime.utc(2024, 1, 1);
      await db.youtubeChannelSubscriptionDao.upsert(
        YoutubeChannelSubscriptionRow(
          channelId: channelId,
          displayName: 'DualFail',
          source: YoutubeSubscriptionSource.recommended,
          subscribedAt: DateTime.utc(2023, 1, 1),
          lastFetchedAt: previousFetchedAt,
          language: 'und',
        ),
      );
      await db.youtubeFeedEntryDao.upsertEntry(
        YoutubeFeedEntryRow(
          videoId: 'preserve0000001',
          channelId: channelId,
          title: 'Preserve Me',
          publishedAt: DateTime.utc(2024, 1, 1),
          fetchedAt: previousFetchedAt,
        ),
      );

      final localRepo = DiscoverRepository(
        db,
        httpClient: MockClient((req) async {
          if (req.method == 'POST' &&
              req.url.host == 'youtubei.googleapis.com') {
            return http.Response('', 401);
          }
          if (req.url.toString().contains('feeds/videos.xml')) {
            return http.Response(
              '<!DOCTYPE html><html>Sorry, unusual traffic</html>',
              200,
            );
          }
          return http.Response('', 404);
        }),
        rssParser: const YoutubeRssParser(),
      );

      final result = await localRepo.refreshFeeds(force: true);
      expect(result.failedChannelIds, contains(channelId));
      expect(result.refreshedChannels, 0);

      final sub = await db.youtubeChannelSubscriptionDao.getByChannelId(
        channelId,
      );
      expect(sub!.lastFetchedAt!.toUtc(), previousFetchedAt);

      final timeline = await localRepo.watchTimeline().first;
      final ours = timeline.where((e) => e.channelId == channelId);
      expect(ours, hasLength(1));
      expect(ours.single.videoId, 'preserve0000001');
    });

    test('YoutubeBrowseException caught in _refreshChannelGuarded', () async {
      const channelId = 'UCguardcatches001';
      await repo.subscribeChannel(
        channelId: channelId,
        displayName: 'GuardCatches',
        source: YoutubeSubscriptionSource.recommended,
      );

      final localRepo = DiscoverRepository(
        db,
        httpClient: MockClient((req) async {
          if (req.method == 'POST' &&
              req.url.host == 'youtubei.googleapis.com') {
            return http.Response('', 500);
          }
          return http.Response('', 500);
        }),
        rssParser: const YoutubeRssParser(),
      );

      final result = await localRepo.refreshFeeds(force: true);
      expect(result.failedChannelIds, contains(channelId));
      expect(result.refreshedChannels, 0);

      final sub = await db.youtubeChannelSubscriptionDao.getByChannelId(
        channelId,
      );
      expect(sub!.lastFetchedAt, isNull);
    });

    test('InnerTube-supplied duration persists on row', () async {
      const channelId = 'UCduration000000001';
      await repo.subscribeChannel(
        channelId: channelId,
        displayName: 'DurationPersist',
        source: YoutubeSubscriptionSource.recommended,
      );

      var watchPageHits = 0;
      final localRepo = DiscoverRepository(
        db,
        httpClient: MockClient((req) async {
          if (req.method == 'POST' &&
              req.url.host == 'youtubei.googleapis.com') {
            final entries = List.generate(
              30,
              (i) => {
                'richItemRenderer': {
                  'content': {
                    'videoRenderer': {
                      'videoId': 'd${i.toString().padLeft(10, '0')}',
                      'title': {
                        'runs': [
                          {'text': 'D $i'},
                        ],
                      },
                      'lengthText': {'simpleText': '1:23'},
                      'publishedTimeText': {'simpleText': '$i hours ago'},
                    },
                  },
                },
              },
            );
            return http.Response(
              jsonEncode({
                'contents': {
                  'twoColumnBrowseResultsRenderer': {
                    'tabs': [
                      {
                        'tabRenderer': {
                          'content': {
                            'richGridRenderer': {'contents': entries},
                          },
                        },
                      },
                    ],
                  },
                },
              }),
              200,
            );
          }
          if (req.url.toString().contains('youtube.com/watch')) {
            watchPageHits += 1;
            return http.Response('', 500);
          }
          return http.Response('', 404);
        }),
        rssParser: const YoutubeRssParser(),
      );

      final result = await localRepo.refreshFeeds(force: true);
      expect(result.failedChannelIds, isEmpty);
      expect(result.refreshedChannels, 1);

      final timeline = await localRepo.watchTimeline().first;
      final ours = timeline.where((e) => e.channelId == channelId);
      expect(ours, hasLength(30));
      expect(ours.every((e) => e.durationSeconds == 83), isTrue);
      expect(watchPageHits, 0);
    });

    test(
      'InnerTube partial-shape writes null duration and skips enrichment',
      () async {
        const channelId = 'UCpartialshape0001';
        await repo.subscribeChannel(
          channelId: channelId,
          displayName: 'PartialShape',
          source: YoutubeSubscriptionSource.recommended,
        );

        var watchPageHits = 0;
        final localRepo = DiscoverRepository(
          db,
          httpClient: MockClient((req) async {
            if (req.method == 'POST' &&
                req.url.host == 'youtubei.googleapis.com') {
              // No lengthText, no viewCountText, no thumbnail.
              final entries = List.generate(
                30,
                (i) => {
                  'richItemRenderer': {
                    'content': {
                      'videoRenderer': {
                        'videoId': 'p${i.toString().padLeft(10, '0')}',
                        'title': {
                          'runs': [
                            {'text': 'P $i'},
                          ],
                        },
                        'publishedTimeText': {'simpleText': '$i hours ago'},
                      },
                    },
                  },
                },
              );
              return http.Response(
                jsonEncode({
                  'contents': {
                    'twoColumnBrowseResultsRenderer': {
                      'tabs': [
                        {
                          'tabRenderer': {
                            'content': {
                              'richGridRenderer': {'contents': entries},
                            },
                          },
                        },
                      ],
                    },
                  },
                }),
                200,
              );
            }
            if (req.url.toString().contains('youtube.com/watch')) {
              watchPageHits += 1;
              return http.Response('', 500);
            }
            return http.Response('', 404);
          }),
          rssParser: const YoutubeRssParser(),
        );

        final result = await localRepo.refreshFeeds(force: true);
        expect(result.failedChannelIds, isEmpty);

        final timeline = await localRepo.watchTimeline().first;
        final ours = timeline.where((e) => e.channelId == channelId);
        expect(ours, hasLength(30));
        expect(ours.every((e) => e.durationSeconds == null), isTrue);
        expect(watchPageHits, 0);
      },
    );

    test('RSS fallback path still invokes duration enrichment', () async {
      const channelId = 'UCrssfallback001';
      await repo.subscribeChannel(
        channelId: channelId,
        displayName: 'RssFallbackEnrich',
        source: YoutubeSubscriptionSource.recommended,
      );

      var watchPageHits = 0;
      final localRepo = DiscoverRepository(
        db,
        httpClient: MockClient((req) async {
          if (req.method == 'POST' &&
              req.url.host == 'youtubei.googleapis.com') {
            return http.Response('', 401);
          }
          if (req.url.toString().contains('feeds/videos.xml')) {
            return http.Response(
              _rssFor([
                (
                  videoId: 'videoR12345678',
                  publishedAt: DateTime.utc(2024, 1, 1),
                ),
                (
                  videoId: 'videoR23456789',
                  publishedAt: DateTime.utc(2024, 1, 2),
                ),
                (
                  videoId: 'videoR34567890',
                  publishedAt: DateTime.utc(2024, 1, 3),
                ),
                (
                  videoId: 'videoR45678901',
                  publishedAt: DateTime.utc(2024, 1, 4),
                ),
                (
                  videoId: 'videoR56789012',
                  publishedAt: DateTime.utc(2024, 1, 5),
                ),
              ]),
              200,
            );
          }
          if (req.url.toString().contains('youtube.com/watch')) {
            watchPageHits += 1;
            return http.Response('', 500);
          }
          return http.Response('', 404);
        }),
        rssParser: const YoutubeRssParser(),
      );

      final result = await localRepo.refreshFeeds(force: true);
      expect(result.failedChannelIds, isEmpty);
      expect(result.refreshedChannels, 1);

      final timeline = await localRepo.watchTimeline().first;
      final ours = timeline.where((e) => e.channelId == channelId);
      expect(ours, hasLength(5));

      // Allow the unawaited _enrichMissingDurations to complete.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(watchPageHits, 5);
    });

    test('1-hour cooldown skips re-fetch on InnerTube primary path', () async {
      const channelId = 'UCcooldownbrowse01';
      final freshFetchedAt = DateTime.now().toUtc().subtract(
        const Duration(minutes: 30),
      );
      await db.youtubeChannelSubscriptionDao.upsert(
        YoutubeChannelSubscriptionRow(
          channelId: channelId,
          displayName: 'CooldownBrowse',
          source: YoutubeSubscriptionSource.recommended,
          subscribedAt: DateTime.utc(2024, 1, 1),
          lastFetchedAt: freshFetchedAt,
          language: 'und',
        ),
      );

      var browseHits = 0;
      var rssHits = 0;
      final localRepo = DiscoverRepository(
        db,
        httpClient: MockClient((req) async {
          if (req.method == 'POST' &&
              req.url.host == 'youtubei.googleapis.com') {
            browseHits += 1;
            return http.Response('', 200);
          }
          if (req.url.toString().contains('feeds/videos.xml')) {
            rssHits += 1;
            return http.Response(_rss, 200);
          }
          return http.Response('', 404);
        }),
        rssParser: const YoutubeRssParser(),
      );

      final result = await localRepo.refreshFeeds(force: false);
      expect(result.refreshedChannels, 0);
      expect(result.failedChannelIds, isEmpty);
      expect(browseHits, 0);
      expect(rssHits, 0);
    });

    test('profile rotation: WEB 401 -> MWEB 401 -> RSS fallback', () async {
      const channelId = 'UCprofilerotate01';
      await repo.subscribeChannel(
        channelId: channelId,
        displayName: 'ProfileRotate',
        source: YoutubeSubscriptionSource.recommended,
      );

      final calls = <String>[];
      final localRepo = DiscoverRepository(
        db,
        httpClient: MockClient((req) async {
          if (req.method == 'POST' &&
              req.url.host == 'youtubei.googleapis.com') {
            final body = jsonDecode(req.body) as Map<String, dynamic>;
            final clientName =
                ((body['context'] as Map<String, dynamic>)['client']
                        as Map<String, dynamic>)['clientName']
                    as String;
            calls.add(clientName);
            return http.Response('', 401);
          }
          if (req.url.toString().contains('feeds/videos.xml')) {
            return http.Response(_rss, 200);
          }
          return http.Response('', 404);
        }),
        rssParser: const YoutubeRssParser(),
      );

      final result = await localRepo.refreshFeeds(force: true);
      expect(result.refreshedChannels, 1);
      expect(result.failedChannelIds, isEmpty);
      expect(calls, ['WEB', 'MWEB']);

      final timeline = await localRepo.watchTimeline().first;
      final ours = timeline.where((e) => e.channelId == channelId);
      expect(ours, hasLength(2));
    });

    test(
      'profile rotation: WEB 401 -> MWEB success (no RSS fallback)',
      () async {
        const channelId = 'UCprofileMWEBok01';
        await repo.subscribeChannel(
          channelId: channelId,
          displayName: 'ProfileMWEBok',
          source: YoutubeSubscriptionSource.recommended,
        );

        final calls = <String>[];
        var rssHits = 0;
        final localRepo = DiscoverRepository(
          db,
          httpClient: MockClient((req) async {
            if (req.method == 'POST' &&
                req.url.host == 'youtubei.googleapis.com') {
              final body = jsonDecode(req.body) as Map<String, dynamic>;
              final clientName =
                  ((body['context'] as Map<String, dynamic>)['client']
                          as Map<String, dynamic>)['clientName']
                      as String;
              calls.add(clientName);
              if (clientName == 'WEB') {
                return http.Response('', 401);
              }
              // MWEB returns a valid 1-entry response.
              return http.Response(
                jsonEncode({
                  'contents': {
                    'twoColumnBrowseResultsRenderer': {
                      'tabs': [
                        {
                          'tabRenderer': {
                            'content': {
                              'richGridRenderer': {
                                'contents': [
                                  {
                                    'richItemRenderer': {
                                      'content': {
                                        'videoRenderer': {
                                          'videoId': 'mwebWins000001',
                                          'title': {
                                            'runs': [
                                              {'text': 'MWEB Video'},
                                            ],
                                          },
                                          'publishedTimeText': {
                                            'simpleText': '1 hour ago',
                                          },
                                        },
                                      },
                                    },
                                  },
                                ],
                              },
                            },
                          },
                        },
                      ],
                    },
                  },
                }),
                200,
              );
            }
            if (req.url.toString().contains('feeds/videos.xml')) {
              rssHits += 1;
              return http.Response(_rss, 200);
            }
            return http.Response('', 404);
          }),
          rssParser: const YoutubeRssParser(),
        );

        final result = await localRepo.refreshFeeds(force: true);
        expect(result.refreshedChannels, 1);
        expect(result.failedChannelIds, isEmpty);
        expect(calls, ['WEB', 'MWEB']);
        expect(rssHits, 0);

        final timeline = await localRepo.watchTimeline().first;
        final ours = timeline.where((e) => e.channelId == channelId);
        expect(ours, hasLength(1));
        expect(ours.single.videoId, 'mwebWins000001');
      },
    );

    test(
      'append-only cache preserved when InnerTube returns a subset',
      () async {
        const channelId = 'UCinnerpartial01';
        await repo.subscribeChannel(
          channelId: channelId,
          displayName: 'InnerPartial',
          source: YoutubeSubscriptionSource.recommended,
        );

        final all = List.generate(50, (i) {
          return (
            videoId: 's${i.toString().padLeft(10, '0')}',
            publishedAt: DateTime.utc(2024, 1, 1 + i),
          );
        });
        final beforeFetchedAt = DateTime.utc(2024, 1, 1);
        for (final e in all) {
          await db.youtubeFeedEntryDao.upsertEntry(
            YoutubeFeedEntryRow(
              videoId: e.videoId,
              channelId: channelId,
              title: e.videoId,
              publishedAt: e.publishedAt,
              fetchedAt: beforeFetchedAt,
            ),
          );
        }

        // InnerTube returns only the newest 30 (a strict subset).
        final newest30 = all.sublist(all.length - 30);

        final localRepo = DiscoverRepository(
          db,
          httpClient: MockClient((req) async {
            if (req.method == 'POST' &&
                req.url.host == 'youtubei.googleapis.com') {
              final entries = newest30
                  .map(
                    (e) => {
                      'richItemRenderer': {
                        'content': {
                          'videoRenderer': {
                            'videoId': e.videoId,
                            'title': {
                              'runs': [
                                {'text': e.videoId},
                              ],
                            },
                            'publishedTimeText': {'simpleText': 'recent'},
                          },
                        },
                      },
                    },
                  )
                  .toList();
              return http.Response(
                jsonEncode({
                  'contents': {
                    'twoColumnBrowseResultsRenderer': {
                      'tabs': [
                        {
                          'tabRenderer': {
                            'content': {
                              'richGridRenderer': {'contents': entries},
                            },
                          },
                        },
                      ],
                    },
                  },
                }),
                200,
              );
            }
            return http.Response('', 404);
          }),
          rssParser: const YoutubeRssParser(),
        );

        await localRepo.refreshFeeds(force: true);

        final timeline = await localRepo.watchTimeline().first;
        final ours = timeline.where((e) => e.channelId == channelId);
        expect(ours, hasLength(50));
        // The 20 unseen rows keep their original fetchedAt.
        final unseen = ours.where(
          (e) => !newest30.any((n) => n.videoId == e.videoId),
        );
        expect(unseen, hasLength(20));
        for (final u in unseen) {
          final row = await db.youtubeFeedEntryDao.getEntry(
            channelId: channelId,
            videoId: u.videoId,
          );
          expect(row!.fetchedAt.toUtc(), beforeFetchedAt);
        }
      },
    );

    group('fetchChannelAvatarUrl LRU cache', () {
      test(
        'first call hits resolver; subsequent calls return cached URL',
        () async {
          var resolverCalls = 0;
          final localRepo = DiscoverRepository(
            db,
            httpClient: MockClient((request) async {
              if (request.url.path.startsWith('/channel/')) {
                resolverCalls += 1;
                return http.Response(
                  '<html>"avatar":{"thumbnails":[{"url":"https://example.com/a.jpg"}]}</html>',
                  200,
                );
              }
              return http.Response('', 404);
            }),
          );

          const channelId = 'UCaaaaaaaaaaaaaaaaaaaaaa';
          final first = await localRepo.fetchChannelAvatarUrl(channelId);
          final second = await localRepo.fetchChannelAvatarUrl(channelId);
          final third = await localRepo.fetchChannelAvatarUrl(channelId);

          expect(first, 'https://example.com/a.jpg');
          expect(second, first);
          expect(third, first);
          expect(
            resolverCalls,
            1,
            reason: 'cache must short-circuit the resolver',
          );
        },
      );

      test('different channels are cached independently', () async {
        final visited = <String>[];
        final localRepo = DiscoverRepository(
          db,
          httpClient: MockClient((request) async {
            if (request.url.path.startsWith('/channel/')) {
              final id = request.url.pathSegments.last;
              visited.add(id);
              return http.Response(
                '<html>"avatar":{"thumbnails":[{"url":"https://example.com/$id.jpg"}]}</html>',
                200,
              );
            }
            return http.Response('', 404);
          }),
        );

        final a = await localRepo.fetchChannelAvatarUrl(
          'UCaaaaaaaaaaaaaaaaaaaaaa',
        );
        final b = await localRepo.fetchChannelAvatarUrl(
          'UCbbbbbbbbbbbbbbbbbbbbbb',
        );
        // Repeat — must come from cache.
        final aRepeat = await localRepo.fetchChannelAvatarUrl(
          'UCaaaaaaaaaaaaaaaaaaaaaa',
        );
        final bRepeat = await localRepo.fetchChannelAvatarUrl(
          'UCbbbbbbbbbbbbbbbbbbbbbb',
        );

        expect(a, 'https://example.com/UCaaaaaaaaaaaaaaaaaaaaaa.jpg');
        expect(b, 'https://example.com/UCbbbbbbbbbbbbbbbbbbbbbb.jpg');
        expect(aRepeat, a);
        expect(bRepeat, b);
        expect(visited, [
          'UCaaaaaaaaaaaaaaaaaaaaaa',
          'UCbbbbbbbbbbbbbbbbbbbbbb',
        ], reason: 'each channel resolves at most once');
      });

      test('failed fetch returns null and is not cached', () async {
        var resolverCalls = 0;
        final localRepo = DiscoverRepository(
          db,
          httpClient: MockClient((request) async {
            if (request.url.path.startsWith('/channel/')) {
              resolverCalls += 1;
              return http.Response('not found', 404);
            }
            return http.Response('', 404);
          }),
        );

        const channelId = 'UCcccccccccccccccccccccc';
        final first = await localRepo.fetchChannelAvatarUrl(channelId);
        // Second call must hit the resolver again — null is not cached.
        final second = await localRepo.fetchChannelAvatarUrl(channelId);

        expect(first, isNull);
        expect(second, isNull);
        expect(resolverCalls, 2);
      });
    });
  });
}
