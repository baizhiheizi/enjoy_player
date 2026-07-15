import 'package:flutter_test/flutter_test.dart';
import 'package:enjoy_player/features/discover/data/youtube_url_parser.dart';
import 'package:enjoy_player/data/db/youtube_subscription_source.dart';

void main() {
  late YoutubeUrlParser parser;

  setUp(() {
    parser = YoutubeUrlParser(workerBaseUrl: 'https://worker.test');
  });

  group('parse channel URL', () {
    test('parses /channel/UC... URL', () {
      final result = parser.parse(
        'https://www.youtube.com/channel/UCAuUUnT6oDeKwE6v1NGQxug',
      );
      expect(result.sourceType, YoutubeSourceType.channel);
      expect(result.canonicalId, 'UCAuUUnT6oDeKwE6v1NGQxug');
      expect(
        result.feedUrl,
        'https://worker.test/youtube/channel/UCAuUUnT6oDeKwE6v1NGQxug?format=json',
      );
    });

    test('parses raw channel ID', () {
      final result = parser.parse('UCAuUUnT6oDeKwE6v1NGQxug');
      expect(result.sourceType, YoutubeSourceType.channel);
      expect(result.canonicalId, 'UCAuUUnT6oDeKwE6v1NGQxug');
    });

    test('rejects invalid channel ID format', () {
      expect(() => parser.parse('UCshort'), throwsA(isA<FormatException>()));
    });
  });

  group('parse handle URL', () {
    test('parses @handle', () {
      final result = parser.parse('https://www.youtube.com/@TED');
      expect(result.sourceType, YoutubeSourceType.channel);
      expect(result.canonicalId, '@TED');
      expect(
        result.feedUrl,
        'https://worker.test/youtube/user/@TED?format=json',
      );
    });

    test('parses raw @handle without URL', () {
      final result = parser.parse('@TED');
      expect(result.sourceType, YoutubeSourceType.channel);
      expect(result.canonicalId, '@TED');
    });

    test('parses /user/username URL', () {
      final result = parser.parse('https://www.youtube.com/user/TEDtalks');
      expect(result.sourceType, YoutubeSourceType.channel);
      expect(result.canonicalId, '@TEDtalks');
    });
  });

  group('parse playlist URL', () {
    test('parses /playlist?list=PL... URL', () {
      final result = parser.parse(
        'https://www.youtube.com/playlist?list=PLqQ1RwlxOgeLTJ1f3fNMSwhjVgaWKo_9Z',
      );
      expect(result.sourceType, YoutubeSourceType.playlist);
      expect(result.canonicalId, 'PLqQ1RwlxOgeLTJ1f3fNMSwhjVgaWKo_9Z');
      expect(
        result.feedUrl,
        'https://worker.test/youtube/playlist/PLqQ1RwlxOgeLTJ1f3fNMSwhjVgaWKo_9Z?format=json',
      );
    });

    test('parses raw playlist ID', () {
      final result = parser.parse('PLqQ1RwlxOgeLTJ1f3fNMSwhjVgaWKo_9Z');
      expect(result.sourceType, YoutubeSourceType.playlist);
      expect(result.canonicalId, 'PLqQ1RwlxOgeLTJ1f3fNMSwhjVgaWKo_9Z');
    });
  });

  group('invalid inputs', () {
    test('rejects single video URL', () {
      expect(
        () => parser.parse('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects non-YouTube domain', () {
      expect(
        () => parser.parse('https://vimeo.com/channel/123'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects empty string', () {
      expect(() => parser.parse(''), throwsA(isA<FormatException>()));
    });

    test('rejects non-YouTube URLs', () {
      expect(
        () => parser.parse('https://www.example.com'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects garbage text', () {
      expect(
        () => parser.parse('this is not a url'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
