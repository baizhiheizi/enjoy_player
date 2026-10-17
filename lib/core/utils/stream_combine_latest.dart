/// Combines the latest values of two streams.
library;

import 'dart:async';

/// Emits `combine(latestFirst, latestSecond)` once both [first] and [second]
/// have produced, and again whenever either produces a new value.
Stream<R> combineLatest2<A, B, R>(
  Stream<A> first,
  Stream<B> second,
  R Function(A, B) combine,
) {
  return Stream<R>.multi((controller) {
    A? latestFirst;
    B? latestSecond;
    var hasFirst = false;
    var hasSecond = false;

    void emitIfReady() {
      if (!hasFirst || !hasSecond || controller.isClosed) return;
      controller.add(combine(latestFirst as A, latestSecond as B));
    }

    final firstSub = first.listen((value) {
      latestFirst = value;
      hasFirst = true;
      emitIfReady();
    }, onError: controller.addError);
    final secondSub = second.listen((value) {
      latestSecond = value;
      hasSecond = true;
      emitIfReady();
    }, onError: controller.addError);

    controller.onCancel = () {
      unawaited(firstSub.cancel());
      unawaited(secondSub.cancel());
    };
  }, isBroadcast: first.isBroadcast && second.isBroadcast);
}
