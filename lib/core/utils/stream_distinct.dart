/// Stream dedupe helpers — skip emissions whose value compares equal to the
/// last value the subscriber already saw.
///
/// Used to absorb redundant Drift re-emissions (and any upstream re-mapping
/// that produces a new container but no semantic change) before the value
/// reaches Riverpod listeners.
library;

import 'dart:async';

/// Returns a stream that forwards [this] emissions for which [equals] returns
/// `false` against the previously forwarded value.
///
/// The returned stream can be listened to any number of times (like Drift's
/// `.watch()` streams): each subscription re-subscribes to [this] and keeps its
/// own "last seen" reference, so there is no cross-talk between consumers.
/// Providers cache one deduped stream per key and hand it to every widget that
/// mounts — a single-subscription stream here threw "Stream has already been
/// listened to" the second time a `StreamBuilder` mounted for the same key.
extension StreamDistinctExt<T> on Stream<T> {
  Stream<T> distinctBy(bool Function(T previous, T current) equals) {
    return Stream<T>.multi((controller) {
      var hasLast = false;
      late T last;
      final upstream = listen(
        (value) {
          if (hasLast && equals(last, value)) return;
          last = value;
          hasLast = true;
          controller.add(value);
        },
        onError: controller.addError,
        onDone: controller.close,
      );
      controller
        ..onPause = upstream.pause
        ..onResume = upstream.resume
        ..onCancel = upstream.cancel;
    }, isBroadcast: isBroadcast);
  }
}
