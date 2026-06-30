/// Payment session returned by `POST /api/v1/subscriptions`.
library;

import 'package:enjoy_player/features/subscription/domain/payment_processor.dart';

class PaymentSession {
  const PaymentSession({
    required this.id,
    required this.paymentType,
    required this.processor,
    required this.status,
    this.payUrl,
    required this.createdAt,
  });

  factory PaymentSession.fromJson(Map<String, dynamic> json) {
    return PaymentSession(
      id: json['id']?.toString() ?? '',
      paymentType: json['paymentType']?.toString() ?? '',
      processor:
          PaymentProcessor.fromJson(json['processor']) ??
          PaymentProcessor.stripe,
      status:
          PaymentStatus.fromJson(json['status']) ?? PaymentStatus.pending,
      payUrl: json['payUrl'] as String?,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  final String id;
  final String paymentType;
  final PaymentProcessor processor;
  final PaymentStatus status;
  final String? payUrl;
  final String createdAt;
}
