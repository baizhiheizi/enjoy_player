import 'package:flutter_test/flutter_test.dart';
import 'package:enjoy_player/features/discover/data/json_feed_parser.dart';

void main() {
  late JsonFeedParser parser;

  setUp(() {
    parser = JsonFeedParser();
  });

  group('extractVideoId', () {
    test('extracts from watch URL', () {
      expect(
        extractVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('extracts from watch URL with extra params', () {
      expect(
        extractVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=30s'),
        'dQw4w9WgXcQ',
      );
    });

    test('returns bare video ID as-is', () {
      expect(extractVideoId('dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
    });

    test('extracts from youtu.be short URL', () {
      expect(extractVideoId('https://youtu.be/dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
    });
  });

  group('parse valid JSON Feed', () {
    test('parses full channel feed', () {
      final json = '''
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
            "authors": [{"name": "TED"}],
            "attachments": [
              {
                "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
                "mime_type": "text/html",
                "duration_in_seconds": 212
              }
            ]
          }
        ]
      }
      ''';

      final result = parser.parse(json);

      expect(result.displayName, 'TED');
      expect(
        result.homePageUrl,
        'https://www.youtube.com/channel/UCAuUUnT6oDeKwE6v1NGQxug',
      );
      expect(result.iconUrl, 'https://yt3.ggpht.com/avatar.jpg');
      expect(result.entries.length, 1);

      final entry = result.entries.first;
      expect(entry.videoId, 'dQw4w9WgXcQ');
      expect(entry.title, 'Test Video');
      expect(
        entry.thumbnailUrl,
        'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
      );
      expect(entry.durationSeconds, 212);
      expect(entry.publishedAt, DateTime.utc(2026, 7, 10, 8, 0, 0));
    });

    test('extracts display name without YouTube suffix', () {
      final json = '''
      {
        "version": "https://jsonfeed.org/version/1.1",
        "title": "Learning English - YouTube",
        "home_page_url": "https://www.youtube.com/channel/UC...",
        "items": []
      }
      ''';
      final result = parser.parse(json);
      expect(result.displayName, 'Learning English');
    });

    test('handles title without - YouTube suffix', () {
      final json = '''
      {
        "version": "https://jsonfeed.org/version/1.1",
        "title": "Plain Title",
        "home_page_url": "https://www.youtube.com/channel/UC...",
        "items": []
      }
      ''';
      final result = parser.parse(json);
      expect(result.displayName, 'Plain Title');
    });
  });

  group('parse with optional missing fields', () {
    test('missing icon', () {
      final json = '''
      {
        "version": "https://jsonfeed.org/version/1.1",
        "title": "Test - YouTube",
        "home_page_url": "https://www.youtube.com/channel/UC...",
        "items": []
      }
      ''';
      final result = parser.parse(json);
      expect(result.iconUrl, isNull);
    });

    test('missing duration in attachments', () {
      final json = '''
      {
        "version": "https://jsonfeed.org/version/1.1",
        "title": "Test - YouTube",
        "home_page_url": "https://www.youtube.com/channel/UC...",
        "items": [
          {
            "id": "dQw4w9WgXcQ",
            "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            "title": "No Duration"
          }
        ]
      }
      ''';
      final result = parser.parse(json);
      expect(result.entries.first.durationSeconds, isNull);
    });

    test('missing date_published uses current time', () {
      final json = '''
      {
        "version": "https://jsonfeed.org/version/1.1",
        "title": "Test - YouTube",
        "home_page_url": "https://www.youtube.com/channel/UC...",
        "items": [
          {
            "id": "dQw4w9WgXcQ",
            "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            "title": "No Date"
          }
        ]
      }
      ''';
      final now = DateTime.now();
      final result = parser.parse(json);
      expect(
        result.entries.first.publishedAt.difference(now).inSeconds,
        lessThan(5),
      );
    });

    test('missing items array causes error', () {
      final json = '''
      {
        "version": "https://jsonfeed.org/version/1.1",
        "title": "Test - YouTube",
        "home_page_url": "https://www.youtube.com/channel/UC..."
      }
      ''';
      expect(() => parser.parse(json), throwsA(isA<FormatException>()));
    });
  });

  group('invalid JSON Feed', () {
    test('rejects non-JSON', () {
      expect(() => parser.parse('not json'), throwsA(isA<FormatException>()));
    });

    test('rejects missing version', () {
      expect(
        () => parser.parse('{"title": "Test", "items": []}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects missing title', () {
      expect(
        () => parser.parse(
          '{"version": "https://jsonfeed.org/version/1.1", "items": []}',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects empty title', () {
      expect(
        () => parser.parse(
          '{"version": "https://jsonfeed.org/version/1.1", "title": "", "items": []}',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects items not a list', () {
      expect(
        () => parser.parse(
          '{"version": "https://jsonfeed.org/version/1.1", "title": "T", "items": "not_a_list"}',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('skips items with empty id', () {
      final json = '''
      {
        "version": "https://jsonfeed.org/version/1.1",
        "title": "Test - YouTube",
        "home_page_url": "https://www.youtube.com/channel/UC...",
        "items": [
          {"id": "", "title": "Empty ID"},
          {"id": "dQw4w9WgXcQ", "title": "Valid"}
        ]
      }
      ''';
      final result = parser.parse(json);
      expect(result.entries.length, 1);
    });
  });
}
