import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Haptics.wrapTap', () {
    testWidgets('returns null when action is null', (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      );
      final wrapped = Haptics.wrapTap(captured, null);
      expect(wrapped, isNull);
    });

    testWidgets('invokes the wrapped action', (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      );
      var calls = 0;
      final wrapped = Haptics.wrapTap(captured, () => calls += 1);
      wrapped!();
      wrapped();
      expect(calls, 2);
    });

    testWidgets(
      'still invokes the wrapped action when haptic is gated by reduced motion',
      (tester) async {
        await _withPlatform(TargetPlatform.iOS, () async {
          late BuildContext captured;
          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Builder(
                builder: (context) {
                  captured = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          );
          var calls = 0;
          final wrapped = Haptics.wrapTap(captured, () => calls += 1);
          wrapped!();
          expect(calls, 1);
        });
      },
    );

    testWidgets('still invokes the wrapped action on non-mobile platforms', (
      tester,
    ) async {
      await _withPlatform(TargetPlatform.macOS, () async {
        late BuildContext captured;
        await tester.pumpWidget(
          Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        );
        var ran = false;
        final wrapped = Haptics.wrapTap(captured, () => ran = true);
        wrapped!();
        expect(ran, isTrue);
      });
    });
  });

  group('Haptics selection/impactMedium/success/warning gating', () {
    final fireByName = <String, void Function(BuildContext)>{
      'selection': Haptics.selection,
      'impactMedium': Haptics.impactMedium,
      'success': Haptics.success,
      'warning': Haptics.warning,
    };

    for (final entry in fireByName.entries) {
      final name = entry.key;
      final fire = entry.value;

      testWidgets('$name is a no-op on non-mobile platforms', (tester) async {
        await _withPlatform(TargetPlatform.macOS, () async {
          final recorder = _PlatformRecorder();
          await tester.pumpWidget(
            _Harness(
              child: Builder(
                builder: (context) {
                  fire(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          );
          expect(recorder.hapticCalls, isEmpty);
          recorder.dispose();
        });
      });

      testWidgets('$name is a no-op when reduced motion is enabled', (
        tester,
      ) async {
        await _withPlatform(TargetPlatform.iOS, () async {
          final recorder = _PlatformRecorder();
          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _Harness(
                child: Builder(
                  builder: (context) {
                    fire(context);
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          );
          expect(recorder.hapticCalls, isEmpty);
          recorder.dispose();
        });
      });

      testWidgets(
        '$name fires HapticFeedback.vibrate on mobile with animations',
        (tester) async {
          await _withPlatform(TargetPlatform.iOS, () async {
            final recorder = _PlatformRecorder();
            await tester.pumpWidget(
              _Harness(
                child: Builder(
                  builder: (context) {
                    fire(context);
                    return const SizedBox.shrink();
                  },
                ),
              ),
            );
            expect(recorder.hapticCalls, hasLength(1));
            expect(
              recorder.hapticCalls.single.method,
              'HapticFeedback.vibrate',
            );
            recorder.dispose();
          });
        },
      );
    }
  });
}

Future<void> _withPlatform(
  TargetPlatform platform,
  Future<void> Function() body,
) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

class _Harness extends StatelessWidget {
  const _Harness({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      MaterialApp(home: Scaffold(body: child));
}

class _PlatformRecorder {
  _PlatformRecorder() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            hapticCalls.add(call);
          }
          return null;
        });
  }

  final List<MethodCall> hapticCalls = [];

  void dispose() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  }
}
