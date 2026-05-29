/// Compile-time distribution channel (store vs direct download).
library;

import 'package:flutter/foundation.dart';

/// How this build is distributed (`DISTRIBUTION_CHANNEL` dart-define).
enum DistributionChannel {
  /// TestFlight, Play test, or future App Store / Play production.
  store,

  /// Windows/macOS installer or Android sideload APK from dl.enjoy.bot.
  direct,
}

/// Parsed from `--dart-define=DISTRIBUTION_CHANNEL=store|direct`.
///
/// When unset, dev defaults match early-days policy: mobile → [store],
/// desktop → [direct].
DistributionChannel resolveDistributionChannel() {
  const raw = String.fromEnvironment('DISTRIBUTION_CHANNEL');
  switch (raw) {
    case 'store':
      return DistributionChannel.store;
    case 'direct':
      return DistributionChannel.direct;
    default:
      break;
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.android:
      return DistributionChannel.store;
    default:
      return DistributionChannel.direct;
  }
}

/// Whether this build should run the direct-download update coordinator.
bool get isDirectDistributionChannel =>
    resolveDistributionChannel() == DistributionChannel.direct;
