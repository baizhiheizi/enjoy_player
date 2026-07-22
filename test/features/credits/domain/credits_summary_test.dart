import 'package:enjoy_player/features/credits/domain/credits_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CreditsSummary.fromJson', () {
    final summary = CreditsSummary.fromJson({
      'tier': 'free',
      'dailyUsed': 10,
      'dailyLimit': 1000,
      'dailyRemaining': 990,
      'permanentAvailable': 200000,
      'resetAt': 1721692800000,
    });
    expect(summary.permanentAvailable, 200000);
    expect(summary.dailyRemaining, 990);
  });
}
