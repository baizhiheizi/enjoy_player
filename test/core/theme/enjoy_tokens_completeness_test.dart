import 'dart:io';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sentinelDouble = 111.5;
const _sentinelColor = Color(0xFF13579B);
const _sentinelDuration = Duration(milliseconds: 999);
const _sentinelPadding = EdgeInsets.all(9);
const _sentinelLens = <double>[1.5];
const _sentinelShadows = <BoxShadow>[
  BoxShadow(color: Color(0x1F13579B), blurRadius: 9),
];

const _spacesTokenNames = <String>[
  'space4',
  'space8',
  'space12',
  'space16',
  'space20',
  'space24',
  'space32',
  'space40',
  'space48',
  'pageGutterCompact',
  'pageGutter',
  'desktopGutter',
  'marginWidth',
  'gutter',
  'gutterPhone',
];

const _radiiTokenNames = <String>[
  'radiusSm',
  'radiusMd',
  'radiusLg',
  'radiusXl',
  'radiusFull',
  'radiusXs',
  'radius2xl',
  'panelRadius',
  'radiusKeycap',
  'radiusBadge',
  'radiusSegmentThumb',
  'radiusControl',
  'radiusTile',
  'radiusCard',
  'radiusCardLarge',
  'radiusDialog',
  'radiusSheet',
];

const _motionTokenNames = <String>[
  'motionFast',
  'motionStandard',
  'motionEnter',
  'motionExit',
  'motionMedium',
  'motionLens',
  'motionMargin',
];

const _elevationTokenNames = <String>[
  'elevationNone',
  'elevationCard',
  'elevationSheet',
  'elevationModal',
  'elevationBar',
  'elevationSurface',
  'focusRingWidth',
  'shadowLift',
  'shadowFloat',
  'shadowPopover',
  'strokeReferencePitch',
  'strokeYourPitch',
  'strokeLoopBracket',
  'strokeRulerTrack',
  'shadowBrandButton',
  'shadowRecordButton',
];

const _layoutTokenNames = <String>[
  'breakpointCompact',
  'breakpointRail',
  'breakpointTranscriptSideBySide',
  'breakpointMarginDrawer',
  'contentMaxWidth',
  'formMaxWidth',
  'hubMaxWidth',
  'sidebarWidth',
  'sidebarBrandHeight',
  'transportHeight',
  'bottomNavHeight',
  'modalMaxWidth',
  'modalMaxWidthLarge',
  'shellInset',
  'tabBarHeight',
  'tabBarSafeInset',
  'playerTopBarHeight',
  'subpageHeaderHeight',
  'rulerHitHeight',
  'transcriptMaxListen',
  'transcriptMaxEcho',
  'videoColumnMin',
  'videoColumnMax',
  'videoColumnShare',
  'pageMaxBrowse',
  'pageMaxCraft',
  'pageMaxHub',
  'pageMaxForm',
];

const _componentTokenNames = <String>[
  'miniBarBlurSigma',
  'heroTitleLetterSpacing',
  'controlHeightSm',
  'controlHeight',
  'controlHeightLg',
  'touchTargetMin',
  'iconButtonSize',
  'iconButtonSizePhone',
  'segmentHeight',
  'chipHeight',
  'takeChipHeight',
  'playButtonSize',
  'playButtonSizePhone',
  'recordButtonSize',
  'recordButtonSizePhone',
  'originalPillWidth',
  'originalPillHeight',
  'originalButtonPhoneSize',
];

const _paletteTokenNames = <String>[
  'glassTint',
  'glassBorder',
  'gradientStart',
  'gradientEnd',
  'canvas',
  'card',
  'popover',
  'hairline',
  'fill',
  'textFaint',
  'logoStart',
  'logoEnd',
  'topHighlight',
  'ground',
  'paper',
  'raised',
  'sunk',
  'line',
  'ink',
  'ink2',
  'ink3',
  'shape',
  'tick',
  'scrim',
  'video',
];

const _accentTokenNames = <String>[
  'echoActive',
  'blurActive',
  'scoreGood',
  'scoreWarn',
  'scoreBad',
  'scoreGoodContainer',
  'scoreWarnContainer',
  'scoreBadContainer',
  'accentSoft',
  'accentInk',
  'intelligenceInk',
  'echoInk',
  'ccBadge',
  'original',
  'originalInk',
  'originalSoft',
  'you',
  'youInk',
  'youSoft',
  'youLine',
  'originalLine',
  'onYou',
  'brandInk',
  'brandSoft',
  'primary',
  'onPrimary',
  'danger',
  'vocabNew',
  'vocabLearning',
  'vocabReviewing',
  'vocabMastered',
];

const _effectTokenNames = <String>[
  'transcriptLinePadding',
  'echoLensOpacity',
  'referencePitchOpacity',
];

const _tokenGroupFiles = <String, String>{
  'spaces': 'spaces.dart',
  'radii': 'radius.dart',
  'motion': 'motion.dart',
  'elevation': 'elevation.dart',
  'layout': 'layout.dart',
  'components': 'components.dart',
  'palette': 'palette.dart',
  'accents': 'accents_values.dart',
  'effects': 'effects.dart',
};

const _tokenGroups = <String, List<String>>{
  'spaces': _spacesTokenNames,
  'radii': _radiiTokenNames,
  'motion': _motionTokenNames,
  'elevation': _elevationTokenNames,
  'layout': _layoutTokenNames,
  'components': _componentTokenNames,
  'palette': _paletteTokenNames,
  'accents': _accentTokenNames,
  'effects': _effectTokenNames,
};

Set<String> _scanGroupFields(File file) {
  final source = file.readAsStringSync();
  return RegExp(
    r'^\s+final [\w<>, ?]+ (\w+);$',
    multiLine: true,
  ).allMatches(source).map((match) => match.group(1)!).toSet();
}

Map<String, Set<String>> _scanAccessors() {
  final accessors = <String, Set<String>>{};
  final partFiles = Directory(
    'lib/core/theme/tokens',
  ).listSync().whereType<File>().where((file) => file.path.endsWith('.dart'));
  for (final file in partFiles) {
    final source = file.readAsStringSync();
    for (final match in RegExp(r'_(\w+)\.(\w+);').allMatches(source)) {
      accessors
          .putIfAbsent(match.group(1)!, () => <String>{})
          .add(match.group(2)!);
    }
  }
  return accessors;
}

void main() {
  group('EnjoyThemeTokens completeness pin', () {
    test('manifest matches every group field and count', () {
      expect(
        _tokenGroups.values.fold<int>(
          0,
          (total, names) => total + names.length,
        ),
        160,
      );

      for (final entry in _tokenGroups.entries) {
        final file = File(
          'lib/core/theme/tokens/${_tokenGroupFiles[entry.key]}',
        );
        final fields = _scanGroupFields(file);
        expect(
          fields,
          entry.value.toSet(),
          reason:
              '${entry.key} group fields drifted; update the pin manifest and '
              'the facade copyWith together',
        );

        final accessors = _scanAccessors();
        expect(
          accessors[entry.key],
          fields,
          reason: '${entry.key} accessor extension is missing a token getter',
        );
      }
    });

    test('facade copyWith lists every token as a parameter', () {
      final source = File(
        'lib/core/theme/enjoy_tokens.dart',
      ).readAsStringSync();
      final start = source.indexOf('copyWith({');
      final end = source.indexOf('}) {', start);
      final block = source.substring(start, end);

      final params = RegExp(
        r'^\s+[\w<>, ?]+ (\w+),\s*$',
        multiLine: true,
      ).allMatches(block).map((match) => match.group(1)!).toSet();

      final everyField = _tokenGroups.values.expand((names) => names).toSet();
      expect(params, everyField);
    });

    test('facade copyWith forwards every token into its own group', () {
      final source = File(
        'lib/core/theme/enjoy_tokens.dart',
      ).readAsStringSync();
      final region = source.substring(
        source.indexOf('return EnjoyThemeTokens._('),
      );

      final forwarding = <String, Set<String>>{};
      for (final match in RegExp(
        r'_(\w+)\.copyWith\(([^)]*)\)',
      ).allMatches(region)) {
        final group = match.group(1)!;
        forwarding[group] = RegExp(
          r'(\w+): \w+,',
        ).allMatches(match.group(2)!).map((entry) => entry.group(1)!).toSet();
      }

      for (final entry in _tokenGroups.entries) {
        final group = entry.key;
        expect(
          forwarding[group],
          entry.value.toSet(),
          reason: 'facade forwarding for the $group group dropped a token',
        );
      }
    });

    test('every token flows through the facade copyWith', () {
      final tokens = EnjoyThemeTokens.build(const ColorScheme.dark());
      final copy = tokens.copyWith(
        space4: _sentinelDouble,
        space8: _sentinelDouble,
        space12: _sentinelDouble,
        space16: _sentinelDouble,
        space20: _sentinelDouble,
        space24: _sentinelDouble,
        space32: _sentinelDouble,
        space40: _sentinelDouble,
        space48: _sentinelDouble,
        pageGutterCompact: _sentinelDouble,
        pageGutter: _sentinelDouble,
        desktopGutter: _sentinelDouble,
        marginWidth: _sentinelDouble,
        gutter: _sentinelDouble,
        gutterPhone: _sentinelDouble,
        radiusSm: _sentinelDouble,
        radiusMd: _sentinelDouble,
        radiusLg: _sentinelDouble,
        radiusXl: _sentinelDouble,
        radiusFull: _sentinelDouble,
        radiusXs: _sentinelDouble,
        radius2xl: _sentinelDouble,
        panelRadius: _sentinelDouble,
        radiusKeycap: _sentinelDouble,
        radiusBadge: _sentinelDouble,
        radiusSegmentThumb: _sentinelDouble,
        radiusControl: _sentinelDouble,
        radiusTile: _sentinelDouble,
        radiusCard: _sentinelDouble,
        radiusCardLarge: _sentinelDouble,
        radiusDialog: _sentinelDouble,
        radiusSheet: _sentinelDouble,
        motionFast: _sentinelDuration,
        motionStandard: _sentinelDuration,
        motionEnter: _sentinelDuration,
        motionExit: _sentinelDuration,
        motionMedium: _sentinelDuration,
        motionLens: _sentinelDuration,
        motionMargin: _sentinelDuration,
        elevationNone: _sentinelDouble,
        elevationCard: _sentinelDouble,
        elevationSheet: _sentinelDouble,
        elevationModal: _sentinelDouble,
        elevationBar: _sentinelDouble,
        elevationSurface: _sentinelDouble,
        focusRingWidth: _sentinelDouble,
        shadowLift: _sentinelShadows,
        shadowFloat: _sentinelShadows,
        shadowPopover: _sentinelShadows,
        strokeReferencePitch: _sentinelDouble,
        strokeYourPitch: _sentinelDouble,
        strokeLoopBracket: _sentinelDouble,
        strokeRulerTrack: _sentinelDouble,
        shadowBrandButton: _sentinelShadows,
        shadowRecordButton: _sentinelShadows,
        breakpointCompact: _sentinelDouble,
        breakpointRail: _sentinelDouble,
        breakpointTranscriptSideBySide: _sentinelDouble,
        breakpointMarginDrawer: _sentinelDouble,
        contentMaxWidth: _sentinelDouble,
        formMaxWidth: _sentinelDouble,
        hubMaxWidth: _sentinelDouble,
        sidebarWidth: _sentinelDouble,
        sidebarBrandHeight: _sentinelDouble,
        transportHeight: _sentinelDouble,
        bottomNavHeight: _sentinelDouble,
        modalMaxWidth: _sentinelDouble,
        modalMaxWidthLarge: _sentinelDouble,
        shellInset: _sentinelDouble,
        tabBarHeight: _sentinelDouble,
        tabBarSafeInset: _sentinelDouble,
        playerTopBarHeight: _sentinelDouble,
        subpageHeaderHeight: _sentinelDouble,
        rulerHitHeight: _sentinelDouble,
        transcriptMaxListen: _sentinelDouble,
        transcriptMaxEcho: _sentinelDouble,
        videoColumnMin: _sentinelDouble,
        videoColumnMax: _sentinelDouble,
        videoColumnShare: _sentinelDouble,
        pageMaxBrowse: _sentinelDouble,
        pageMaxCraft: _sentinelDouble,
        pageMaxHub: _sentinelDouble,
        pageMaxForm: _sentinelDouble,
        miniBarBlurSigma: _sentinelDouble,
        heroTitleLetterSpacing: _sentinelDouble,
        controlHeightSm: _sentinelDouble,
        controlHeight: _sentinelDouble,
        controlHeightLg: _sentinelDouble,
        touchTargetMin: _sentinelDouble,
        iconButtonSize: _sentinelDouble,
        iconButtonSizePhone: _sentinelDouble,
        segmentHeight: _sentinelDouble,
        chipHeight: _sentinelDouble,
        takeChipHeight: _sentinelDouble,
        playButtonSize: _sentinelDouble,
        playButtonSizePhone: _sentinelDouble,
        recordButtonSize: _sentinelDouble,
        recordButtonSizePhone: _sentinelDouble,
        originalPillWidth: _sentinelDouble,
        originalPillHeight: _sentinelDouble,
        originalButtonPhoneSize: _sentinelDouble,
        glassTint: _sentinelColor,
        glassBorder: _sentinelColor,
        gradientStart: _sentinelColor,
        gradientEnd: _sentinelColor,
        canvas: _sentinelColor,
        card: _sentinelColor,
        popover: _sentinelColor,
        hairline: _sentinelColor,
        fill: _sentinelColor,
        textFaint: _sentinelColor,
        logoStart: _sentinelColor,
        logoEnd: _sentinelColor,
        topHighlight: _sentinelColor,
        ground: _sentinelColor,
        paper: _sentinelColor,
        raised: _sentinelColor,
        sunk: _sentinelColor,
        line: _sentinelColor,
        ink: _sentinelColor,
        ink2: _sentinelColor,
        ink3: _sentinelColor,
        shape: _sentinelColor,
        tick: _sentinelColor,
        scrim: _sentinelColor,
        video: _sentinelColor,
        echoActive: _sentinelColor,
        blurActive: _sentinelColor,
        scoreGood: _sentinelColor,
        scoreWarn: _sentinelColor,
        scoreBad: _sentinelColor,
        scoreGoodContainer: _sentinelColor,
        scoreWarnContainer: _sentinelColor,
        scoreBadContainer: _sentinelColor,
        accentSoft: _sentinelColor,
        accentInk: _sentinelColor,
        intelligenceInk: _sentinelColor,
        echoInk: _sentinelColor,
        ccBadge: _sentinelColor,
        original: _sentinelColor,
        originalInk: _sentinelColor,
        originalSoft: _sentinelColor,
        you: _sentinelColor,
        youInk: _sentinelColor,
        youSoft: _sentinelColor,
        youLine: _sentinelColor,
        originalLine: _sentinelColor,
        onYou: _sentinelColor,
        brandInk: _sentinelColor,
        brandSoft: _sentinelColor,
        primary: _sentinelColor,
        onPrimary: _sentinelColor,
        danger: _sentinelColor,
        vocabNew: _sentinelColor,
        vocabLearning: _sentinelColor,
        vocabReviewing: _sentinelColor,
        vocabMastered: _sentinelColor,
        transcriptLinePadding: _sentinelPadding,
        echoLensOpacity: _sentinelLens,
        referencePitchOpacity: _sentinelDouble,
      );

      expect(copy.space4, _sentinelDouble);
      expect(copy.space8, _sentinelDouble);
      expect(copy.space12, _sentinelDouble);
      expect(copy.space16, _sentinelDouble);
      expect(copy.space20, _sentinelDouble);
      expect(copy.space24, _sentinelDouble);
      expect(copy.space32, _sentinelDouble);
      expect(copy.space40, _sentinelDouble);
      expect(copy.space48, _sentinelDouble);
      expect(copy.pageGutterCompact, _sentinelDouble);
      expect(copy.pageGutter, _sentinelDouble);
      expect(copy.desktopGutter, _sentinelDouble);
      expect(copy.marginWidth, _sentinelDouble);
      expect(copy.gutter, _sentinelDouble);
      expect(copy.gutterPhone, _sentinelDouble);
      expect(copy.radiusSm, _sentinelDouble);
      expect(copy.radiusMd, _sentinelDouble);
      expect(copy.radiusLg, _sentinelDouble);
      expect(copy.radiusXl, _sentinelDouble);
      expect(copy.radiusFull, _sentinelDouble);
      expect(copy.radiusXs, _sentinelDouble);
      expect(copy.radius2xl, _sentinelDouble);
      expect(copy.panelRadius, _sentinelDouble);
      expect(copy.radiusKeycap, _sentinelDouble);
      expect(copy.radiusBadge, _sentinelDouble);
      expect(copy.radiusSegmentThumb, _sentinelDouble);
      expect(copy.radiusControl, _sentinelDouble);
      expect(copy.radiusTile, _sentinelDouble);
      expect(copy.radiusCard, _sentinelDouble);
      expect(copy.radiusCardLarge, _sentinelDouble);
      expect(copy.radiusDialog, _sentinelDouble);
      expect(copy.radiusSheet, _sentinelDouble);
      expect(copy.motionFast, _sentinelDuration);
      expect(copy.motionStandard, _sentinelDuration);
      expect(copy.motionEnter, _sentinelDuration);
      expect(copy.motionExit, _sentinelDuration);
      expect(copy.motionMedium, _sentinelDuration);
      expect(copy.motionLens, _sentinelDuration);
      expect(copy.motionMargin, _sentinelDuration);
      expect(copy.elevationNone, _sentinelDouble);
      expect(copy.elevationCard, _sentinelDouble);
      expect(copy.elevationSheet, _sentinelDouble);
      expect(copy.elevationModal, _sentinelDouble);
      expect(copy.elevationBar, _sentinelDouble);
      expect(copy.elevationSurface, _sentinelDouble);
      expect(copy.focusRingWidth, _sentinelDouble);
      expect(copy.shadowLift, _sentinelShadows);
      expect(copy.shadowFloat, _sentinelShadows);
      expect(copy.shadowPopover, _sentinelShadows);
      expect(copy.strokeReferencePitch, _sentinelDouble);
      expect(copy.strokeYourPitch, _sentinelDouble);
      expect(copy.strokeLoopBracket, _sentinelDouble);
      expect(copy.strokeRulerTrack, _sentinelDouble);
      expect(copy.shadowBrandButton, _sentinelShadows);
      expect(copy.shadowRecordButton, _sentinelShadows);
      expect(copy.breakpointCompact, _sentinelDouble);
      expect(copy.breakpointRail, _sentinelDouble);
      expect(copy.breakpointTranscriptSideBySide, _sentinelDouble);
      expect(copy.breakpointMarginDrawer, _sentinelDouble);
      expect(copy.contentMaxWidth, _sentinelDouble);
      expect(copy.formMaxWidth, _sentinelDouble);
      expect(copy.hubMaxWidth, _sentinelDouble);
      expect(copy.sidebarWidth, _sentinelDouble);
      expect(copy.sidebarBrandHeight, _sentinelDouble);
      expect(copy.transportHeight, _sentinelDouble);
      expect(copy.bottomNavHeight, _sentinelDouble);
      expect(copy.modalMaxWidth, _sentinelDouble);
      expect(copy.modalMaxWidthLarge, _sentinelDouble);
      expect(copy.shellInset, _sentinelDouble);
      expect(copy.tabBarHeight, _sentinelDouble);
      expect(copy.tabBarSafeInset, _sentinelDouble);
      expect(copy.playerTopBarHeight, _sentinelDouble);
      expect(copy.subpageHeaderHeight, _sentinelDouble);
      expect(copy.rulerHitHeight, _sentinelDouble);
      expect(copy.transcriptMaxListen, _sentinelDouble);
      expect(copy.transcriptMaxEcho, _sentinelDouble);
      expect(copy.videoColumnMin, _sentinelDouble);
      expect(copy.videoColumnMax, _sentinelDouble);
      expect(copy.videoColumnShare, _sentinelDouble);
      expect(copy.pageMaxBrowse, _sentinelDouble);
      expect(copy.pageMaxCraft, _sentinelDouble);
      expect(copy.pageMaxHub, _sentinelDouble);
      expect(copy.pageMaxForm, _sentinelDouble);
      expect(copy.miniBarBlurSigma, _sentinelDouble);
      expect(copy.heroTitleLetterSpacing, _sentinelDouble);
      expect(copy.controlHeightSm, _sentinelDouble);
      expect(copy.controlHeight, _sentinelDouble);
      expect(copy.controlHeightLg, _sentinelDouble);
      expect(copy.touchTargetMin, _sentinelDouble);
      expect(copy.iconButtonSize, _sentinelDouble);
      expect(copy.iconButtonSizePhone, _sentinelDouble);
      expect(copy.segmentHeight, _sentinelDouble);
      expect(copy.chipHeight, _sentinelDouble);
      expect(copy.takeChipHeight, _sentinelDouble);
      expect(copy.playButtonSize, _sentinelDouble);
      expect(copy.playButtonSizePhone, _sentinelDouble);
      expect(copy.recordButtonSize, _sentinelDouble);
      expect(copy.recordButtonSizePhone, _sentinelDouble);
      expect(copy.originalPillWidth, _sentinelDouble);
      expect(copy.originalPillHeight, _sentinelDouble);
      expect(copy.originalButtonPhoneSize, _sentinelDouble);
      expect(copy.glassTint, _sentinelColor);
      expect(copy.glassBorder, _sentinelColor);
      expect(copy.gradientStart, _sentinelColor);
      expect(copy.gradientEnd, _sentinelColor);
      expect(copy.canvas, _sentinelColor);
      expect(copy.card, _sentinelColor);
      expect(copy.popover, _sentinelColor);
      expect(copy.hairline, _sentinelColor);
      expect(copy.fill, _sentinelColor);
      expect(copy.textFaint, _sentinelColor);
      expect(copy.logoStart, _sentinelColor);
      expect(copy.logoEnd, _sentinelColor);
      expect(copy.topHighlight, _sentinelColor);
      expect(copy.ground, _sentinelColor);
      expect(copy.paper, _sentinelColor);
      expect(copy.raised, _sentinelColor);
      expect(copy.sunk, _sentinelColor);
      expect(copy.line, _sentinelColor);
      expect(copy.ink, _sentinelColor);
      expect(copy.ink2, _sentinelColor);
      expect(copy.ink3, _sentinelColor);
      expect(copy.shape, _sentinelColor);
      expect(copy.tick, _sentinelColor);
      expect(copy.scrim, _sentinelColor);
      expect(copy.video, _sentinelColor);
      expect(copy.echoActive, _sentinelColor);
      expect(copy.blurActive, _sentinelColor);
      expect(copy.scoreGood, _sentinelColor);
      expect(copy.scoreWarn, _sentinelColor);
      expect(copy.scoreBad, _sentinelColor);
      expect(copy.scoreGoodContainer, _sentinelColor);
      expect(copy.scoreWarnContainer, _sentinelColor);
      expect(copy.scoreBadContainer, _sentinelColor);
      expect(copy.accentSoft, _sentinelColor);
      expect(copy.accentInk, _sentinelColor);
      expect(copy.intelligenceInk, _sentinelColor);
      expect(copy.echoInk, _sentinelColor);
      expect(copy.ccBadge, _sentinelColor);
      expect(copy.original, _sentinelColor);
      expect(copy.originalInk, _sentinelColor);
      expect(copy.originalSoft, _sentinelColor);
      expect(copy.you, _sentinelColor);
      expect(copy.youInk, _sentinelColor);
      expect(copy.youSoft, _sentinelColor);
      expect(copy.youLine, _sentinelColor);
      expect(copy.originalLine, _sentinelColor);
      expect(copy.onYou, _sentinelColor);
      expect(copy.brandInk, _sentinelColor);
      expect(copy.brandSoft, _sentinelColor);
      expect(copy.primary, _sentinelColor);
      expect(copy.onPrimary, _sentinelColor);
      expect(copy.danger, _sentinelColor);
      expect(copy.vocabNew, _sentinelColor);
      expect(copy.vocabLearning, _sentinelColor);
      expect(copy.vocabReviewing, _sentinelColor);
      expect(copy.vocabMastered, _sentinelColor);
      expect(copy.transcriptLinePadding, _sentinelPadding);
      expect(copy.echoLensOpacity, _sentinelLens);
      expect(copy.referencePitchOpacity, _sentinelDouble);
    });
  });
}
