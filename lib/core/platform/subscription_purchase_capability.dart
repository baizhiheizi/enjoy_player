/// Platform rules for subscription purchase (desktop checkout vs mobile deferral).
library;

import 'package:flutter/foundation.dart';

/// Windows and macOS direct-download builds may use external Enjoy checkout.
bool supportsExternalSubscriptionPurchase({TargetPlatform? platform}) {
  final p = platform ?? defaultTargetPlatform;
  return p == TargetPlatform.windows || p == TargetPlatform.macOS;
}

/// iOS and Android show coming-soon instead of external checkout in v1.
bool showsMobilePurchaseUnavailable({TargetPlatform? platform}) {
  final p = platform ?? defaultTargetPlatform;
  return p == TargetPlatform.iOS || p == TargetPlatform.android;
}
