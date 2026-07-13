import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/presentation/layouts/video_player_layout.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_player_engine.dart';

class _SessionPlayerController extends PlayerController {
  _SessionPlayerController(this._session);

  final PlaybackSession _session;

  @override
  PlaybackSession? build() => _session;
}

PlaybackSession _testSession() {
  final now = DateTime(2026, 1, 1);
  return PlaybackSession(
    mediaId: 'video-layout-test',
    dexieTargetType: 'Video',
    mediaType: 'video',
    mediaTitle: 'Layout test',
    durationSeconds: 120,
    currentTimeSeconds: 0,
    currentSegmentIndex: 0,
    language: 'en',
    startedAt: now,
    lastActiveAt: now,
  );
}

void main() {
  Future<void> pumpLayout(
    WidgetTester tester, {
    required double width,
    required double height,
    FakePlayerEngine? engine,
    List<Override> overrides = const [],
  }) async {
    final fake = engine ?? FakePlayerEngine();
    if (engine == null) {
      addTearDown(() async {
        await fake.dispose();
      });
    }
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF003366));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerEngineTestDoubleProvider.overrideWithValue(fake),
          ...overrides,
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: scheme,
            extensions: [EnjoyThemeTokens.build(scheme)],
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                height: height,
                child: VideoPlayerLayout(
                  engine: fake,
                  transcript: const Text('TR_STUB'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('VideoPlayerLayout shows transcript beside video when wide', (
    tester,
  ) async {
    await pumpLayout(tester, width: 900, height: 600);
    expect(find.text('TR_STUB'), findsOneWidget);
    expect(find.byType(Row), findsWidgets);
  });

  testWidgets('VideoPlayerLayout stacks transcript when narrow', (
    tester,
  ) async {
    await pumpLayout(tester, width: 500, height: 700);
    expect(find.text('TR_STUB'), findsOneWidget);
    expect(find.byType(Column), findsWidgets);
  });

  testWidgets(
    'VideoPlayerLayout uses 16:9 stacked stage below transcript breakpoint',
    (tester) async {
      await pumpLayout(tester, width: 719, height: 700);
      final layout = find.byType(VideoPlayerLayout);
      expect(
        find.descendant(of: layout, matching: find.byType(AspectRatio)),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'VideoPlayerLayout uses side-by-side above transcript breakpoint',
    (tester) async {
      await pumpLayout(tester, width: 721, height: 700);
      final layout = find.byType(VideoPlayerLayout);
      expect(
        find.descendant(of: layout, matching: find.byType(AspectRatio)),
        findsNothing,
      );
      expect(
        find.descendant(of: layout, matching: find.byType(Row)),
        findsWidgets,
      );
    },
  );

  testWidgets('tapping local video stage toggles play/pause', (tester) async {
    final fake = FakePlayerEngine();
    addTearDown(() async {
      await fake.dispose();
    });
    await pumpLayout(
      tester,
      width: 900,
      height: 600,
      engine: fake,
      overrides: [
        playerControllerProvider.overrideWith(
          () => _SessionPlayerController(_testSession()),
        ),
      ],
    );

    expect(fake.playOrPauseCallCount, 0);
    // Find the stage tap GestureDetector: the one wrapping a transparent
    // ColoredBox with onTap set and no horizontal drag handler. Match by
    // widget type + predicate rather than fragile tree traversal.
    final stageTap = find.byWidgetPredicate(
      (w) =>
          w is GestureDetector &&
          w.onTap != null &&
          w.onHorizontalDragUpdate == null &&
          w.behavior == HitTestBehavior.opaque,
    );
    await tester.tap(stageTap.first);
    await tester.pump();
    expect(fake.playOrPauseCallCount, 1);
  });

  /// Mirrors [ExpandedPlayerChromeBody] narrow video layout: [VideoPlayerLayout]
  /// fills the stack; paused title chrome is an overlay and must not change the
  /// 16:9 stage geometry.
  testWidgets(
    'Stacked title overlay does not move 16:9 stage when shown (expanded player pattern)',
    (tester) async {
      final fake = FakePlayerEngine();
      addTearDown(() async {
        await fake.dispose();
      });
      final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF003366));
      final overlayVisible = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: scheme,
              extensions: [EnjoyThemeTokens.build(scheme)],
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Center(
              child: SizedBox(
                width: 390,
                height: 844,
                child: MediaQuery(
                  data: const MediaQueryData(
                    size: Size(390, 844),
                    padding: EdgeInsets.only(top: 47, bottom: 34),
                  ),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: overlayVisible,
                    builder: (context, showOverlay, _) {
                      return Scaffold(
                        body: Stack(
                          fit: StackFit.expand,
                          children: [
                            VideoPlayerLayout(
                              engine: fake,
                              transcript: const Text('TR_STUB'),
                            ),
                            if (showOverlay)
                              Align(
                                alignment: Alignment.topCenter,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.55),
                                        Colors.black.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                  child: const SafeArea(
                                    bottom: false,
                                    left: false,
                                    right: false,
                                    child: SizedBox(
                                      height: kToolbarHeight,
                                      child: Row(
                                        children: [
                                          SizedBox(width: 48, height: 48),
                                          Expanded(child: Text('Title')),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final layout = find.byType(VideoPlayerLayout);
      final aspectFinder = find.descendant(
        of: layout,
        matching: find.byType(AspectRatio),
      );
      expect(aspectFinder, findsOneWidget);
      final rectHidden = tester.getRect(aspectFinder);

      overlayVisible.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final rectShown = tester.getRect(aspectFinder);
      expect(rectShown, rectHidden);
    },
  );
}
