import 'dart:convert';

import 'package:enjoy_player/features/vocabulary/domain/vocabulary_locator_json.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('stableLocatorJson', () {
    test('matches JSON.stringify with sorted keys duration,start,type', () {
      const locator = MediaLocator(start: 1234, duration: 5000);
      expect(
        stableLocatorJson(locator),
        '{"duration":5000,"start":1234,"type":"media"}',
      );
    });

    test('is stable for same locator', () {
      const a = MediaLocator(start: 0, duration: 100);
      const b = MediaLocator(start: 0, duration: 100);
      expect(stableLocatorJson(a), stableLocatorJson(b));
    });

    test('changes when start or duration changes', () {
      const a = MediaLocator(start: 0, duration: 100);
      const b = MediaLocator(start: 1, duration: 100);
      const c = MediaLocator(start: 0, duration: 101);
      expect(stableLocatorJson(a), isNot(stableLocatorJson(b)));
      expect(stableLocatorJson(a), isNot(stableLocatorJson(c)));
    });
  });

  group('encode/decode locator for Drift', () {
    test('round-trips MediaLocator', () {
      const locator = MediaLocator(start: 10, duration: 20);
      final encoded = encodeLocatorForDb(media: locator);
      final decoded = decodeLocatorFromDb(encoded);
      expect(decoded.media, locator);
      expect(decoded.ebook, isNull);
      expect(jsonDecode(encoded)['type'], 'media');
    });

    test('round-trips EbookLocator', () {
      const locator = EbookLocator(
        href: 'chapter01.xhtml',
        locatorType: 'application/xhtml+xml',
        title: 'Chapter 1',
      );
      final encoded = encodeLocatorForDb(ebook: locator);
      final decoded = decodeLocatorFromDb(encoded);
      expect(decoded.ebook?.href, 'chapter01.xhtml');
      expect(decoded.ebook?.title, 'Chapter 1');
      expect(decoded.media, isNull);
    });
  });
}
