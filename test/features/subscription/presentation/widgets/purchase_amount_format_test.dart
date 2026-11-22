import 'package:enjoy_player/features/subscription/presentation/widgets/purchase_amount_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  final previousDefault = Intl.defaultLocale;
  setUpAll(() => Intl.defaultLocale = 'en');
  tearDownAll(() => Intl.defaultLocale = previousDefault);

  test('formats a USD amount with two decimals like a fresh construction', () {
    expect(formatUsdAmount(12.5), '12.50');
    expect(formatUsdAmount(0), '0.00');
    expect(formatUsdAmount(1234.5), NumberFormat('0.00').format(1234.5));
  });
}
