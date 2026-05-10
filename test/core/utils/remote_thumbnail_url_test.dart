import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isRemoteThumbnailUrl', () {
    test('false for null, empty, file path, file scheme', () {
      expect(isRemoteThumbnailUrl(null), isFalse);
      expect(isRemoteThumbnailUrl(''), isFalse);
      expect(isRemoteThumbnailUrl(r'C:\x\y.jpg'), isFalse);
      expect(isRemoteThumbnailUrl('file:///x/y.jpg'), isFalse);
    });

    test('true for http and https', () {
      expect(isRemoteThumbnailUrl('http://a/b.jpg'), isTrue);
      expect(isRemoteThumbnailUrl('https://cdn/x.png'), isTrue);
    });
  });

  group('remoteThumbnailForCard', () {
    test('returns url only for http(s)', () {
      expect(remoteThumbnailForCard('https://x/a.jpg'), 'https://x/a.jpg');
      expect(remoteThumbnailForCard(r'C:\a.jpg'), isNull);
      expect(remoteThumbnailForCard(null), isNull);
    });
  });

  group('localThumbnailFileForCard', () {
    test('null for remote urls so cards use Image.network', () {
      expect(localThumbnailFileForCard('https://x/a.jpg'), isNull);
      expect(localThumbnailFileForCard('http://x/a.jpg'), isNull);
    });
  });
}
