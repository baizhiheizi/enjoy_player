/// Centralized haptic feedback — respects reduced motion and platform capability.
library;

import 'dart:async';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

abstract final class Haptics {
  static bool _hapticCapable() {
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  static bool _reducedMotion(BuildContext? context) {
    if (context == null) return false;
    final mq = MediaQuery.maybeOf(context);
    return mq?.disableAnimations ?? false;
  }

  /// Light tap / selection (navigation, toggles, list rows).
  static void selection(BuildContext context) {
    if (!_hapticCapable() || _reducedMotion(context)) return;
    unawaited(HapticFeedback.selectionClick());
  }

  /// Stronger feedback (long-press menus, destructive confirm).
  static void impactMedium(BuildContext context) {
    if (!_hapticCapable() || _reducedMotion(context)) return;
    unawaited(HapticFeedback.mediumImpact());
  }

  /// Success / completed action (paired with positive SnackBars).
  static void success(BuildContext context) {
    if (!_hapticCapable() || _reducedMotion(context)) return;
    unawaited(HapticFeedback.mediumImpact());
  }

  /// Warning / error attention (paired with error SnackBars).
  static void warning(BuildContext context) {
    if (!_hapticCapable() || _reducedMotion(context)) return;
    unawaited(HapticFeedback.heavyImpact());
  }

  /// Wraps a tap callback with [selection] haptic (for [IconButton], [InkWell], etc.).
  static VoidCallback? wrapTap(BuildContext context, VoidCallback? action) {
    if (action == null) return null;
    return () {
      selection(context);
      action();
    };
  }
}
