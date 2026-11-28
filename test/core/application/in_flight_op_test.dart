/// Unit tests for the result-sharing single-flight primitive.
library;

import 'dart:async';

import 'package:enjoy_player/core/application/in_flight_op.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InFlightOp slot', () {
    test(
      'pending is null when idle and exposes the slot while in flight',
      () async {
        final flight = InFlightOp<int>();
        expect(flight.pending, isNull);

        final gate = Completer<int>();
        final done = flight.run((_) => gate.future);
        expect(flight.pending, isNotNull);

        gate.complete(7);
        expect(await done, 7);
        expect(flight.pending, isNull);
      },
    );

    test('run returns the thunk value and clears the slot', () async {
      final flight = InFlightOp<int>();
      expect(await flight.run((_) async => 42), 42);
      expect(flight.pending, isNull);
    });

    test(
      'a joining caller shares the leader future without running the thunk',
      () async {
        final flight = InFlightOp<int>();
        final gate = Completer<int>();
        var started = 0;
        final leader = flight.run((_) {
          started++;
          return gate.future;
        });

        final joiner = flight.run((_) {
          started++;
          return Future<int>.value(99);
        });

        expect(started, 1);
        expect(flight.pending, isNotNull);

        gate.complete(42);
        expect(await leader, 42);
        expect(await joiner, 42);
        expect(flight.pending, isNull);
      },
    );

    test(
      'run rethrows the op error to leader and joiner, clearing the slot',
      () async {
        final flight = InFlightOp<int>();
        final gate = Completer<int>();

        final leader = flight.run((_) => gate.future);
        final joiner = flight.run((_) => Future<int>.value(1));
        gate.completeError(StateError('boom'));

        await expectLater(leader, throwsStateError);
        await expectLater(joiner, throwsStateError);
        expect(flight.pending, isNull);
      },
    );

    test('a settled op frees the slot for the next run', () async {
      final flight = InFlightOp<int>();
      expect(await flight.run((_) async => 1), 1);
      expect(await flight.run((_) async => 2), 2);
      expect(flight.pending, isNull);
    });

    test('the slot is claimed before the thunk starts', () async {
      final flight = InFlightOp<int>();
      final gate = Completer<int>();
      var pendingWhenThunkStarted = false;
      var reentrantRuns = 0;

      final leader = flight.run((_) {
        pendingWhenThunkStarted = flight.pending != null;
        unawaited(
          flight.run((_) {
            reentrantRuns++;
            return Future<int>.value(0);
          }),
        );
        return gate.future;
      });

      expect(pendingWhenThunkStarted, isTrue);
      expect(reentrantRuns, 0);

      gate.complete(1);
      expect(await leader, 1);
    });

    test('the release handle frees the slot while the op still runs', () async {
      final flight = InFlightOp<int>();
      final gate = Completer<int>();
      var pendingAfterRelease = true;

      final leader = flight.run((release) async {
        release();
        pendingAfterRelease = flight.pending != null;
        await gate.future;
        return 5;
      });

      expect(pendingAfterRelease, isFalse);
      expect(flight.pending, isNull);

      gate.complete(0);
      expect(await leader, 5);
      expect(flight.pending, isNull);
    });

    test(
      'a released slot can be re-claimed without the settling op clobbering it',
      () async {
        final flight = InFlightOp<int>();
        final firstGate = Completer<int>();
        final secondGate = Completer<int>();

        final first = flight.run((release) async {
          release();
          await firstGate.future;
          return 1;
        });

        final second = flight.run((_) => secondGate.future);
        expect(flight.pending, isNotNull);

        firstGate.complete(0);
        expect(await first, 1);
        expect(flight.pending, isNotNull);

        secondGate.complete(2);
        expect(await second, 2);
        expect(flight.pending, isNull);
      },
    );
  });
}
