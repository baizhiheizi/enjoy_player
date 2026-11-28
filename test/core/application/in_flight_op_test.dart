/// Unit tests for the result-sharing single-flight primitive.
library;

import 'dart:async';

import 'package:enjoy_player/core/application/in_flight_op.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InFlightOp slot', () {
    test(
      'pending is null when idle and exposes the op future in flight',
      () async {
        final flight = InFlightOp<int>();
        expect(flight.pending, isNull);

        final gate = Completer<int>();
        final done = flight.run(() => gate.future);
        expect(flight.pending, same(gate.future));

        gate.complete(7);
        await done;
        expect(flight.pending, isNull);
      },
    );

    test('run returns the thunk value and clears the slot', () async {
      final flight = InFlightOp<int>();
      expect(await flight.run(() async => 42), 42);
      expect(flight.pending, isNull);
    });

    test(
      'a joining caller shares the leader future without running the thunk',
      () async {
        final flight = InFlightOp<int>();
        final gate = Completer<int>();
        var started = 0;
        final leader = flight.run(() {
          started++;
          return gate.future;
        });

        final joiner = flight.run(() {
          started++;
          return Future<int>.value(99);
        });

        expect(started, 1);
        expect(flight.pending, same(gate.future));

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

        final leader = flight.run(() => gate.future);
        final joiner = flight.run(() => Future<int>.value(1));
        gate.completeError(StateError('boom'));

        await expectLater(leader, throwsStateError);
        await expectLater(joiner, throwsStateError);
        expect(flight.pending, isNull);
      },
    );

    test('a settled op frees the slot for the next run', () async {
      final flight = InFlightOp<int>();
      expect(await flight.run(() async => 1), 1);
      expect(await flight.run(() async => 2), 2);
      expect(flight.pending, isNull);
    });
  });
}
