import 'package:enjoy_player/core/window/window_fullscreen_provider.dart';
import 'package:enjoy_player/features/player/application/player_collapse.dart';
import 'package:enjoy_player/features/player/application/player_ui_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _RecordingFullscreen extends WindowFullscreen {
  var setFullscreenCalled = false;

  @override
  bool build() => true;

  @override
  Future<void> setFullscreen(bool value) async {
    setFullscreenCalled = true;
    state = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'collapseExpandedPlayer exits fullscreen, collapses UI, pops route',
    (tester) async {
      final fullscreen = _RecordingFullscreen();
      late ProviderContainer container;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Consumer(
              builder: (context, ref, _) {
                return ElevatedButton(
                  onPressed: () => context.push('/player/test-media'),
                  child: const Text('open'),
                );
              },
            ),
          ),
          GoRoute(
            path: '/player/:mediaId',
            builder: (context, state) {
              return Consumer(
                builder: (context, ref, _) {
                  container = ProviderScope.containerOf(context);
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () => collapseExpandedPlayer(ref, context),
                      child: const Text('collapse'),
                    ),
                  );
                },
              );
            },
          ),
        ],
      );

      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [windowFullscreenProvider.overrideWith(() => fullscreen)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/player/test-media');

      container.read(playerUiProvider.notifier).expand();
      expect(container.read(playerUiProvider).mode, PlayerChromeMode.expanded);

      await tester.tap(find.text('collapse'));
      await tester.pumpAndSettle();

      expect(fullscreen.setFullscreenCalled, isTrue);
      expect(container.read(playerUiProvider).mode, PlayerChromeMode.mini);
      expect(router.state.uri.path, '/');
    },
  );
}
