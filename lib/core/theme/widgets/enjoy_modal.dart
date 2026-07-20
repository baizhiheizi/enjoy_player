/// Shared modal bottom sheet and dialog chrome (barrier, shape, max width).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

Color enjoyModalBarrierColor() => Colors.black.withValues(alpha: 0.52);

/// Whether [context] should use a compact bottom sheet vs a centered modal.
///
/// Uses [EnjoyThemeTokens.breakpointCompact] (600) against the current width.
@visibleForTesting
bool enjoyUseCompactSheet(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return width < EnjoyThemeTokens.of(context).breakpointCompact;
}

/// Standard Enjoy modal bottom sheet (drag handle left to sheet content).
Future<T?> showEnjoySheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context) builder,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool useSafeArea = true,
}) {
  final t = EnjoyThemeTokens.of(context);
  final cs = Theme.of(context).colorScheme;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    useSafeArea: useSafeArea,
    showDragHandle: false,
    backgroundColor: cs.surfaceContainerHigh,
    barrierColor: enjoyModalBarrierColor(),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(t.radiusXl)),
    ),
    builder: builder,
  );
}

/// Adaptive Enjoy sheet: bottom sheet on compact widths, centered dialog on wide.
///
/// Same barrier color and surface styling as [showEnjoySheet] / [showEnjoyDialog].
Future<T?> showEnjoyAdaptiveSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context) builder,
  bool isScrollControlled = true,
  bool useRootNavigator = false,
  bool useSafeArea = true,
  bool barrierDismissible = true,
}) {
  if (enjoyUseCompactSheet(context)) {
    return showEnjoySheet<T>(
      context: context,
      builder: builder,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      useSafeArea: useSafeArea,
    );
  }

  final t = EnjoyThemeTokens.of(context);
  final cs = Theme.of(context).colorScheme;
  return showDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    barrierColor: enjoyModalBarrierColor(),
    builder: (ctx) {
      return Dialog(
        backgroundColor: cs.surfaceContainerHigh,
        insetPadding: EdgeInsets.symmetric(
          horizontal: t.space24,
          vertical: t.space24,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusXl),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: t.modalMaxWidthLarge,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
          ),
          child: builder(ctx),
        ),
      );
    },
  );
}

/// Centered [AlertDialog] with token max width on content and shared scrim.
Future<T?> showEnjoyAlertDialog<T>({
  required BuildContext context,
  Widget? title,
  Widget? content,
  List<Widget>? actions,
  List<Widget> Function(BuildContext dialogContext)? actionsBuilder,
  bool barrierDismissible = true,
  bool useRootNavigator = false,
}) {
  final t = EnjoyThemeTokens.of(context);
  return showDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    barrierColor: enjoyModalBarrierColor(),
    builder: (ctx) {
      final resolved = actions ?? actionsBuilder?.call(ctx);
      return AlertDialog(
        title: title,
        content: content == null
            ? null
            : ConstrainedBox(
                constraints: BoxConstraints(maxWidth: t.modalMaxWidth),
                child: content,
              ),
        actions: resolved,
      );
    },
  );
}

/// [showDialog] with Enjoy scrim (e.g. custom [Dialog] / loading states).
Future<T?> showEnjoyDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext context) builder,
  bool barrierDismissible = true,
  bool useRootNavigator = false,
}) {
  return showDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    barrierColor: enjoyModalBarrierColor(),
    builder: builder,
  );
}
