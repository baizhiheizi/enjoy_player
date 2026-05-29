import 'package:enjoy_player/core/routing/library_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('librarySourceFromUri', () {
    test('defaults to local', () {
      expect(librarySourceFromUri(Uri.parse('/library')), LibrarySource.local);
      expect(
        librarySourceFromUri(Uri.parse('/library?source=local')),
        LibrarySource.local,
      );
      expect(
        librarySourceFromUri(Uri.parse('/library?source=unknown')),
        LibrarySource.local,
      );
    });

    test('parses cloud', () {
      expect(
        librarySourceFromUri(Uri.parse('/library?source=cloud')),
        LibrarySource.cloud,
      );
      expect(
        librarySourceFromUri(Uri.parse('/library?source=CLOUD')),
        LibrarySource.cloud,
      );
    });
  });

  group('libraryRouteForSource', () {
    test('local omits query', () {
      expect(libraryRouteForSource(LibrarySource.local), '/library');
    });

    test('cloud includes query', () {
      expect(
        libraryRouteForSource(LibrarySource.cloud),
        '/library?source=cloud',
      );
    });
  });
}
