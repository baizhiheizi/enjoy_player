import 'package:enjoy_player/features/player/application/open_media_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('openMediaActionProvider disables Riverpod auto-retry', () {
    expect(openMediaActionProvider('media-id').retry, isNull);
  });
}
