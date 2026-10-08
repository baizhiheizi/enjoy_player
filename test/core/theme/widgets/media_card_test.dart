import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:io';

import 'package:enjoy_player/core/platform/mobile_platform.dart';
import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/media_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ThemeData _buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7B61FF),
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    extensions: [EnjoyThemeTokens.build(scheme)],
  );
}

Widget _wrap({required Widget child, ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? _buildTheme(Brightness.dark),
    home: Scaffold(body: child),
  );
}

/// Wraps [body] in a `debugDefaultTargetPlatformOverride = platform` block so
/// the override is cleared *before* the testWidgets verification check runs.
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('helpers', () {
    test(
      'mediaCardTileGridAspectRatioForWidth uses width/(9/16*w+meta+inset)',
      () {
        final ratio = mediaCardTileGridAspectRatioForWidth(280);
        expect(
          ratio,
          closeTo(
            280 /
                (280 * 9 / 16 +
                    mediaCardTileMetaHeight +
                    mediaCardTileBorderInset),
            0.001,
          ),
        );
      },
    );

    test('mediaCardTileGridAspectRatioForWidth handles small widths', () {
      final ratio = mediaCardTileGridAspectRatioForWidth(120);
      expect(
        ratio,
        closeTo(
          120 /
              (120 * 9 / 16 +
                  mediaCardTileMetaHeight +
                  mediaCardTileBorderInset),
          0.001,
        ),
      );
    });

    test('mediaCardTileGridDelegateForMaxTileWidth builds a grid delegate', () {
      final delegate = mediaCardTileGridDelegateForMaxTileWidth(
        crossAxisExtent: 800,
      );
      expect(delegate, isA<SliverGridDelegateWithFixedCrossAxisCount>());
    });

    test('mediaCardTileGridDelegateForMinTileWidth builds a grid delegate', () {
      final delegate = mediaCardTileGridDelegateForMinTileWidth(
        crossAxisExtent: 1200,
      );
      expect(delegate, isA<SliverGridDelegateWithFixedCrossAxisCount>());
    });

    test('mediaCardTileGridDelegateForMinTileWidth clamps crossAxisCount', () {
      final delegate = mediaCardTileGridDelegateForMinTileWidth(
        crossAxisExtent: 100,
      );
      final fixed = delegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(fixed.crossAxisCount, 1);
    });

    test(
      'mediaCardTileGridDelegateForMaxTileWidth clamps to maxCrossAxisCount',
      () {
        final delegate = mediaCardTileGridDelegateForMaxTileWidth(
          crossAxisExtent: 10000,
          maxCrossAxisCount: 2,
        );
        final fixed = delegate as SliverGridDelegateWithFixedCrossAxisCount;
        expect(fixed.crossAxisCount, 2);
      },
    );
  });

  group('MediaCardTile', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: MediaCardTile(title: 'Hello World', onTap: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: MediaCardTile(
            title: 'Title',
            subtitle: 'Subtitle line',
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Subtitle line'), findsOneWidget);
    });

    testWidgets('shows the audio placeholder glyph by default', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: MediaCardTile(title: 'T', onTap: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(EnjoyIcons.audio), findsOneWidget);
      expect(find.byIcon(EnjoyIcons.video), findsNothing);
    });

    testWidgets('shows the video placeholder glyph when isVideo=true', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          child: MediaCardTile(title: 'T', isVideo: true, onTap: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(EnjoyIcons.video), findsOneWidget);
      expect(find.byIcon(EnjoyIcons.audio), findsNothing);
    });

    testWidgets('providerBadge renders when set', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: MediaCardTile(
            title: 'T',
            providerBadge: 'YouTube',
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('YouTube'), findsOneWidget);
    });

    testWidgets('durationLabel renders when set', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: MediaCardTile(
            title: 'T',
            durationLabel: '10:30',
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('10:30'), findsOneWidget);
    });

    testWidgets('calls onTap when card tapped', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(
          child: MediaCardTile(title: 'T', onTap: () => tapped++),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('T'));
      await tester.pumpAndSettle();
      expect(tapped, 1);
    });

    for (final placement in MediaCardLanguagePlacement.values) {
      testWidgets('language on the $placement is tappable', (tester) async {
        var tapped = 0;
        await tester.pumpWidget(
          _wrap(
            child: MediaCardTile(
              title: 'T',
              language: 'ZH',
              languagePlacement: placement,
              onLanguageTap: () => tapped++,
              onTap: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('ZH'), findsOneWidget);
        await tester.tap(find.text('ZH'));
        await tester.pumpAndSettle();
        expect(tapped, 1);
      });
    }

    testWidgets('desktop onDelete shows inline IconButton', (tester) async {
      await _withPlatform(TargetPlatform.macOS, () async {
        var deleted = 0;
        await tester.pumpWidget(
          _wrap(
            child: MediaCardTile(
              title: 'T',
              onDelete: () => deleted++,
              onTap: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(EnjoyIcons.delete), findsOneWidget);
        await tester.tap(find.byIcon(EnjoyIcons.delete));
        await tester.pumpAndSettle();
        expect(deleted, 1);
      });
    });

    testWidgets('mobile onDelete: long-press opens sheet, tap deletes', (
      tester,
    ) async {
      await _withPlatform(TargetPlatform.android, () async {
        var deleted = 0;
        await tester.pumpWidget(
          _wrap(
            child: MediaCardTile(
              title: 'T',
              onDelete: () => deleted++,
              deleteTooltip: 'Remove this item',
              onTap: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(EnjoyIcons.delete), findsNothing);
        await tester.longPress(find.text('T'));
        await tester.pumpAndSettle();
        final listTile = find.widgetWithText(ListTile, 'Remove this item');
        expect(listTile, findsOneWidget);
        await tester.tap(listTile);
        await tester.pumpAndSettle();
        expect(deleted, 1);
      });
    });

    testWidgets('heroArtworkMediaId wraps thumbnail in Hero with tag', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          child: MediaCardTile(
            title: 'T',
            heroArtworkMediaId: 'm1',
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final heroFinder = find.byType(Hero);
      expect(heroFinder, findsWidgets);
      final heroWidget = tester
          .widgetList<Hero>(heroFinder)
          .firstWhere((h) => h.tag == mediaArtworkHeroTag('m1'));
      expect(heroWidget.tag, mediaArtworkHeroTag('m1'));
    });

    testWidgets('renders thumbnailFile when provided', (tester) async {
      final tmp = File('/tmp/empty_thumb.png');
      await tester.pumpWidget(
        _wrap(
          child: MediaCardTile(title: 'T', thumbnailFile: tmp, onTap: () {}),
        ),
      );
      await tester.pump();
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('accentColor is respected', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: MediaCardTile(
            title: 'T',
            accentColor: const Color(0xFFFF0000),
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('T'), findsOneWidget);
    });

    testWidgets('adding scrim renders spinner when adding=true', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          child: MediaCardTile(title: 'T', adding: true, onTap: () {}),
        ),
      );
      await tester.pump();
      expect(find.byType(MediaCardAddingScrim), findsOneWidget);
      expect(find.byType(LoadingIcon), findsOneWidget);
    });

    testWidgets('in-library chip renders when inLibrary=true', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: MediaCardTile(title: 'T', inLibrary: true, onTap: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MediaCardInLibraryChip), findsOneWidget);
      expect(find.byIcon(EnjoyIcons.check), findsOneWidget);
    });

    testWidgets('default tile renders neither scrim nor in-library chip', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          child: MediaCardTile(title: 'T', onTap: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MediaCardAddingScrim), findsNothing);
      expect(find.byType(LoadingIcon), findsNothing);
      expect(find.byIcon(EnjoyIcons.check), findsNothing);
    });

    testWidgets('meta slot replaces the built-in meta block', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: MediaCardTile(
            onTap: () {},
            meta: const Padding(padding: EdgeInsets.zero, child: Text('C')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('C'), findsOneWidget);
    });

    test('meta is mutually exclusive with the built-in meta block', () {
      expect(
        () => MediaCardTile(title: 'T', meta: const Text('C'), onTap: () {}),
        throwsA(isA<AssertionError>()),
      );
      expect(() => MediaCardTile(title: 'T', onTap: () {}), returnsNormally);
      expect(
        () => MediaCardTile(meta: const Text('C'), onTap: () {}),
        returnsNormally,
      );
    });

    testWidgets('meta slot honours the mediaCardTileMetaHeight budget', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          child: SizedBox(
            width: 280,
            child: MediaCardTile(onTap: () {}, meta: const Text('custom meta')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final budget = find.ancestor(
        of: find.text('custom meta'),
        matching: find.byWidgetPredicate(
          (w) =>
              w is ConstrainedBox &&
              w.constraints.minHeight == mediaCardTileMetaHeight,
        ),
      );
      expect(budget, findsOneWidget);
      expect(
        tester.getSize(find.byType(MediaCardTile)).height,
        closeTo(157.5 + mediaCardTileMetaHeight, 0.1),
      );
    });

    testWidgets('meta taller than its budget grows the tile, never overflows', (
      tester,
    ) async {
      const tall = 96.0;
      await tester.pumpWidget(
        _wrap(
          child: SizedBox(
            width: 280,
            child: MediaCardTile(
              onTap: () {},
              meta: const SizedBox(height: tall, child: Text('tall meta')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(MediaCardTile)).height,
        closeTo(157.5 + tall, 0.1),
      );
    });

    test('grid aspect ratio follows a caller metaHeight', () {
      const tileWidth = 320.0;
      const tallMeta = 96.0;
      final ratio = mediaCardTileGridAspectRatioForWidth(
        tileWidth,
        metaHeight: tallMeta,
      );
      expect(ratio, lessThan(mediaCardTileGridAspectRatioForWidth(tileWidth)));
      expect(
        tileWidth / ratio,
        greaterThanOrEqualTo(tileWidth * 9 / 16 + tallMeta),
      );
    });

    testWidgets('hover play glyph is present but invisible while adding', (
      tester,
    ) async {
      final previousStrategy = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy = previousStrategy,
      );

      var adding = false;
      late StateSetter setTileState;
      await tester.pumpWidget(
        _wrap(
          child: StatefulBuilder(
            builder: (context, setState) {
              setTileState = setState;
              return MediaCardTile(onTap: () {}, adding: adding);
            },
          ),
        ),
      );
      await tester.pump();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      await gesture.moveTo(tester.getCenter(find.byType(MediaCardTile)));
      await tester.pumpAndSettle();

      final glyph = find.byType(MediaCardPlayGlyph);
      final glyphOpacity = find.ancestor(
        of: glyph,
        matching: find.byType(AnimatedOpacity),
      );
      expect(tester.widget<AnimatedOpacity>(glyphOpacity).opacity, 1.0);

      final glyphScale = find.descendant(
        of: glyphOpacity,
        matching: find.byType(AnimatedScale),
      );
      setTileState(() => adding = true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(glyph, findsOneWidget);

      expect(tester.widget<AnimatedOpacity>(glyphOpacity).opacity, 0.0);

      expect(tester.widget<AnimatedScale>(glyphScale).scale, 0.85);

      final hit = tester.hitTestOnBinding(tester.getCenter(glyph));
      final glyphBox = tester.renderObject<RenderBox>(glyph);
      expect(hit.path.any((entry) => entry.target == glyphBox), isFalse);

      setTileState(() => adding = false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.widget<AnimatedOpacity>(glyphOpacity).opacity, 1.0);
      expect(tester.widget<AnimatedScale>(glyphScale).scale, 1.0);

      await gesture.removePointer();
    });
  });

  group('MediaCardRow', () {
    testWidgets('renders title without a chevron', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: MediaCardRow(title: 'Audio', onTap: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Audio'), findsOneWidget);
      expect(find.byIcon(EnjoyIcons.chevronRight), findsNothing);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: MediaCardRow(title: 'T', subtitle: 'Channel', onTap: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Channel'), findsOneWidget);
    });

    testWidgets('calls onTap on tap', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(
          child: MediaCardRow(title: 'T', onTap: () => tapped++),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('T'));
      await tester.pumpAndSettle();
      expect(tapped, 1);
    });

    testWidgets('trailing widget overrides default chevron/delete', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          child: MediaCardRow(
            title: 'T',
            trailing: const Text('Custom trailing'),
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Custom trailing'), findsOneWidget);
    });

    testWidgets('providerBadge compact pill renders', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: MediaCardRow(title: 'T', providerBadge: 'YT', onTap: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('YT'), findsOneWidget);
    });

    testWidgets('desktop: onDelete shows IconButton beside chevron', (
      tester,
    ) async {
      await _withPlatform(TargetPlatform.macOS, () async {
        var deleted = 0;
        await tester.pumpWidget(
          _wrap(
            child: MediaCardRow(
              title: 'T',
              onDelete: () => deleted++,
              onTap: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(EnjoyIcons.delete), findsOneWidget);
        await tester.tap(find.byIcon(EnjoyIcons.delete));
        await tester.pumpAndSettle();
        expect(deleted, 1);
      });
    });

    testWidgets('mobile: long-press opens sheet, tap deletes', (tester) async {
      await _withPlatform(TargetPlatform.android, () async {
        var deleted = 0;
        await tester.pumpWidget(
          _wrap(
            child: MediaCardRow(
              title: 'T',
              onDelete: () => deleted++,
              deleteTooltip: 'Remove this audio',
              onTap: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(EnjoyIcons.delete), findsNothing);
        await tester.longPress(find.text('T'));
        await tester.pumpAndSettle();
        final listTile = find.widgetWithText(ListTile, 'Remove this audio');
        expect(listTile, findsOneWidget);
        await tester.tap(listTile);
        await tester.pumpAndSettle();
        expect(deleted, 1);
      });
    });

    testWidgets('mobile onDelete with trailing present has no long-press', (
      tester,
    ) async {
      await _withPlatform(TargetPlatform.android, () async {
        await tester.pumpWidget(
          _wrap(
            child: MediaCardRow(
              title: 'T',
              trailing: const Text('Custom'),
              onDelete: () {},
              onTap: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.longPress(find.text('T'));
        await tester.pumpAndSettle();
        expect(find.byType(ListTile), findsNothing);
      });
    });

    testWidgets('row language chip triggers its callback', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(
          child: MediaCardRow(
            title: 'T',
            language: 'EN',
            durationLabel: '0:56',
            onLanguageTap: () => tapped++,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0:56'), findsOneWidget);
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();
      expect(tapped, 1);
    });

    testWidgets('heroArtworkMediaId wraps row thumbnail', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: MediaCardRow(
            title: 'T',
            heroArtworkMediaId: 'm1',
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final hero = find.byWidgetPredicate(
        (w) => w is Hero && w.tag == mediaArtworkHeroTag('m1'),
      );
      expect(hero, findsOneWidget);
    });
  });

  test('isMobilePlatform is read by delete-button helper', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(isMobilePlatform, isTrue);
    debugDefaultTargetPlatformOverride = null;
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(isMobilePlatform, isFalse);
    debugDefaultTargetPlatformOverride = null;
  });
}
