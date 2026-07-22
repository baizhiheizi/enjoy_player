import 'package:enjoy_player/features/credits/domain/credits_package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CreditsPackage.fromJson', () {
    final pkg = CreditsPackage.fromJson({
      'id': 'credits_5',
      'amount': '5.00',
      'currency': 'USD',
      'credits': 500000,
      'rate': {'usd': 1, 'credits': 100000},
    });
    expect(pkg.id, 'credits_5');
    expect(pkg.credits, 500000);
    expect(pkg.amount, '5.00');
  });

  test('CreditsPackagePurchaseSession.fromJson', () {
    final session = CreditsPackagePurchaseSession.fromJson({
      'id': 'pay-1',
      'status': 'pending',
      'paymentType': 'credits_package',
      'amount': '5.00',
      'payUrl': 'https://checkout.example.com',
      'package': {
        'id': 'credits_5',
        'amount': '5.00',
        'currency': 'USD',
        'credits': 500000,
      },
    });
    expect(session.payUrl, isNotEmpty);
    expect(session.package.credits, 500000);
  });
}
