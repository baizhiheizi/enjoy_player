import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/transcript/application/auto_translate_line_queue.dart';

void main() {
  late AutoTranslateLineQueue queue;
  late List<(int, bool)> started;
  late Set<int> failed;
  late int anchor;
  late List<Set<int>> published;

  setUp(() {
    started = <(int, bool)>[];
    failed = <int>{};
    anchor = 0;
    published = <Set<int>>[];
    queue = AutoTranslateLineQueue(
      isLineFailed: failed.contains,
      startTranslate: (lineIndex, {required bool forceRefresh}) {
        started.add((lineIndex, forceRefresh));
        queue.markInFlight(lineIndex);
      },
      currentCueAnchor: () => anchor,
      publishInFlight: published.add,
    );
  });

  test('enqueue keeps insertion order and ignores a duplicate', () {
    queue.enqueue(3);
    queue.enqueue(7);

    expect(queue.waitingOrder, [3, 7]);

    queue.enqueue(3);

    expect(queue.waitingOrder, [3, 7]);
  });

  test('enqueue with preferFront puts the line ahead of earlier requests', () {
    queue.enqueue(3);
    queue.enqueue(7);

    queue.enqueue(5, preferFront: true);

    expect(queue.waitingOrder, [5, 3, 7]);
  });

  test('reprioritize orders the waiting lines by distance to the anchor', () {
    queue.enqueue(2);
    queue.enqueue(10);
    queue.enqueue(6);

    queue.reprioritize(anchor: 8);

    expect(queue.waitingOrder, [6, 10, 2]);
  });

  test('reprioritize drops lines the user seeked away from', () {
    queue.enqueue(2);
    queue.enqueue(60);

    queue.reprioritize(anchor: 0);

    expect(queue.waitingOrder, [2]);
  });

  test('reprioritize reads the playback anchor when none is given', () {
    anchor = 40;
    queue.enqueue(38);
    queue.enqueue(90);

    queue.reprioritize();

    expect(queue.waitingOrder, [38]);
  });

  test('drain starts waiting lines up to the concurrency limit', () {
    queue.enqueue(1);
    queue.enqueue(2);
    queue.enqueue(3);

    queue.markInFlight(0);
    queue.markInFlight(9);
    queue.drain();

    expect(started, isEmpty);

    queue.releaseInFlight(0);
    queue.drain();

    expect(started.map((e) => e.$1), [1]);
  });

  test('drain skips lines that already failed', () {
    failed.add(2);
    queue.enqueue(1);
    queue.enqueue(2);
    queue.enqueue(3);

    queue.drain();

    expect(started.map((e) => e.$1), [1, 3]);
  });

  test('drain starts a force-refreshed line with the force flag', () {
    queue.enqueue(4);
    queue.markForceRefresh(4);

    queue.drain();

    expect(started, [(4, true)]);
    expect(queue.isForceRefreshPending(4), isTrue);
  });

  test('consumeForceRefresh reports and clears the mark', () {
    queue.markForceRefresh(2);

    expect(queue.consumeForceRefresh(2), isTrue);
    expect(queue.consumeForceRefresh(2), isFalse);
    expect(queue.isForceRefreshPending(2), isFalse);
  });

  test('markInFlight and releaseInFlight publish the in-flight set', () {
    queue.markInFlight(1);
    expect(published.last, {1});

    queue.releaseInFlight(1);
    expect(published.last, isEmpty);
  });

  test('clear empties every set and publishes the empty in-flight set', () {
    queue.markInFlight(1);
    queue.enqueue(2);
    queue.markForceRefresh(2);

    queue.clear();

    expect(queue.waitingOrder, isEmpty);
    expect(queue.isInFlight(1), isFalse);
    expect(queue.isForceRefreshPending(2), isFalse);
    expect(published.last, isEmpty);
  });

  test('clearWaiting keeps the in-flight and force-refresh sets', () {
    queue.markInFlight(1);
    queue.enqueue(2);
    queue.markForceRefresh(2);

    queue.clearWaiting();

    expect(queue.waitingOrder, isEmpty);
    expect(queue.isInFlight(1), isTrue);
    expect(queue.isForceRefreshPending(2), isTrue);
  });
}
