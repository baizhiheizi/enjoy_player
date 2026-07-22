/// Phone / tablet / desktop form-factor classification and orientation policy.
///
/// See ADR-0059 and `specs/026-orientation-layout-polish/contracts/orientation-policy.md`.
library;

import 'dart:ui' show Display, FlutterView, Size;

import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter/services.dart' show DeviceOrientation, SystemChrome;

/// Material / Flutter tablet threshold: shortest side ≥ this many logical
/// pixels classifies an iOS/Android device as tablet-class.
const double kTabletShortestSideLogical = 600;

/// Logical device class for app-wide orientation policy.
enum DeviceFormFactor {
  /// Mobile, shortest side &lt; [kTabletShortestSideLogical]. Portrait lock.
  phone,

  /// Mobile, shortest side ≥ [kTabletShortestSideLogical]. All orientations.
  tablet,

  /// Windows / macOS / Linux. No mobile orientation lock.
  desktop,
}

/// Resolves [DeviceFormFactor] from platform + logical shortest side.
///
/// Desktop platforms always return [DeviceFormFactor.desktop] (shortest side
/// is ignored). On mobile, [shortestSideLogical] must be finite and &gt; 0;
/// otherwise returns `null` so callers can defer applying a lock (never guess
/// phone — that portrait-locks tablets when bootstrap metrics are still zero).
DeviceFormFactor? resolveDeviceFormFactor({
  required TargetPlatform platform,
  required double shortestSideLogical,
}) {
  switch (platform) {
    case TargetPlatform.windows:
    case TargetPlatform.macOS:
    case TargetPlatform.linux:
    case TargetPlatform.fuchsia:
      return DeviceFormFactor.desktop;
    case TargetPlatform.iOS:
    case TargetPlatform.android:
      if (!shortestSideLogical.isFinite || shortestSideLogical <= 0) {
        return null;
      }
      return shortestSideLogical >= kTabletShortestSideLogical
          ? DeviceFormFactor.tablet
          : DeviceFormFactor.phone;
  }
}

/// Preferred orientations for [formFactor], or `null` when the caller must
/// not invoke [SystemChrome.setPreferredOrientations] (desktop).
List<DeviceOrientation>? preferredOrientationsFor(DeviceFormFactor formFactor) {
  switch (formFactor) {
    case DeviceFormFactor.phone:
      return const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ];
    case DeviceFormFactor.tablet:
      return const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ];
    case DeviceFormFactor.desktop:
      return null;
  }
}

/// Logical shortest side of [size] (`min(width, height)`).
double logicalShortestSideOf(Size size) {
  final w = size.width;
  final h = size.height;
  return w < h ? w : h;
}

/// Logical shortest side of a [Display], or `0` when the size is unusable.
///
/// Prefer this over [logicalShortestSideFromView] when deciding whether to
/// lock orientation: [FlutterView.physicalSize] can be [Size.zero] at
/// startup and, after a wrong portrait lock, reports the letterboxed window
/// instead of the device — see [SystemChrome.setPreferredOrientations].
double logicalShortestSideFromDisplay(Display display) {
  final dpr = display.devicePixelRatio;
  if (!dpr.isFinite || dpr <= 0) return 0;
  final physical = display.size;
  if (!physical.width.isFinite || !physical.height.isFinite) return 0;
  if (physical.isEmpty) return 0;
  return logicalShortestSideOf(physical / dpr);
}

/// Logical shortest side of a [FlutterView]'s [Display], or `0` when unusable.
double logicalShortestSideFromView(FlutterView view) {
  return logicalShortestSideFromDisplay(view.display);
}

/// Applies [preferredOrientationsFor] via [SystemChrome] when non-null.
///
/// No-op for [DeviceFormFactor.desktop]. Throws from [SystemChrome] are not
/// caught here — callers should wrap if bootstrap must continue.
Future<void> applyPreferredOrientationsForFormFactor(
  DeviceFormFactor formFactor,
) async {
  final orientations = preferredOrientationsFor(formFactor);
  if (orientations == null) return;
  await SystemChrome.setPreferredOrientations(orientations);
}
