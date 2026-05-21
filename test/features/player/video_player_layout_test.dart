import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/player/presentation/layouts/video_player_layout.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_player_engine.dart';

void main() {
  Future<void> pumpLayout(
    WidgetTester tester, {
    required double width,
    required double height,
  }) async {
    final fake = FakePlayerEngine();
    addTearDown(() async {
      await fake.dispose();
    });
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF003366));
    await tester.pumpWidget(
      MaterialApp(
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
    );
    await tester.pumpAndSettle();
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
        MaterialApp(
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
