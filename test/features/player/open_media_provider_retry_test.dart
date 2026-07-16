import 'package:enjoy_player/features/player/application/open_media_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('openMediaActionProvider disables Riverpod auto-retry', () {
    // MediaNeedsRelocateException must surface once so LocateMediaScreen
    // can settle — Riverpod 3's default exponential retry would re-open forever.
    expect(openMediaActionProvider('media-id').retry, isNull);
  });
}
