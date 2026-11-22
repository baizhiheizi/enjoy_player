import 'package:enjoy_player/data/api/checkout_client_tag.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the native checkout client tag keeps the enjoy.bot wire value', () {
    expect(kNativeCheckoutClientTag, 'enjoy_player');
  });
}
