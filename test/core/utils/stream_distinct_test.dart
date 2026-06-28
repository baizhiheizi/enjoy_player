import 'dart:async';

import 'package:enjoy_player/core/utils/stream_distinct.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StreamDistinctExt', () {
    test('forwards first value', () async {
      final source = Stream<int>.fromIterable(const [1]);
      final out = await source.distinctBy((a, b) => a == b).toList();
      expect(out, [1]);
    });

    test('drops values equal to last forwarded', () async {
      final source = Stream<int>.fromIterable(const [1, 1, 1, 2, 2, 3, 3]);
      final out = await source.distinctBy((a, b) => a == b).toList();
      expect(out, [1, 2, 3]);
    });

    test('forwards all values when none equal the previous', () async {
      final source = Stream<int>.fromIterable(const [1, 2, 3, 4]);
      final out = await source.distinctBy((a, b) => a == b).toList();
      expect(out, [1, 2, 3, 4]);
    });

    test('uses caller-provided equality (structural)', () async {
      // Two logically-equal list-of-ints; identity differs because each `[]`
      // literal allocates a new instance. The default `==` on `List` would
      // see them as different — the extension's `equals` callback decides.
      final source = Stream<List<int>>.fromIterable([
        const [1, 2, 3],
        const [1, 2, 3],
        const [4, 5],
        const [1, 2, 3],
      ]);
      final out = await source.distinctBy((a, b) {
        if (a.length != b.length) return false;
        for (var i = 0; i < a.length; i++) {
          if (a[i] != b[i]) return false;
        }
        return true;
      }).toList();
      expect(out.length, 3);
      expect(out[0], [1, 2, 3]);
      expect(out[1], [4, 5]);
      expect(out[2], [1, 2, 3]);
    });

    test('keeps dedupe state per subscriber', () async {
      // Two independent subscribers on the same source stream must each see
      // every emission — dedupe state is not shared.
      final controller = StreamController<int>.broadcast();
      final aFut = controller.stream.distinctBy((p, c) => p == c).toList();
      final bFut = controller.stream.distinctBy((p, c) => p == c).toList();
      controller
        ..add(1)
        ..add(1)
        ..add(2)
        ..close();
      final a = await aFut;
      final b = await bFut;
      expect(a, [1, 2]);
      expect(b, [1, 2]);
    });

    test('propagates errors and stays open for the next value', () async {
      final controller = StreamController<int>();
      final out = <int>[];
      final sub = controller.stream
          .distinctBy((p, c) => p == c)
          .listen(out.add, onError: (e) => out.add(-1));
      controller
        ..add(1)
        ..add(2)
        ..addError('boom')
        ..add(3);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      await controller.close();
      expect(out, [1, 2, -1, 3]);
    });
  });
}
