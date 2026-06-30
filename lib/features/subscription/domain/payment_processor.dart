/// Payment processor for Pro subscription checkout (Enjoy Rails API).
library;

enum PaymentProcessor {
  stripe,
  mixin;

  String get apiValue => name;

  static PaymentProcessor? fromJson(Object? value) {
    if (value == null) return null;
    final s = value.toString().toLowerCase();
    return switch (s) {
      'stripe' => PaymentProcessor.stripe,
      'mixin' => PaymentProcessor.mixin,
      _ => null,
    };
  }
}

enum PaymentStatus {
  pending,
  succeeded,
  expired;

  static PaymentStatus? fromJson(Object? value) {
    if (value == null) return null;
    final s = value.toString().toLowerCase();
    return switch (s) {
      'pending' => PaymentStatus.pending,
      'succeeded' => PaymentStatus.succeeded,
      'expired' => PaymentStatus.expired,
      _ => null,
    };
  }
}
