import 'package:drift/native.dart';
import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/youtube_subscription_source.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:enjoy_player/features/discover/data/discover_repository.dart';
import 'package:enjoy_player/features/discover/domain/feed_entry.dart';
import 'package:enjoy_player/features/discover/domain/recommended_channel.dart';
import 'package:enjoy_player/features/library/data/library_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _channelId = 'UCAuUUnT6oDeKwE6v1NGQxug';
const _workerBase = 'https://worker.enjoy.bot';

String _jsonFeedBody({
  String title = 'Test Channel - YouTube',
  String homePageUrl = 'https://www.youtube.com/channel/$_channelId',
  String? icon = 'https://yt3.ggpht.com/avatar.jpg',
  List<Map<String, dynamic>> items = const [],
}) {
  final itemsJson = items
      .map((item) {
        final attachments = item['attachments'] as List<dynamic>?;
        final attachmentsStr = attachments != null
            ? '"attachments": ${_attachmentsJson(attachments)}'
            : '';
        final parts = <String>[
          '"id": "${item['id']}"',
          '"url": "https://www.youtube.com/watch?v=${item['id']}"',
          '"title": "${item['title'] ?? 'Untitled'}"',
          if (item['image'] != null) '"image": "${item['image']}"',
          if (item['date_published'] != null)
            '"date_published": "${item['date_published']}"',
          if (attachmentsStr.isNotEmpty) attachmentsStr,
        ];
        return '{${parts.join(',')}}';
      })
      .join(',');

  return '''
  {
    "version": "https://jsonfeed.org/version/1.1",
    "title": "$title",
    "home_page_url": "$homePageUrl",
    ${icon != null ? '"icon": "$icon",' : ''}
    "items": [$itemsJson]
  }
  ''';
}

String _attachmentsJson(List<dynamic> attachments) {
  final parts = attachments.map((a) {
    final map = a as Map<String, dynamic>;
    return '{"url": "${map['url']}", "mime_type": "${map['mime_type']}", "duration_in_seconds": ${map['duration_in_seconds']}}';
  });
  return '[${parts.join(',')}]';
}

class _FakeLibraryRepository extends MediaLibraryRepository {
  _FakeLibraryRepository(super.db, super.storage);

  final importedVideos = <String, String>{};

  @override
  Future<String> importYoutubeVideo(
    String rawInput, {
    String? prefetchedTitle,
    String? prefetchedThumbnailUrl,
    String contentLanguage = kUnknownMediaLanguageTag,
  }) async {
    importedVideos[rawInput] = contentLanguage;
    return 'imported-$rawInput';
  }
}

void main() {
  group('DiscoverRepository', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    group('getSubscription', () {
      test('returns null when channel is not subscribed', () async {
        final repo = DiscoverRepository(db);
        final result = await repo.getSubscription('UCnonexistent000000000');
        expect(result, isNull);
      });

      test('returns mapped DiscoverChannel when subscribed', () async {
        final repo = DiscoverRepository(db);
        await repo.subscribeChannel(
          channelId: _channelId,
          displayName: 'TED',
          source: YoutubeSubscriptionSource.recommended,
          thumbnailUrl: 'https://example.com/thumb.jpg',
          feedUrl: '$_workerBase/youtube/channel/$_channelId?format=json',
        );

        final result = await repo.getSubscription(_channelId);
        expect(result, isNotNull);
        expect(result!.channelId, _channelId);
        expect(result.displayName, 'TED');
        expect(result.thumbnailUrl, 'https://example.com/thumb.jpg');
        expect(result.source, YoutubeSubscriptionSource.recommended);
        expect(result.sourceType, YoutubeSourceType.channel);
        expect(
          result.feedUrl,
          '$_workerBase/youtube/channel/$_channelId?format=json',
        );
      });
    });

    group('subscribeChannel', () {
      test('creates new subscription with defaults', () async {
        final repo = DiscoverRepository(db);
        await repo.subscribeChannel(
          channelId: _channelId,
          displayName: 'TED',
          source: YoutubeSubscriptionSource.user,
        );

        final row = await db.youtubeChannelSubscriptionDao.getByChannelId(
          _channelId,
        );
        expect(row, isNotNull);
        expect(row!.displayName, 'TED');
        expect(row.source, YoutubeSubscriptionSource.user);
        expect(row.language, 'und');
        expect(row.lastFetchedAt, isNull);
        expect(row.thumbnailUrl, isNull);
        expect(row.feedUrl, isNull);
      });

      test('preserves existing metadata on re-subscribe', () async {
        final repo = DiscoverRepository(db);
        await repo.subscribeChannel(
          channelId: _channelId,
          displayName: 'TED',
          source: YoutubeSubscriptionSource.recommended,
          thumbnailUrl: 'https://example.com/old.jpg',
          feedUrl: '$_workerBase/youtube/channel/$_channelId?format=json',
        );

        final original = await db.youtubeChannelSubscriptionDao.getByChannelId(
          _channelId,
        );

        await repo.subscribeChannel(
          channelId: _channelId,
          displayName: 'TED Updated',
          source: YoutubeSubscriptionSource.user,
        );

        final updated = await db.youtubeChannelSubscriptionDao.getByChannelId(
          _channelId,
        );
        expect(updated!.displayName, 'TED Updated');
        expect(updated.source, YoutubeSubscriptionSource.user);
        expect(updated.subscribedAt, original!.subscribedAt);
        expect(updated.thumbnailUrl, 'https://example.com/old.jpg');
        expect(
          updated.feedUrl,
          '$_workerBase/youtube/channel/$_channelId?format=json',
        );
        expect(updated.language, original.language);
      });

      test('new thumbnailUrl overrides existing', () async {
        final repo = DiscoverRepository(db);
        await repo.subscribeChannel(
          channelId: _channelId,
          displayName: 'TED',
          source: YoutubeSubscriptionSource.recommended,
          thumbnailUrl: 'https://example.com/old.jpg',
        );

        await repo.subscribeChannel(
          channelId: _channelId,
          displayName: 'TED',
          source: YoutubeSubscriptionSource.recommended,
          thumbnailUrl: 'https://example.com/new.jpg',
        );

        final row = await db.youtubeChannelSubscriptionDao.getByChannelId(
          _channelId,
        );
        expect(row!.thumbnailUrl, 'https://example.com/new.jpg');
      });
    });

    group('subscribeRecommended', () {
      test(
        'persists subscription with recommended source and feed URL',
        () async {
          final repo = DiscoverRepository(db);
          const channel = RecommendedChannel(
            channelId: _channelId,
            name: 'TED',
            handle: '@TED',
            language: 'en',
          );

          await repo.subscribeRecommended(channel);

          final row = await db.youtubeChannelSubscriptionDao.getByChannelId(
            _channelId,
          );
          expect(row, isNotNull);
          expect(row!.displayName, 'TED');
          expect(row.source, YoutubeSubscriptionSource.recommended);
          expect(row.sourceType, YoutubeSourceType.channel);
          expect(
            row.feedUrl,
            '$_workerBase/youtube/channel/$_channelId?format=json',
          );
        },
      );
    });

    group('unsubscribe', () {
      test('removes subscription and feed entries', () async {
        final repo = DiscoverRepository(db);
        await repo.subscribeChannel(
          channelId: _channelId,
          displayName: 'TED',
          source: YoutubeSubscriptionSource.recommended,
        );
        await db.youtubeFeedEntryDao.upsertEntry(
          YoutubeFeedEntryRow(
            videoId: 'vid00000001',
            channelId: _channelId,
            title: 'Video 1',
            publishedAt: DateTime.utc(2024, 1, 1),
            fetchedAt: DateTime.utc(2024, 1, 2),
          ),
        );

        await repo.unsubscribe(_channelId);

        expect(
          await db.youtubeChannelSubscriptionDao.getByChannelId(_channelId),
          isNull,
        );
        expect(await db.youtubeFeedEntryDao.getForChannel(_channelId), isEmpty);
      });
    });

    group('isVideoInLibrary', () {
      test('returns false when video is not in library', () async {
        final repo = DiscoverRepository(db);
        expect(await repo.isVideoInLibrary('dQw4w9WgXcQ'), isFalse);
      });

      test('returns true when video exists in library', () async {
        final repo = DiscoverRepository(db);
        final now = DateTime.now();
        await db.videoDao.insertRow(
          VideoRow(
            id: 'yt-dQw4w9WgXcQ',
            vid: 'dQw4w9WgXcQ',
            provider: 'youtube',
            title: 'Test',
            durationSeconds: 0,
            mediaUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            language: 'und',
            createdAt: now,
            updatedAt: now,
          ),
        );

        expect(await repo.isVideoInLibrary('dQw4w9WgXcQ'), isTrue);
      });
    });

    group('fetchChannelAvatarUrl', () {
      test('returns null when channel not found', () async {
        final repo = DiscoverRepository(db);
        final url = await repo.fetchChannelAvatarUrl('UCnonexistent000000000');
        expect(url, isNull);
      });

      test('returns null when thumbnailUrl is null', () async {
        final repo = DiscoverRepository(db);
        await repo.subscribeChannel(
          channelId: _channelId,
          displayName: 'TED',
          source: YoutubeSubscriptionSource.recommended,
        );

        final url = await repo.fetchChannelAvatarUrl(_channelId);
        expect(url, isNull);
      });

      test(
        'returns empty string without caching when thumbnailUrl is empty',
        () async {
          final repo = DiscoverRepository(db);
          await db.youtubeChannelSubscriptionDao.upsert(
            YoutubeChannelSubscriptionRow(
              channelId: _channelId,
              displayName: 'TED',
              thumbnailUrl: '',
              source: YoutubeSubscriptionSource.recommended,
              sourceType: YoutubeSourceType.channel,
              subscribedAt: DateTime.now(),
              language: 'und',
            ),
          );

          final url = await repo.fetchChannelAvatarUrl(_channelId);
          expect(url, '');
        },
      );

      test('returns URL and caches it', () async {
        final repo = DiscoverRepository(db);
        await repo.subscribeChannel(
          channelId: _channelId,
          displayName: 'TED',
          source: YoutubeSubscriptionSource.recommended,
          thumbnailUrl: 'https://yt3.ggpht.com/avatar.jpg',
        );

        final url = await repo.fetchChannelAvatarUrl(_channelId);
        expect(url, 'https://yt3.ggpht.com/avatar.jpg');

        // Second call should hit cache (same result even if DB row changes)
        await db.youtubeChannelSubscriptionDao.updateThumbnail(
          _channelId,
          'https://yt3.ggpht.com/changed.jpg',
        );
        final cached = await repo.fetchChannelAvatarUrl(_channelId);
        expect(cached, 'https://yt3.ggpht.com/avatar.jpg');
      });
    });

    group('addFeedEntryToLibrary', () {
      test('throws StateError when library not bound', () async {
        final repo = DiscoverRepository(db);
        final entry = FeedEntry(
          videoId: 'dQw4w9WgXcQ',
          channelId: _channelId,
          title: 'Test Video',
          publishedAt: DateTime.utc(2024, 1, 1),
        );

        expect(
          () => repo.addFeedEntryToLibrary(entry),
          throwsA(isA<StateError>()),
        );
      });

      test('imports video with default language when none specified', () async {
        final fakeLib = _FakeLibraryRepository(db, FileStorage());
        final repo = DiscoverRepository(db);
        repo.bindLibraryRepository(fakeLib);

        final entry = FeedEntry(
          videoId: 'dQw4w9WgXcQ',
          channelId: _channelId,
          title: 'Test Video',
          thumbnailUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
          publishedAt: DateTime.utc(2024, 1, 1),
        );

        final result = await repo.addFeedEntryToLibrary(entry);
        expect(result, 'imported-dQw4w9WgXcQ');
        expect(fakeLib.importedVideos['dQw4w9WgXcQ'], kUnknownMediaLanguageTag);
      });

      test('passes explicit contentLanguage to library', () async {
        final fakeLib = _FakeLibraryRepository(db, FileStorage());
        final repo = DiscoverRepository(db);
        repo.bindLibraryRepository(fakeLib);

        final entry = FeedEntry(
          videoId: 'dQw4w9WgXcQ',
          channelId: _channelId,
          title: 'Test Video',
          publishedAt: DateTime.utc(2024, 1, 1),
        );

        await repo.addFeedEntryToLibrary(entry, contentLanguage: 'en');
        expect(fakeLib.importedVideos['dQw4w9WgXcQ'], 'en');
      });
    });

    group('subscribeFromUserInput', () {
      test('throws FormatException for invalid input', () async {
        final repo = DiscoverRepository(db);
        expect(
          () => repo.subscribeFromUserInput('not a youtube url'),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException for empty input', () async {
        final repo = DiscoverRepository(db);
        expect(
          () => repo.subscribeFromUserInput(''),
          throwsA(isA<FormatException>()),
        );
      });

      test('subscribes new channel from channel ID input', () async {
        final mockClient = MockClient((_) async {
          return http.Response(
            _jsonFeedBody(
              items: [
                {
                  'id': 'dQw4w9WgXcQ',
                  'title': 'Video One',
                  'image': 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
                  'date_published': '2024-06-01T08:00:00.000Z',
                  'attachments': [
                    {
                      'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
                      'mime_type': 'text/html',
                      'duration_in_seconds': 212,
                    },
                  ],
                },
              ],
            ),
            200,
          );
        });

        final repo = DiscoverRepository(db, httpClient: mockClient);
        await repo.subscribeFromUserInput(_channelId);

        final row = await db.youtubeChannelSubscriptionDao.getByChannelId(
          _channelId,
        );
        expect(row, isNotNull);
        expect(row!.displayName, 'Test Channel');
        expect(row.source, YoutubeSubscriptionSource.user);
        expect(row.sourceType, YoutubeSourceType.channel);
        expect(row.thumbnailUrl, 'https://yt3.ggpht.com/avatar.jpg');
        expect(row.language, 'und');

        final entries = await db.youtubeFeedEntryDao.getForChannel(_channelId);
        expect(entries, hasLength(1));
        expect(entries.first.videoId, 'dQw4w9WgXcQ');
        expect(entries.first.title, 'Video One');
        expect(entries.first.durationSeconds, 212);
      });

      test('updates existing subscription on re-subscribe', () async {
        final repo = DiscoverRepository(db);
        await repo.subscribeChannel(
          channelId: _channelId,
          displayName: 'Old Name',
          source: YoutubeSubscriptionSource.recommended,
          thumbnailUrl: 'https://example.com/old.jpg',
        );
        final original = await db.youtubeChannelSubscriptionDao.getByChannelId(
          _channelId,
        );

        final mockClient = MockClient((_) async {
          return http.Response(
            _jsonFeedBody(
              title: 'New Name - YouTube',
              icon: 'https://yt3.ggpht.com/new-avatar.jpg',
            ),
            200,
          );
        });

        final repoWithClient = DiscoverRepository(db, httpClient: mockClient);
        await repoWithClient.subscribeFromUserInput(_channelId);

        final updated = await db.youtubeChannelSubscriptionDao.getByChannelId(
          _channelId,
        );
        expect(updated!.displayName, 'New Name');
        expect(updated.source, YoutubeSubscriptionSource.user);
        expect(updated.subscribedAt, original!.subscribedAt);
        expect(updated.thumbnailUrl, 'https://yt3.ggpht.com/new-avatar.jpg');
        expect(updated.language, original.language);
      });

      test('preserves existing thumbnail when feed has no icon', () async {
        final repo = DiscoverRepository(db);
        await repo.subscribeChannel(
          channelId: _channelId,
          displayName: 'TED',
          source: YoutubeSubscriptionSource.recommended,
          thumbnailUrl: 'https://example.com/existing.jpg',
        );

        final mockClient = MockClient((_) async {
          return http.Response(_jsonFeedBody(icon: null), 200);
        });

        final repoWithClient = DiscoverRepository(db, httpClient: mockClient);
        await repoWithClient.subscribeFromUserInput(_channelId);

        final row = await db.youtubeChannelSubscriptionDao.getByChannelId(
          _channelId,
        );
        expect(row!.thumbnailUrl, 'https://example.com/existing.jpg');
      });

      test('skips entry upsert when feed has no items', () async {
        final mockClient = MockClient((_) async {
          return http.Response(_jsonFeedBody(items: []), 200);
        });

        final repo = DiscoverRepository(db, httpClient: mockClient);
        await repo.subscribeFromUserInput(_channelId);

        final entries = await db.youtubeFeedEntryDao.getForChannel(_channelId);
        expect(entries, isEmpty);
      });

      test('canonicalizes handle to channel ID from feed response', () async {
        final mockClient = MockClient((_) async {
          return http.Response(
            _jsonFeedBody(
              homePageUrl: 'https://www.youtube.com/channel/$_channelId',
            ),
            200,
          );
        });

        final repo = DiscoverRepository(db, httpClient: mockClient);
        await repo.subscribeFromUserInput('@TED');

        final row = await db.youtubeChannelSubscriptionDao.getByChannelId(
          _channelId,
        );
        expect(row, isNotNull);
        expect(row!.sourceType, YoutubeSourceType.channel);
        expect(
          row.feedUrl,
          '$_workerBase/youtube/channel/$_channelId?format=json',
        );
      });

      test('uses parsed canonicalId when feed has no channel URL', () async {
        final mockClient = MockClient((_) async {
          return http.Response(
            _jsonFeedBody(homePageUrl: 'https://www.youtube.com/@TED'),
            200,
          );
        });

        final repo = DiscoverRepository(db, httpClient: mockClient);
        await repo.subscribeFromUserInput(_channelId);

        final row = await db.youtubeChannelSubscriptionDao.getByChannelId(
          _channelId,
        );
        expect(row, isNotNull);
      });
    });

    group('refreshFeeds', () {
      test('returns zero when no subscriptions exist', () async {
        final repo = DiscoverRepository(db);
        final result = await repo.refreshFeeds();
        expect(result.refreshedChannels, 0);
        expect(result.failedChannelIds, isEmpty);
        expect(result.hasFailures, isFalse);
      });

      test('skips recently fetched channels', () async {
        final repo = DiscoverRepository(db);
        await db.youtubeChannelSubscriptionDao.upsert(
          YoutubeChannelSubscriptionRow(
            channelId: _channelId,
            displayName: 'TED',
            source: YoutubeSubscriptionSource.recommended,
            sourceType: YoutubeSourceType.channel,
            feedUrl: '$_workerBase/youtube/channel/$_channelId?format=json',
            subscribedAt: DateTime.now().subtract(const Duration(days: 30)),
            lastFetchedAt: DateTime.now(),
            language: 'und',
          ),
        );

        final result = await repo.refreshFeeds();
        expect(result.refreshedChannels, 0);
        expect(result.failedChannelIds, isEmpty);
      });

      test('force refreshes recently fetched channels', () async {
        final mockClient = MockClient((_) async {
          return http.Response(_jsonFeedBody(), 200);
        });

        final repo = DiscoverRepository(db, httpClient: mockClient);
        await db.youtubeChannelSubscriptionDao.upsert(
          YoutubeChannelSubscriptionRow(
            channelId: _channelId,
            displayName: 'TED',
            source: YoutubeSubscriptionSource.recommended,
            sourceType: YoutubeSourceType.channel,
            feedUrl: '$_workerBase/youtube/channel/$_channelId?format=json',
            subscribedAt: DateTime.now().subtract(const Duration(days: 30)),
            lastFetchedAt: DateTime.now(),
            language: 'und',
          ),
        );

        final result = await repo.refreshFeeds(force: true);
        expect(result.refreshedChannels, 1);
        expect(result.failedChannelIds, isEmpty);
      });

      test('includes channels with null lastFetchedAt', () async {
        final mockClient = MockClient((_) async {
          return http.Response(_jsonFeedBody(), 200);
        });

        final repo = DiscoverRepository(db, httpClient: mockClient);
        await db.youtubeChannelSubscriptionDao.upsert(
          YoutubeChannelSubscriptionRow(
            channelId: _channelId,
            displayName: 'TED',
            source: YoutubeSubscriptionSource.recommended,
            sourceType: YoutubeSourceType.channel,
            feedUrl: '$_workerBase/youtube/channel/$_channelId?format=json',
            subscribedAt: DateTime.now(),
            language: 'und',
          ),
        );

        final result = await repo.refreshFeeds();
        expect(result.refreshedChannels, 1);
      });

      test('reports failed channels on WorkerFeedException', () async {
        final mockClient = MockClient((_) async {
          return http.Response('', 404);
        });

        final repo = DiscoverRepository(db, httpClient: mockClient);
        await db.youtubeChannelSubscriptionDao.upsert(
          YoutubeChannelSubscriptionRow(
            channelId: _channelId,
            displayName: 'TED',
            source: YoutubeSubscriptionSource.recommended,
            sourceType: YoutubeSourceType.channel,
            feedUrl: '$_workerBase/youtube/channel/$_channelId?format=json',
            subscribedAt: DateTime.now().subtract(const Duration(days: 30)),
            lastFetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
            language: 'und',
          ),
        );

        final result = await repo.refreshFeeds();
        expect(result.refreshedChannels, 0);
        expect(result.failedChannelIds, [_channelId]);
        expect(result.hasFailures, isTrue);
      });

      test('reports failed channels on generic exception', () async {
        final mockClient = MockClient((_) async {
          throw Exception('network failure');
        });

        final repo = DiscoverRepository(db, httpClient: mockClient);
        await db.youtubeChannelSubscriptionDao.upsert(
          YoutubeChannelSubscriptionRow(
            channelId: _channelId,
            displayName: 'TED',
            source: YoutubeSubscriptionSource.recommended,
            sourceType: YoutubeSourceType.channel,
            feedUrl: '$_workerBase/youtube/channel/$_channelId?format=json',
            subscribedAt: DateTime.now().subtract(const Duration(days: 30)),
            lastFetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
            language: 'und',
          ),
        );

        final result = await repo.refreshFeeds();
        expect(result.refreshedChannels, 0);
        expect(result.failedChannelIds, [_channelId]);
        expect(result.hasFailures, isTrue);
      });

      test('repairs missing feedUrl for legacy subscriptions', () async {
        String? requestedUrl;
        final mockClient = MockClient((request) async {
          requestedUrl = request.url.toString();
          return http.Response(_jsonFeedBody(), 200);
        });

        final repo = DiscoverRepository(db, httpClient: mockClient);
        await db.youtubeChannelSubscriptionDao.upsert(
          YoutubeChannelSubscriptionRow(
            channelId: _channelId,
            displayName: 'TED',
            source: YoutubeSubscriptionSource.recommended,
            sourceType: YoutubeSourceType.channel,
            subscribedAt: DateTime.now().subtract(const Duration(days: 30)),
            lastFetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
            language: 'und',
          ),
        );

        final result = await repo.refreshFeeds();
        expect(result.refreshedChannels, 1);
        expect(
          requestedUrl,
          '$_workerBase/youtube/channel/$_channelId?format=json',
        );
      });

      test('repairs empty feedUrl for legacy subscriptions', () async {
        String? requestedUrl;
        final mockClient = MockClient((request) async {
          requestedUrl = request.url.toString();
          return http.Response(_jsonFeedBody(), 200);
        });

        final repo = DiscoverRepository(db, httpClient: mockClient);
        await db.youtubeChannelSubscriptionDao.upsert(
          YoutubeChannelSubscriptionRow(
            channelId: _channelId,
            displayName: 'TED',
            source: YoutubeSubscriptionSource.recommended,
            sourceType: YoutubeSourceType.channel,
            feedUrl: '',
            subscribedAt: DateTime.now().subtract(const Duration(days: 30)),
            lastFetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
            language: 'und',
          ),
        );

        final result = await repo.refreshFeeds();
        expect(result.refreshedChannels, 1);
        expect(
          requestedUrl,
          '$_workerBase/youtube/channel/$_channelId?format=json',
        );
      });

      test('upserts feed entries on successful refresh', () async {
        final mockClient = MockClient((_) async {
          return http.Response(
            _jsonFeedBody(
              items: [
                {
                  'id': 'vid00000001',
                  'title': 'First Video',
                  'date_published': '2024-06-01T08:00:00.000Z',
                  'attachments': [
                    {
                      'url': 'https://www.youtube.com/watch?v=vid00000001',
                      'mime_type': 'text/html',
                      'duration_in_seconds': 120,
                    },
                  ],
                },
                {
                  'id': 'vid00000002',
                  'title': 'Second Video',
                  'date_published': '2024-06-02T08:00:00.000Z',
                },
              ],
            ),
            200,
          );
        });

        final repo = DiscoverRepository(db, httpClient: mockClient);
        await db.youtubeChannelSubscriptionDao.upsert(
          YoutubeChannelSubscriptionRow(
            channelId: _channelId,
            displayName: 'TED',
            source: YoutubeSubscriptionSource.recommended,
            sourceType: YoutubeSourceType.channel,
            feedUrl: '$_workerBase/youtube/channel/$_channelId?format=json',
            subscribedAt: DateTime.now().subtract(const Duration(days: 30)),
            lastFetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
            language: 'en',
          ),
        );

        final result = await repo.refreshFeeds();
        expect(result.refreshedChannels, 1);

        final entries = await db.youtubeFeedEntryDao.getForChannel(_channelId);
        expect(entries, hasLength(2));
        expect(
          entries.map((e) => e.videoId),
          containsAll(['vid00000001', 'vid00000002']),
        );
      });

      test('updates subscription metadata after refresh', () async {
        final mockClient = MockClient((_) async {
          return http.Response(
            _jsonFeedBody(
              title: 'Updated Channel - YouTube',
              icon: 'https://yt3.ggpht.com/new-avatar.jpg',
            ),
            200,
          );
        });

        final repo = DiscoverRepository(db, httpClient: mockClient);
        final subscribedAt = DateTime.now().subtract(const Duration(days: 90));
        await db.youtubeChannelSubscriptionDao.upsert(
          YoutubeChannelSubscriptionRow(
            channelId: _channelId,
            displayName: 'Old Name',
            thumbnailUrl: 'https://example.com/old.jpg',
            source: YoutubeSubscriptionSource.recommended,
            sourceType: YoutubeSourceType.channel,
            feedUrl: '$_workerBase/youtube/channel/$_channelId?format=json',
            subscribedAt: subscribedAt,
            lastFetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
            language: 'en',
          ),
        );

        final before = await db.youtubeChannelSubscriptionDao.getByChannelId(
          _channelId,
        );

        await repo.refreshFeeds();

        final row = await db.youtubeChannelSubscriptionDao.getByChannelId(
          _channelId,
        );
        expect(row!.displayName, 'Updated Channel');
        expect(row.thumbnailUrl, 'https://yt3.ggpht.com/new-avatar.jpg');
        expect(row.source, YoutubeSubscriptionSource.recommended);
        expect(row.language, 'en');
        expect(row.subscribedAt, before!.subscribedAt);
        expect(row.lastFetchedAt, isNotNull);
      });

      test('preserves existing thumbnail when feed icon is null', () async {
        final mockClient = MockClient((_) async {
          return http.Response(_jsonFeedBody(icon: null), 200);
        });

        final repo = DiscoverRepository(db, httpClient: mockClient);
        await db.youtubeChannelSubscriptionDao.upsert(
          YoutubeChannelSubscriptionRow(
            channelId: _channelId,
            displayName: 'TED',
            thumbnailUrl: 'https://example.com/existing.jpg',
            source: YoutubeSubscriptionSource.recommended,
            sourceType: YoutubeSourceType.channel,
            feedUrl: '$_workerBase/youtube/channel/$_channelId?format=json',
            subscribedAt: DateTime.now().subtract(const Duration(days: 30)),
            lastFetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
            language: 'und',
          ),
        );

        await repo.refreshFeeds();

        final row = await db.youtubeChannelSubscriptionDao.getByChannelId(
          _channelId,
        );
        expect(row!.thumbnailUrl, 'https://example.com/existing.jpg');
      });

      test('handles mixed success and failure across channels', () async {
        final mockClient = MockClient((request) async {
          if (request.url.toString().contains('UCgood')) {
            return http.Response(_jsonFeedBody(), 200);
          }
          return http.Response('', 500);
        });

        final repo = DiscoverRepository(db, httpClient: mockClient);
        final oldFetch = DateTime.now().subtract(const Duration(hours: 2));

        await db.youtubeChannelSubscriptionDao.upsert(
          YoutubeChannelSubscriptionRow(
            channelId: 'UCgoodChannel00000000000',
            displayName: 'Good',
            source: YoutubeSubscriptionSource.user,
            sourceType: YoutubeSourceType.channel,
            feedUrl:
                '$_workerBase/youtube/channel/UCgoodChannel00000000000?format=json',
            subscribedAt: DateTime.now(),
            lastFetchedAt: oldFetch,
            language: 'und',
          ),
        );
        await db.youtubeChannelSubscriptionDao.upsert(
          YoutubeChannelSubscriptionRow(
            channelId: 'UCbadChannel000000000000',
            displayName: 'Bad',
            source: YoutubeSubscriptionSource.user,
            sourceType: YoutubeSourceType.channel,
            feedUrl:
                '$_workerBase/youtube/channel/UCbadChannel000000000000?format=json',
            subscribedAt: DateTime.now(),
            lastFetchedAt: oldFetch,
            language: 'und',
          ),
        );

        final result = await repo.refreshFeeds();
        expect(result.refreshedChannels, 1);
        expect(result.failedChannelIds, ['UCbadChannel000000000000']);
        expect(result.hasFailures, isTrue);
      });

      test('processes more than 4 channels via batching', () async {
        var requestCount = 0;
        final mockClient = MockClient((_) async {
          requestCount++;
          return http.Response(_jsonFeedBody(), 200);
        });

        final repo = DiscoverRepository(db, httpClient: mockClient);
        final oldFetch = DateTime.now().subtract(const Duration(hours: 2));

        for (var i = 0; i < 6; i++) {
          final id = 'UCbatch${i.toString().padLeft(18, '0')}';
          await db.youtubeChannelSubscriptionDao.upsert(
            YoutubeChannelSubscriptionRow(
              channelId: id,
              displayName: 'Channel $i',
              source: YoutubeSubscriptionSource.user,
              sourceType: YoutubeSourceType.channel,
              feedUrl: '$_workerBase/youtube/channel/$id?format=json',
              subscribedAt: DateTime.now(),
              lastFetchedAt: oldFetch,
              language: 'und',
            ),
          );
        }

        final result = await repo.refreshFeeds();
        expect(result.refreshedChannels, 6);
        expect(result.failedChannelIds, isEmpty);
        expect(requestCount, 6);
      });

      test('skips entry upsert when feed returns empty items', () async {
        final mockClient = MockClient((_) async {
          return http.Response(_jsonFeedBody(items: []), 200);
        });

        final repo = DiscoverRepository(db, httpClient: mockClient);
        await db.youtubeChannelSubscriptionDao.upsert(
          YoutubeChannelSubscriptionRow(
            channelId: _channelId,
            displayName: 'TED',
            source: YoutubeSubscriptionSource.recommended,
            sourceType: YoutubeSourceType.channel,
            feedUrl: '$_workerBase/youtube/channel/$_channelId?format=json',
            subscribedAt: DateTime.now().subtract(const Duration(days: 30)),
            lastFetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
            language: 'und',
          ),
        );

        final result = await repo.refreshFeeds();
        expect(result.refreshedChannels, 1);

        final entries = await db.youtubeFeedEntryDao.getForChannel(_channelId);
        expect(entries, isEmpty);
      });
    });

    group('looksLikeVideoThumbnail', () {
      test('returns false for null', () {
        expect(DiscoverRepository.looksLikeVideoThumbnail(null), isFalse);
      });

      test('returns false for empty string', () {
        expect(DiscoverRepository.looksLikeVideoThumbnail(''), isFalse);
      });

      test('returns true for i.ytimg.com/vi/ URL', () {
        expect(
          DiscoverRepository.looksLikeVideoThumbnail(
            'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
          ),
          isTrue,
        );
      });

      test('returns false for non-video thumbnail URL', () {
        expect(
          DiscoverRepository.looksLikeVideoThumbnail(
            'https://yt3.ggpht.com/avatar.jpg',
          ),
          isFalse,
        );
      });
    });

    group('DiscoverRefreshResult', () {
      test('hasFailures is false when no failed channels', () {
        const result = DiscoverRefreshResult(
          refreshedChannels: 3,
          failedChannelIds: [],
        );
        expect(result.hasFailures, isFalse);
      });

      test('hasFailures is true when channels failed', () {
        const result = DiscoverRefreshResult(
          refreshedChannels: 1,
          failedChannelIds: ['UCfailed'],
        );
        expect(result.hasFailures, isTrue);
      });
    });

    group('YoutubeFeedFetchException', () {
      test('toString returns message', () {
        final e = YoutubeFeedFetchException(
          'Something went wrong',
          statusCode: 500,
        );
        expect(e.toString(), 'Something went wrong');
        expect(e.statusCode, 500);
      });

      test('statusCode is optional', () {
        final e = YoutubeFeedFetchException('error');
        expect(e.statusCode, isNull);
        expect(e.message, 'error');
      });
    });
  });
}
