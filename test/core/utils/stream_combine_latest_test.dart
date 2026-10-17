import 'dart:async';

import 'package:enjoy_player/core/utils/stream_combine_latest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emits only after both sides have produced', () async {
    final first = StreamController<int>();
    final second = StreamController<String>();
    addTearDown(first.close);
    addTearDown(second.close);
    final emissions = <String>[];
    final sub = combineLatest2(
      first.stream,
      second.stream,
      (int a, String b) => '$a$b',
    ).listen(emissions.add);
    addTearDown(sub.cancel);

    first.add(1);
    await Future<void>.delayed(Duration.zero);
    expect(emissions, isEmpty);

    second.add('a');
    await Future<void>.delayed(Duration.zero);
    expect(emissions, ['1a']);

    first.add(2);
    await Future<void>.delayed(Duration.zero);
    expect(emissions, ['1a', '2a']);

    second.add('b');
    await Future<void>.delayed(Duration.zero);
    expect(emissions, ['1a', '2a', '2b']);
  });

  test('one listener does not dedupe against another', () async {
    final first = StreamController<int>.broadcast();
    final second = StreamController<int>.broadcast();
    addTearDown(first.close);
    addTearDown(second.close);
    final stream = combineLatest2(
      first.stream,
      second.stream,
      (int a, int b) => a + b,
    );
    final left = <int>[];
    final right = <int>[];
    final subLeft = stream.listen(left.add);
    final subRight = stream.listen(right.add);
    addTearDown(subLeft.cancel);
    addTearDown(subRight.cancel);

    first.add(1);
    second.add(2);
    await Future<void>.delayed(Duration.zero);

    expect(left, [3]);
    expect(right, [3]);
  });

  test('cancelling a listener cancels both upstream subscriptions', () async {
    var firstCancelled = false;
    var secondCancelled = false;
    final first = StreamController<int>(onCancel: () => firstCancelled = true);
    final second = StreamController<int>(
      onCancel: () => secondCancelled = true,
    );
    addTearDown(first.close);
    addTearDown(second.close);
    final sub = combineLatest2(
      first.stream,
      second.stream,
      (int a, int b) => a + b,
    ).listen((_) {});
    await sub.cancel();

    expect(firstCancelled, isTrue);
    expect(secondCancelled, isTrue);
  });

  test('errors forward without closing the combination', () async {
    final first = StreamController<int>();
    final second = StreamController<int>();
    addTearDown(first.close);
    addTearDown(second.close);
    final errors = <Object>[];
    final emissions = <int>[];
    final sub = combineLatest2(
      first.stream,
      second.stream,
      (int a, int b) => a + b,
    ).listen(emissions.add, onError: errors.add);
    addTearDown(sub.cancel);

    first.addError(StateError('boom'));
    second.add(2);
    first.add(1);
    await Future<void>.delayed(Duration.zero);

    expect(errors, hasLength(1));
    expect(emissions, [3]);
  });
}
