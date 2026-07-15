import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:enjoy_player/data/api/services/ai/youtube_feed_api.dart';
import 'package:enjoy_player/features/discover/data/worker_feed_exception.dart';

void main() {
  group('fetchFeed success', () {
    test('parses valid JSON Feed response', () async {
      final jsonBody = '''
      {
        "version": "https://jsonfeed.org/version/1.1",
        "title": "TED - YouTube",
        "home_page_url": "https://www.youtube.com/channel/UCAuUUnT6oDeKwE6v1NGQxug",
        "icon": "https://yt3.ggpht.com/avatar.jpg",
        "items": [
          {
            "id": "dQw4w9WgXcQ",
            "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            "title": "Test Video",
            "image": "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg",
            "date_published": "2026-07-10T08:00:00.000Z",
            "attachments": [
              {"url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ", "mime_type": "text/html", "duration_in_seconds": 212}
            ]
          }
        ]
      }
      ''';

      final mockClient = MockClient((request) async {
        return http.Response(jsonBody, 200);
      });

      final client = YoutubeFeedClient(httpClient: mockClient);

      final result = await client.fetchFeed(
        'https://worker.test/youtube/channel/UC_test?format=json',
      );

      expect(result.feedResult.displayName, 'TED');
      expect(result.feedResult.entries.length, 1);
      expect(result.feedResult.entries.first.videoId, 'dQw4w9WgXcQ');
      expect(result.feedResult.entries.first.durationSeconds, 212);
    });
  });

  group('handle-to-ID canonicalization', () {
    test('extracts channel ID from home_page_url', () async {
      final jsonBody = '''
      {
        "version": "https://jsonfeed.org/version/1.1",
        "title": "TED - YouTube",
        "home_page_url": "https://www.youtube.com/channel/UCAuUUnT6oDeKwE6v1NGQxug",
        "icon": "https://yt3.ggpht.com/avatar.jpg",
        "items": []
      }
      ''';

      final mockClient = MockClient((request) async {
        return http.Response(jsonBody, 200);
      });

      final client = YoutubeFeedClient(httpClient: mockClient);

      final result = await client.fetchFeed(
        'https://worker.test/youtube/user/@TED?format=json',
      );

      expect(result.canonicalChannelId, 'UCAuUUnT6oDeKwE6v1NGQxug');
    });

    test('returns null canonicalChannelId for non-handle feeds', () async {
      final jsonBody = '''
      {
        "version": "https://jsonfeed.org/version/1.1",
        "title": "TED - YouTube",
        "home_page_url": "https://www.youtube.com/channel/UC...",
        "icon": "https://yt3.ggpht.com/avatar.jpg",
        "items": []
      }
      ''';

      final mockClient = MockClient((request) async {
        return http.Response(jsonBody, 200);
      });

      final client = YoutubeFeedClient(httpClient: mockClient);

      final result = await client.fetchFeed(
        'https://worker.test/youtube/channel/UC...?format=json',
      );

      expect(result.canonicalChannelId, isNull);
    });
  });

  group('fetchFeed errors', () {
    test('throws notFound on 404', () async {
      final mockClient = MockClient((request) async {
        return http.Response('', 404);
      });
      final client = YoutubeFeedClient(httpClient: mockClient);

      expect(
        () => client.fetchFeed(
          'https://worker.test/youtube/channel/unknown?format=json',
        ),
        throwsA(
          predicate<WorkerFeedException>(
            (e) => e.kind == WorkerFeedErrorKind.notFound,
          ),
        ),
      );
    });

    test('throws sourceUnavailable on 410', () async {
      final mockClient = MockClient((request) async {
        return http.Response('', 410);
      });
      final client = YoutubeFeedClient(httpClient: mockClient);

      expect(
        () => client.fetchFeed(
          'https://worker.test/youtube/channel/gone?format=json',
        ),
        throwsA(
          predicate<WorkerFeedException>(
            (e) => e.kind == WorkerFeedErrorKind.sourceUnavailable,
          ),
        ),
      );
    });

    test('throws rateLimited on 429', () async {
      final mockClient = MockClient((request) async {
        return http.Response('', 429);
      });
      final client = YoutubeFeedClient(httpClient: mockClient);

      expect(
        () => client.fetchFeed(
          'https://worker.test/youtube/channel/rl?format=json',
        ),
        throwsA(
          predicate<WorkerFeedException>(
            (e) => e.kind == WorkerFeedErrorKind.rateLimited,
          ),
        ),
      );
    });

    test('throws upstreamFailure on 502', () async {
      final mockClient = MockClient((request) async {
        return http.Response('', 502);
      });
      final client = YoutubeFeedClient(httpClient: mockClient);

      expect(
        () => client.fetchFeed(
          'https://worker.test/youtube/channel/upstream?format=json',
        ),
        throwsA(
          predicate<WorkerFeedException>(
            (e) => e.kind == WorkerFeedErrorKind.upstreamFailure,
          ),
        ),
      );
    });

    test('throws httpError on other 4xx', () async {
      final mockClient = MockClient((request) async {
        return http.Response('', 403);
      });
      final client = YoutubeFeedClient(httpClient: mockClient);

      expect(
        () => client.fetchFeed(
          'https://worker.test/youtube/channel/forbidden?format=json',
        ),
        throwsA(
          predicate<WorkerFeedException>(
            (e) =>
                e.kind == WorkerFeedErrorKind.httpError && e.statusCode == 403,
          ),
        ),
      );
    });
  });

  group('extractChannelIdFromUrl', () {
    test('extracts from standard channel URL', () {
      expect(
        extractChannelIdFromUrl(
          'https://www.youtube.com/channel/UCAuUUnT6oDeKwE6v1NGQxug',
        ),
        'UCAuUUnT6oDeKwE6v1NGQxug',
      );
    });

    test('returns null for non-channel URL', () {
      expect(extractChannelIdFromUrl('https://www.youtube.com/@TED'), isNull);
    });

    test('returns null for non-YouTube URL', () {
      expect(extractChannelIdFromUrl('https://www.example.com'), isNull);
    });
  });
}
