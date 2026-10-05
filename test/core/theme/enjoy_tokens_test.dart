import 'package:enjoy_player/core/theme/colors.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnjoyThemeTokens.build', () {
    test('produces expected defaults from a dark ColorScheme', () {
      const scheme = ColorScheme.dark();
      final tokens = EnjoyThemeTokens.build(scheme);

      expect(tokens.space4, 4);
      expect(tokens.space8, 8);
      expect(tokens.space12, 12);
      expect(tokens.space16, 16);
      expect(tokens.space20, 20);
      expect(tokens.space24, 24);
      expect(tokens.space32, 32);
      expect(tokens.space40, 40);
      expect(tokens.space48, 48);

      expect(tokens.radiusSm, 8);
      expect(tokens.radiusMd, 12);
      expect(tokens.radiusLg, 16);
      expect(tokens.radiusXl, 22);
      expect(tokens.radiusFull, 999);
      expect(tokens.radiusXs, 6);
      expect(tokens.radius2xl, 30);

      expect(tokens.elevationNone, 0);
      expect(tokens.elevationCard, 1);
      expect(tokens.elevationSheet, 3);
      expect(tokens.elevationModal, 8);
      expect(tokens.elevationBar, 2);
      expect(tokens.elevationSurface, 1);

      expect(tokens.breakpointCompact, 600);
      expect(tokens.breakpointRail, 900);
      expect(tokens.breakpointTranscriptSideBySide, 720);

      expect(tokens.motionFast, const Duration(milliseconds: 160));
      expect(tokens.motionStandard, const Duration(milliseconds: 280));
      expect(tokens.motionEnter, const Duration(milliseconds: 260));
      expect(tokens.motionExit, const Duration(milliseconds: 160));
      expect(tokens.motionMedium, const Duration(milliseconds: 220));

      expect(tokens.echoActive, AppColors.youDark);
      expect(tokens.blurActive, AppColors.inkDark);
      expect(tokens.scoreGood, AppColors.ink2Dark);
      expect(tokens.scoreWarn, AppColors.ink2Dark);
      expect(tokens.scoreBad, AppColors.dangerDark);
      expect(tokens.scoreGoodContainer, AppColors.sunkDark);
      expect(tokens.scoreWarnContainer, AppColors.sunkDark);
      expect(tokens.scoreBadContainer, AppColors.sunkDark);
      expect(tokens.accentSoft, AppColors.brandSoftDark);
      expect(tokens.accentInk, AppColors.brandInkDark);
      expect(tokens.intelligenceInk, AppColors.originalInkDark);
      expect(tokens.echoInk, AppColors.youInkDark);
      expect(tokens.ccBadge, scheme.primary);
      expect(tokens.contentMaxWidth, 780);
      expect(tokens.formMaxWidth, 680);
      expect(tokens.hubMaxWidth, 840);
      expect(tokens.pageGutterCompact, 16);
      expect(tokens.pageGutter, 40);
      expect(tokens.miniBarBlurSigma, 24);
      expect(tokens.sidebarWidth, 244);
      expect(tokens.sidebarBrandHeight, 52);
      expect(tokens.transportHeight, 88);
      expect(tokens.heroTitleLetterSpacing, -0.9);
      expect(tokens.bottomNavHeight, 64);
      expect(tokens.desktopGutter, 24);
      expect(tokens.modalMaxWidth, 400);
      expect(tokens.modalMaxWidthLarge, 560);
      expect(tokens.focusRingWidth, 2);
      expect(tokens.canvas, AppColors.groundDark);
      expect(tokens.card, AppColors.paperDark);
      expect(tokens.popover, AppColors.raisedDark);
      expect(tokens.hairline, AppColors.lineDark);
      expect(tokens.fill, AppColors.sunkDark);
      expect(tokens.textFaint, AppColors.ink3Dark);
      expect(tokens.logoStart, AppColors.logoStart);
      expect(tokens.logoEnd, AppColors.logoEnd);
      expect(tokens.shellInset, 0);
      expect(tokens.panelRadius, 0);
      expect(tokens.controlHeightSm, 32);
      expect(tokens.controlHeight, 40);
      expect(tokens.controlHeightLg, 50);
      expect(tokens.shadowLift, isNotEmpty);
      expect(tokens.shadowFloat, isNotEmpty);
      expect(tokens.shadowPopover, isNotEmpty);
      expect(tokens.logo.colors, [AppColors.logoStart, AppColors.logoEnd]);

      expect(
        tokens.transcriptLinePadding,
        const EdgeInsets.symmetric(horizontal: 16),
      );
    });

    test('dark glass aliases the Duet paper and line surfaces', () {
      final tokens = EnjoyThemeTokens.build(const ColorScheme.dark());

      expect(tokens.glassTint, AppColors.paperDark);
      expect(tokens.glassBorder, AppColors.lineDark);
      expect(tokens.topHighlight, Colors.transparent);
    });

    test('light palette uses porcelain inks and denser glass', () {
      const scheme = ColorScheme.light();
      final tokens = EnjoyThemeTokens.build(scheme);

      expect(tokens.accentInk, AppColors.brandInkLight);
      expect(tokens.intelligenceInk, AppColors.originalInkLight);
      expect(tokens.echoInk, AppColors.youInkLight);
      expect(tokens.scoreGood, AppColors.ink2Light);
      expect(tokens.glassTint, AppColors.paperLight);
      expect(tokens.glassBorder, AppColors.lineLight);
      expect(tokens.canvas, AppColors.groundLight);
      expect(tokens.card, AppColors.paperLight);
      expect(tokens.radiusSm, 8);
      expect(tokens.space48, 48);
    });
  });

  group('EnjoyThemeTokens.of', () {
    testWidgets('returns extension when registered in theme', (tester) async {
      const scheme = ColorScheme.dark();
      final tokens = EnjoyThemeTokens.build(scheme);
      late EnjoyThemeTokens resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: scheme, extensions: [tokens]),
          home: Builder(
            builder: (context) {
              resolved = EnjoyThemeTokens.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolved.space4, tokens.space4);
      expect(resolved.radiusMd, tokens.radiusMd);
    });

    testWidgets('falls back to build when no extension registered', (
      tester,
    ) async {
      const scheme = ColorScheme.dark();
      late EnjoyThemeTokens resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: scheme),
          home: Builder(
            builder: (context) {
              resolved = EnjoyThemeTokens.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolved.space4, 4);
      expect(resolved.ccBadge, scheme.primary);
    });
  });

  group('EnjoyThemeTokens.copyWith', () {
    test('returns identical values when no overrides given', () {
      final tokens = EnjoyThemeTokens.build(const ColorScheme.dark());
      final copy = tokens.copyWith();

      expect(copy.space4, tokens.space4);
      expect(copy.radiusSm, tokens.radiusSm);
      expect(copy.motionFast, tokens.motionFast);
      expect(copy.echoActive, tokens.echoActive);
      expect(copy.focusRingWidth, tokens.focusRingWidth);
    });

    test('overrides selected fields and preserves the rest', () {
      final tokens = EnjoyThemeTokens.build(const ColorScheme.dark());
      final copy = tokens.copyWith(
        space4: 100,
        radiusSm: 42,
        motionFast: const Duration(milliseconds: 999),
        echoActive: const Color(0xFF112233),
        bottomNavHeight: 200,
        desktopGutter: 99,
        modalMaxWidth: 500,
        modalMaxWidthLarge: 700,
        focusRingWidth: 5,
        contentMaxWidth: 800,
        formMaxWidth: 750,
        hubMaxWidth: 900,
        pageGutterCompact: 32,
        pageGutter: 48,
        miniBarBlurSigma: 40,
        sidebarWidth: 300,
        sidebarBrandHeight: 80,
        transportHeight: 120,
        heroTitleLetterSpacing: -2.0,
        glassTint: const Color(0xAA000000),
        glassBorder: const Color(0xBB111111),
        gradientStart: const Color(0xFF222222),
        gradientEnd: const Color(0xFF333333),
        blurActive: const Color(0xFF445566),
        scoreGood: const Color(0xFF119955),
        scoreWarn: const Color(0xFF996611),
        scoreBad: const Color(0xFF991122),
        scoreGoodContainer: const Color(0x33119955),
        scoreWarnContainer: const Color(0x33996611),
        scoreBadContainer: const Color(0x33991122),
        accentSoft: const Color(0x337B61FF),
        ccBadge: const Color(0xFF778899),
        transcriptLinePadding: const EdgeInsets.all(20),
        space8: 18,
        space12: 22,
        space16: 26,
        space20: 30,
        space24: 34,
        space32: 42,
        space40: 50,
        radiusMd: 14,
        radiusLg: 18,
        radiusXl: 22,
        radiusFull: 1000,
        elevationNone: 1,
        elevationCard: 2,
        elevationSheet: 4,
        elevationModal: 10,
        elevationBar: 3,
        elevationSurface: 2,
        breakpointCompact: 700,
        breakpointRail: 1000,
        breakpointTranscriptSideBySide: 800,
        motionStandard: const Duration(milliseconds: 300),
        motionEnter: const Duration(milliseconds: 280),
        motionExit: const Duration(milliseconds: 200),
        motionMedium: const Duration(milliseconds: 250),
      );

      expect(copy.space4, 100);
      expect(copy.radiusSm, 42);
      expect(copy.motionFast, const Duration(milliseconds: 999));
      expect(copy.echoActive, const Color(0xFF112233));
      expect(copy.bottomNavHeight, 200);
      expect(copy.desktopGutter, 99);
      expect(copy.modalMaxWidth, 500);
      expect(copy.modalMaxWidthLarge, 700);
      expect(copy.focusRingWidth, 5);
      expect(copy.contentMaxWidth, 800);
      expect(copy.formMaxWidth, 750);
      expect(copy.hubMaxWidth, 900);
      expect(copy.pageGutterCompact, 32);
      expect(copy.pageGutter, 48);
      expect(copy.miniBarBlurSigma, 40);
      expect(copy.sidebarWidth, 300);
      expect(copy.sidebarBrandHeight, 80);
      expect(copy.transportHeight, 120);
      expect(copy.heroTitleLetterSpacing, -2.0);
      expect(copy.glassTint, const Color(0xAA000000));
      expect(copy.glassBorder, const Color(0xBB111111));
      expect(copy.gradientStart, const Color(0xFF222222));
      expect(copy.gradientEnd, const Color(0xFF333333));
      expect(copy.blurActive, const Color(0xFF445566));
      expect(copy.scoreGood, const Color(0xFF119955));
      expect(copy.scoreWarn, const Color(0xFF996611));
      expect(copy.scoreBad, const Color(0xFF991122));
      expect(copy.scoreGoodContainer, const Color(0x33119955));
      expect(copy.scoreWarnContainer, const Color(0x33996611));
      expect(copy.scoreBadContainer, const Color(0x33991122));
      expect(copy.accentSoft, const Color(0x337B61FF));
      expect(copy.ccBadge, const Color(0xFF778899));
      expect(copy.transcriptLinePadding, const EdgeInsets.all(20));
      expect(copy.space8, 18);
      expect(copy.space12, 22);
      expect(copy.space16, 26);
      expect(copy.space20, 30);
      expect(copy.space24, 34);
      expect(copy.space32, 42);
      expect(copy.space40, 50);
      expect(copy.radiusMd, 14);
      expect(copy.radiusLg, 18);
      expect(copy.radiusXl, 22);
      expect(copy.radiusFull, 1000);
      expect(copy.elevationNone, 1);
      expect(copy.elevationCard, 2);
      expect(copy.elevationSheet, 4);
      expect(copy.elevationModal, 10);
      expect(copy.elevationBar, 3);
      expect(copy.elevationSurface, 2);
      expect(copy.breakpointCompact, 700);
      expect(copy.breakpointRail, 1000);
      expect(copy.breakpointTranscriptSideBySide, 800);
      expect(copy.motionStandard, const Duration(milliseconds: 300));
      expect(copy.motionEnter, const Duration(milliseconds: 280));
      expect(copy.motionExit, const Duration(milliseconds: 200));
      expect(copy.motionMedium, const Duration(milliseconds: 250));
    });
  });

  group('EnjoyThemeTokens.lerp', () {
    late EnjoyThemeTokens a;
    late EnjoyThemeTokens b;

    setUp(() {
      a = EnjoyThemeTokens.build(const ColorScheme.dark());
      b = a.copyWith(
        space4: 8,
        space8: 16,
        space12: 24,
        space16: 32,
        space20: 40,
        space24: 48,
        space32: 64,
        space40: 80,
        radiusSm: 16,
        radiusMd: 24,
        radiusLg: 32,
        radiusXl: 40,
        radiusFull: 1998,
        elevationNone: 0,
        elevationCard: 3,
        elevationSheet: 7,
        elevationModal: 16,
        elevationBar: 4,
        elevationSurface: 3,
        breakpointCompact: 1200,
        breakpointRail: 1800,
        breakpointTranscriptSideBySide: 1440,
        motionFast: const Duration(milliseconds: 360),
        motionStandard: const Duration(milliseconds: 520),
        motionEnter: const Duration(milliseconds: 480),
        motionExit: const Duration(milliseconds: 320),
        motionMedium: const Duration(milliseconds: 440),
        echoActive: const Color(0xFF0000FF),
        blurActive: const Color(0xFF00FF00),
        scoreGood: const Color(0xFF00EE88),
        scoreWarn: const Color(0xFFEEAA00),
        scoreBad: const Color(0xFFEE2233),
        scoreGoodContainer: const Color(0x4000EE88),
        scoreWarnContainer: const Color(0x40EEAA00),
        scoreBadContainer: const Color(0x40EE2233),
        accentSoft: const Color(0x407B61FF),
        ccBadge: const Color(0xFFFF0000),
        transcriptLinePadding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 20,
        ),
        contentMaxWidth: 1440,
        formMaxWidth: 1360,
        hubMaxWidth: 1680,
        pageGutterCompact: 32,
        pageGutter: 48,
        miniBarBlurSigma: 40,
        sidebarWidth: 496,
        sidebarBrandHeight: 112,
        transportHeight: 176,
        heroTitleLetterSpacing: -2.4,
        glassTint: const Color(0xFF000000),
        glassBorder: const Color(0xFFFFFFFF),
        gradientStart: const Color(0xFF303030),
        gradientEnd: const Color(0xFF121212),
        bottomNavHeight: 136,
        desktopGutter: 48,
        modalMaxWidth: 800,
        modalMaxWidthLarge: 1120,
        focusRingWidth: 4,
      );
    });

    test('t=0 returns this', () {
      final result = a.lerp(b, 0);
      expect(identical(result, a), isTrue);
    });

    test('t=1 returns other', () {
      final result = a.lerp(b, 1);
      expect(identical(result, b), isTrue);
    });

    test('returns this when other is not EnjoyThemeTokens', () {
      final result = a.lerp(null, 0.5);
      expect(identical(result, a), isTrue);
    });

    test('t=0.5 produces correct midpoint for doubles', () {
      final result = a.lerp(b, 0.5) as EnjoyThemeTokens;

      expect(result.space4, 6);
      expect(result.space8, 12);
      expect(result.space12, 18);
      expect(result.space16, 24);
      expect(result.space20, 30);
      expect(result.space24, 36);
      expect(result.space32, 48);
      expect(result.space40, 60);

      expect(result.radiusSm, 12);
      expect(result.radiusMd, 18);
      expect(result.radiusLg, 24);
      expect(result.radiusXl, 31);
      expect(result.radiusFull, 1498.5);

      expect(result.elevationNone, 0);
      expect(result.elevationCard, 2);
      expect(result.elevationSheet, 5);
      expect(result.elevationModal, 12);
      expect(result.elevationBar, 3);
      expect(result.elevationSurface, 2);

      expect(result.breakpointCompact, 900);
      expect(result.breakpointRail, 1350);
      expect(result.breakpointTranscriptSideBySide, 1080);

      expect(result.contentMaxWidth, 1110);
      expect(result.formMaxWidth, 1020);
      expect(result.hubMaxWidth, 1260);
      expect(result.pageGutterCompact, 24);
      expect(result.pageGutter, 44);
      expect(result.miniBarBlurSigma, 32);
      expect(result.sidebarWidth, 370);
      expect(result.sidebarBrandHeight, 82);
      expect(result.transportHeight, 132);
      expect(result.heroTitleLetterSpacing, closeTo(-1.65, 1e-10));
      expect(result.bottomNavHeight, 100);
      expect(result.desktopGutter, 36);
      expect(result.modalMaxWidth, 600);
      expect(result.modalMaxWidthLarge, 840);
      expect(result.focusRingWidth, 3);
    });

    test('t=0.5 produces correct midpoint for durations', () {
      final result = a.lerp(b, 0.5) as EnjoyThemeTokens;

      expect(result.motionFast, const Duration(milliseconds: 260));
      expect(result.motionStandard, const Duration(milliseconds: 400));
      expect(result.motionEnter, const Duration(milliseconds: 370));
      expect(result.motionExit, const Duration(milliseconds: 240));
      expect(result.motionMedium, const Duration(milliseconds: 330));
    });

    test('t=0.5 lerps colors', () {
      final result = a.lerp(b, 0.5) as EnjoyThemeTokens;

      expect(result.echoActive, Color.lerp(a.echoActive, b.echoActive, 0.5));
      expect(result.blurActive, Color.lerp(a.blurActive, b.blurActive, 0.5));
      expect(result.scoreGood, Color.lerp(a.scoreGood, b.scoreGood, 0.5));
      expect(result.scoreWarn, Color.lerp(a.scoreWarn, b.scoreWarn, 0.5));
      expect(result.scoreBad, Color.lerp(a.scoreBad, b.scoreBad, 0.5));
      expect(
        result.scoreGoodContainer,
        Color.lerp(a.scoreGoodContainer, b.scoreGoodContainer, 0.5),
      );
      expect(
        result.scoreWarnContainer,
        Color.lerp(a.scoreWarnContainer, b.scoreWarnContainer, 0.5),
      );
      expect(
        result.scoreBadContainer,
        Color.lerp(a.scoreBadContainer, b.scoreBadContainer, 0.5),
      );
      expect(result.accentSoft, Color.lerp(a.accentSoft, b.accentSoft, 0.5));
      expect(result.ccBadge, Color.lerp(a.ccBadge, b.ccBadge, 0.5));
      expect(result.glassTint, Color.lerp(a.glassTint, b.glassTint, 0.5));
      expect(result.glassBorder, Color.lerp(a.glassBorder, b.glassBorder, 0.5));
      expect(
        result.gradientStart,
        Color.lerp(a.gradientStart, b.gradientStart, 0.5),
      );
      expect(result.gradientEnd, Color.lerp(a.gradientEnd, b.gradientEnd, 0.5));
    });

    test('t=0.5 lerps EdgeInsets', () {
      final result = a.lerp(b, 0.5) as EnjoyThemeTokens;

      expect(
        result.transcriptLinePadding,
        EdgeInsets.lerp(a.transcriptLinePadding, b.transcriptLinePadding, 0.5),
      );
    });

    test('t=0.25 produces correct quarter-point values', () {
      final result = a.lerp(b, 0.25) as EnjoyThemeTokens;

      expect(result.space4, 5);
      expect(result.space40, 50);
      expect(result.radiusSm, 10);
      expect(result.focusRingWidth, 2.5);
    });
  });
}
