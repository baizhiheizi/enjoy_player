import 'package:enjoy_player/features/discover/data/youtube_channel_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('YoutubeChannelResolver', () {
    test('returns raw channel id input', () async {
      const id = 'UCAuUUnT6oDeKwE6v1NGQxug';
      final resolver = YoutubeChannelResolver(
        client: MockClient((_) async {
          fail('should not fetch');
        }),
      );
      expect(await resolver.resolve(id), id);
    });

    test('extracts channel id from /channel/ URL', () async {
      const id = 'UCAuUUnT6oDeKwE6v1NGQxug';
      final resolver = YoutubeChannelResolver(
        client: MockClient((_) async {
          fail('should not fetch');
        }),
      );
      expect(await resolver.resolve('https://www.youtube.com/channel/$id'), id);
    });

    test('extracts channel id from HTML browse page', () async {
      const id = 'UCAuUUnT6oDeKwE6v1NGQxug';
      final resolver = YoutubeChannelResolver(
        client: MockClient((request) async {
          return http.Response('<html>"channelId":"$id"</html>', 200);
        }),
      );
      expect(await resolver.resolve('@TEDEd'), id);
    });

    test('resolveDetailed returns display name from HTML', () async {
      const id = 'UCAuUUnT6oDeKwE6v1NGQxug';
      final resolver = YoutubeChannelResolver(
        client: MockClient((request) async {
          return http.Response(
            '<html><meta property="og:title" content="TED-Ed - YouTube">'
            '"channelId":"$id"</html>',
            200,
          );
        }),
      );
      final resolved = await resolver.resolveDetailed('@TEDEd');
      expect(resolved.channelId, id);
      expect(resolved.displayName, 'TED-Ed');
    });

    test('parseAvatarUrlFromHtml extracts channel profile photo', () {
      const avatar = r'https://yt3.ggpht.com/abc=s88-c-k-c0x00ffffff-no-rj';
      final html =
          '"avatar":{"thumbnails":[{"url":"$avatar"}],"accessibility":{}}';
      expect(YoutubeChannelResolver.parseAvatarUrlFromHtml(html), avatar);
    });

    test('fetchChannelAvatarUrl loads avatar from channel page', () async {
      const id = 'UCAuUUnT6oDeKwE6v1NGQxug';
      const avatar =
          r'https://yt3.googleusercontent.com/ytc/example=s176-c-k-c0x00ffffff-no-rj';
      final resolver = YoutubeChannelResolver(
        client: MockClient((request) async {
          expect(request.url.path, '/channel/$id');
          return http.Response(
            '"channelAvatarRenderer":{"thumbnails":[{"url":"$avatar"}]}',
            200,
          );
        }),
      );
      expect(await resolver.fetchChannelAvatarUrl(id), avatar);
    });

    test('rejects non-YouTube URLs', () async {
      final resolver = YoutubeChannelResolver(
        client: MockClient((_) async {
          fail('should not fetch');
        }),
      );
      expect(
        () => resolver.resolve('https://example.com/channel/foo'),
        throwsA(isA<YoutubeChannelResolveException>()),
      );
    });
  });
}
