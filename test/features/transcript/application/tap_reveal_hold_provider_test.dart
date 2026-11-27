import 'package:enjoy_player/features/transcript/application/tap_reveal_hold_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_blur.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TapRevealHoldCtrl', () {
    test('setHold stores the tapped cue with the injected clock expiry and '
        'clears when the hold elapses', () {
      fakeAsync((async) {
        final basis = DateTime.utc(2026, 1, 1, 12);
        final container = ProviderContainer(
          overrides: [
            tapRevealHoldCtrlProvider.overrideWith(
              () => TapRevealHoldCtrl.withClock(() => basis),
            ),
          ],
        );
        addTearDown(container.dispose);
        container.listen(tapRevealHoldCtrlProvider('m1'), (_, __) {});

        final ctrl = container.read(tapRevealHoldCtrlProvider('m1').notifier);
        ctrl.setHold(cueId: 'cue-1', holdSeconds: 30);

        expect(
          container.read(tapRevealHoldCtrlProvider('m1')),
          TapRevealHold(
            cueId: 'cue-1',
            expiresAt: basis.add(const Duration(seconds: 30)),
          ),
        );

        async.elapse(const Duration(seconds: 30));
        expect(container.read(tapRevealHoldCtrlProvider('m1')), isNull);
      });
    });

    test('a replacement hold swaps the cue and cancels the prior timer', () {
      fakeAsync((async) {
        final basis = DateTime.utc(2026, 1, 1, 12);
        var now = basis;
        final container = ProviderContainer(
          overrides: [
            tapRevealHoldCtrlProvider.overrideWith(
              () => TapRevealHoldCtrl.withClock(() => now),
            ),
          ],
        );
        addTearDown(container.dispose);
        container.listen(tapRevealHoldCtrlProvider('m1'), (_, __) {});

        final ctrl = container.read(tapRevealHoldCtrlProvider('m1').notifier);
        ctrl.setHold(cueId: 'cue-1', holdSeconds: 30);
        async.elapse(const Duration(seconds: 10));
        now = basis.add(const Duration(seconds: 10));
        ctrl.setHold(cueId: 'cue-2', holdSeconds: 30);

        expect(
          container.read(tapRevealHoldCtrlProvider('m1')),
          TapRevealHold(
            cueId: 'cue-2',
            expiresAt: basis.add(const Duration(seconds: 40)),
          ),
        );

        async.elapse(const Duration(seconds: 20));
        expect(
          container.read(tapRevealHoldCtrlProvider('m1')),
          isA<TapRevealHold>().having((h) => h.cueId, 'cueId', 'cue-2'),
        );

        async.elapse(const Duration(seconds: 10));
        expect(container.read(tapRevealHoldCtrlProvider('m1')), isNull);
      });
    });

    test('holdSeconds <= 0 degrades to clear and leaves no pending timer', () {
      fakeAsync((async) {
        final basis = DateTime.utc(2026, 1, 1, 12);
        final container = ProviderContainer(
          overrides: [
            tapRevealHoldCtrlProvider.overrideWith(
              () => TapRevealHoldCtrl.withClock(() => basis),
            ),
          ],
        );
        addTearDown(container.dispose);
        container.listen(tapRevealHoldCtrlProvider('m1'), (_, __) {});

        final ctrl = container.read(tapRevealHoldCtrlProvider('m1').notifier);
        ctrl.setHold(cueId: 'cue-1', holdSeconds: 30);
        ctrl.setHold(cueId: 'cue-2', holdSeconds: 0);
        expect(container.read(tapRevealHoldCtrlProvider('m1')), isNull);

        ctrl.setHold(cueId: 'cue-3', holdSeconds: 30);
        ctrl.setHold(cueId: 'cue-4', holdSeconds: -5);
        expect(container.read(tapRevealHoldCtrlProvider('m1')), isNull);

        async.elapse(const Duration(seconds: 60));
        expect(container.read(tapRevealHoldCtrlProvider('m1')), isNull);
      });
    });

    test('clear resets the hold immediately and cancels the pending timer', () {
      fakeAsync((async) {
        final basis = DateTime.utc(2026, 1, 1, 12);
        final container = ProviderContainer(
          overrides: [
            tapRevealHoldCtrlProvider.overrideWith(
              () => TapRevealHoldCtrl.withClock(() => basis),
            ),
          ],
        );
        addTearDown(container.dispose);
        container.listen(tapRevealHoldCtrlProvider('m1'), (_, __) {});

        final ctrl = container.read(tapRevealHoldCtrlProvider('m1').notifier);
        ctrl.setHold(cueId: 'cue-1', holdSeconds: 30);
        ctrl.clear();

        expect(container.read(tapRevealHoldCtrlProvider('m1')), isNull);
        async.elapse(const Duration(seconds: 60));
        expect(container.read(tapRevealHoldCtrlProvider('m1')), isNull);
      });
    });

    test('clear with no hold set is a no-op', () {
      fakeAsync((async) {
        final basis = DateTime.utc(2026, 1, 1, 12);
        final container = ProviderContainer(
          overrides: [
            tapRevealHoldCtrlProvider.overrideWith(
              () => TapRevealHoldCtrl.withClock(() => basis),
            ),
          ],
        );
        addTearDown(container.dispose);
        container.listen(tapRevealHoldCtrlProvider('m1'), (_, __) {});

        container.read(tapRevealHoldCtrlProvider('m1').notifier).clear();

        expect(container.read(tapRevealHoldCtrlProvider('m1')), isNull);
        async.elapse(const Duration(seconds: 5));
        expect(container.read(tapRevealHoldCtrlProvider('m1')), isNull);
      });
    });

    test('the read-only projection mirrors the controller hold', () {
      fakeAsync((async) {
        final basis = DateTime.utc(2026, 1, 1, 12);
        final container = ProviderContainer(
          overrides: [
            tapRevealHoldCtrlProvider.overrideWith(
              () => TapRevealHoldCtrl.withClock(() => basis),
            ),
          ],
        );
        addTearDown(container.dispose);
        container.listen(tapRevealHoldProvider('m2'), (_, __) {});

        expect(container.read(tapRevealHoldProvider('m2')), isNull);

        container
            .read(tapRevealHoldCtrlProvider('m2').notifier)
            .setHold(cueId: 'cue-9', holdSeconds: 15);
        expect(
          container.read(tapRevealHoldProvider('m2')),
          TapRevealHold(
            cueId: 'cue-9',
            expiresAt: basis.add(const Duration(seconds: 15)),
          ),
        );

        async.elapse(const Duration(seconds: 15));
        expect(container.read(tapRevealHoldProvider('m2')), isNull);
      });
    });
  });
}
