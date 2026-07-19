import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';
import 'package:enjoy_player/features/player/application/player_surface_registry.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_surface_host.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_surface_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_player_engine.dart';

class _KeyedSurfaceEngine extends FakePlayerEngine {
  final surfaceKey = GlobalKey();

  @override
  Widget buildVideoStage({
    required BuildContext context,
    required double maxWidth,
    required double maxHeight,
  }) {
    return ColoredBox(key: surfaceKey, color: Colors.black);
  }
}

void main() {
  testWidgets(
    'target detach and reattach never reparents keyed engine surface',
    (tester) async {
      final engine = _KeyedSurfaceEngine();
      addTearDown(engine.dispose);
      final enabled = ValueNotifier<bool>(true);
      addTearDown(enabled.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [playerEngineTestDoubleProvider.overrideWithValue(engine)],
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: SizedBox(
                      width: 320,
                      height: 180,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: enabled,
                        builder: (context, value, _) {
                          return PlayerSurfaceTarget(
                            id: PlayerSurfaceIds.vocabularyClip,
                            enabled: value,
                            child: const ColoredBox(color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ),
                  const PlayerSurfaceHost(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final originalElement = engine.surfaceKey.currentContext;
      expect(originalElement, isNotNull);

      enabled.value = false;
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(engine.surfaceKey.currentContext, same(originalElement));

      enabled.value = true;
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(engine.surfaceKey.currentContext, same(originalElement));
    },
  );
}
