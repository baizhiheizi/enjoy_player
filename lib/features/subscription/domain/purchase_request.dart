/// Desktop subscription purchase parameters.
library;

import 'package:enjoy_player/features/subscription/domain/payment_processor.dart';

class PurchaseRequest {
  const PurchaseRequest({required this.months, required this.processor});

  final int months;
  final PaymentProcessor processor;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'months': months,
      'processor': processor.apiValue,
    };
  }
}

/// Display price per month (USD); server owns checkout totals.
const kSubscriptionMonthlyPriceUsd = 9.99;
