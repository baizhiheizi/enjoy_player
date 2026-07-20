/// Phone / tablet / desktop form-factor classification and orientation policy.
///
/// See ADR-0059 and `specs/026-orientation-layout-polish/contracts/orientation-policy.md`.
library;

import 'dart:ui' show FlutterView, Size;

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
/// otherwise the safe default is [DeviceFormFactor.phone].
DeviceFormFactor resolveDeviceFormFactor({
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
        return DeviceFormFactor.phone;
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

/// Logical shortest side of a [FlutterView], or `0` when the size is unusable.
double logicalShortestSideFromView(FlutterView view) {
  final dpr = view.devicePixelRatio;
  if (!dpr.isFinite || dpr <= 0) return 0;
  final logical = view.physicalSize / dpr;
  if (!logical.width.isFinite || !logical.height.isFinite) return 0;
  return logicalShortestSideOf(logical);
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
