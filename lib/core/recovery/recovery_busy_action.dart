/// Shared busy-flag plumbing for the recovery surfaces.
///
/// Both [RecoverySurface] and [WidgetErrorSurface] drive their copy /
/// open-logs / reset actions through an identical `setState(busy=true)`
/// → `await … if (!mounted) return; AppLocalizations.of(context)!; …`
/// → `finally { if (mounted) setState(busy=false); }` shape. Centralising
/// the busy flag and mounted-after-await guard in one mixin eliminates
/// the duplicated skeleton and structurally prevents a handler from
/// forgetting the guard (a `setState() called after dispose()` crash).
library;

import 'package:flutter/widgets.dart';

/// Mixin for a [State] that owns a single `_busy` flag for in-flight
/// async button-handler work.
///
/// Concrete states are expected to expose a busy-button affordance via
/// `onPressed: busy ? null : _onFoo`; that is why [_busy] is private but
/// [busy] is a public getter.
mixin RecoveryBusyAction<T extends StatefulWidget> on State<T> {
  bool _busy = false;

  /// True while a [runBusyAction] is awaiting its body or its
  /// post-await callback. Drives the buttons' `onPressed: busy ? null : …`
  /// disable pattern.
  bool get busy => _busy;

  /// Runs [body] with [busy] set to true for the duration. The optional
  /// [onAfter] callback is invoked with the body's result only if the
  /// state is still [mounted] when the future resolves — handlers that
  /// read `context` after the await get a stable post-await mounted
  /// check for free.
  ///
  /// [busy] is always reset in a `finally` block guarded by `mounted`,
  /// so a widget dispose between the `await` and the post-await UI
  /// action cannot trigger `setState() called after dispose()`.
  Future<void> runBusyAction<R>(
    Future<R> Function() body,
    Future<void> Function(BuildContext ctx, R result)? onAfter,
  ) async {
    setState(() => _busy = true);
    try {
      final result = await body();
      if (!mounted) return;
      if (onAfter != null) {
        await onAfter(context, result);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
