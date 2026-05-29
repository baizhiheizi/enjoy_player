import 'package:enjoy_player/features/discover/data/youtube_rss_parser.dart';
import 'package:flutter_test/flutter_test.dart';

const _sampleRss = '''
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns:yt="http://www.youtube.com/xml/schemas/2015" xmlns:media="http://search.yahoo.com/mrss/" xmlns="http://www.w3.org/2005/Atom">
  <entry>
    <yt:videoId>dQw4w9WgXcQ</yt:videoId>
    <title>First video</title>
    <published>2024-06-01T12:00:00+00:00</published>
    <media:group>
      <media:thumbnail url="https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg" />
    </media:group>
  </entry>
  <entry>
    <yt:videoId>abcdefghijk</yt:videoId>
    <title><![CDATA[Second &amp; title]]></title>
    <published>2024-05-01T08:30:00+00:00</published>
  </entry>
</feed>
''';

void main() {
  group('YoutubeRssParser', () {
    const parser = YoutubeRssParser();

    test('parses entries with ids, titles, dates, thumbnails', () {
      final entries = parser.parse(_sampleRss, channelId: 'UCtestchannel0001');
      expect(entries, hasLength(2));
      expect(entries.first.videoId, 'dQw4w9WgXcQ');
      expect(entries.first.title, 'First video');
      expect(entries.first.thumbnailUrl, contains('hqdefault.jpg'));
      expect(entries.first.channelId, 'UCtestchannel0001');
      expect(entries.last.title, 'Second & title');
    });

    test('returns empty list for invalid xml', () {
      expect(parser.parse('<feed></feed>', channelId: 'UCx'), isEmpty);
    });

    test('isValidFeedDocument rejects HTML bot block pages', () {
      expect(
        YoutubeRssParser.isValidFeedDocument(
          '<!DOCTYPE html><html><body>Sorry, unusual traffic</body></html>',
        ),
        isFalse,
      );
      expect(YoutubeRssParser.isValidFeedDocument(_sampleRss), isTrue);
    });

    test('parseFeedTitle reads channel title before entries', () {
      const xml = '''
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>TED - YouTube</title>
  <entry>
    <title>Video title</title>
  </entry>
</feed>
''';
      expect(parser.parseFeedTitle(xml), 'TED');
    });

    test('skips YouTube Shorts entries', () {
      const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns:yt="http://www.youtube.com/xml/schemas/2015" xmlns="http://www.w3.org/2005/Atom">
  <entry>
    <yt:videoId>7iEiEEzzogU</yt:videoId>
    <link rel="alternate" href="https://www.youtube.com/shorts/7iEiEEzzogU"/>
    <title>Short clip</title>
    <published>2026-05-27T21:00:27+00:00</published>
  </entry>
  <entry>
    <yt:videoId>regularVideo1</yt:videoId>
    <link rel="alternate" href="https://www.youtube.com/watch?v=regularVideo1"/>
    <title>Full video</title>
    <published>2026-05-26T21:00:27+00:00</published>
  </entry>
</feed>
''';
      final entries = parser.parse(xml, channelId: 'UCtest');
      expect(entries, hasLength(1));
      expect(entries.single.videoId, 'regularVideo1');
      expect(
        YoutubeRssParser.isShortEntryBlock(
          '<link rel="alternate" href="https://www.youtube.com/shorts/abc"/>',
        ),
        isTrue,
      );
    });
  });
}
