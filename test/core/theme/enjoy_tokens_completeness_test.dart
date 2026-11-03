import 'dart:io';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sentinelPadding = EdgeInsets.all(9);

const _sentinelLens = <double>[1.5];

const _doubleSentinels = <String, double>{
  'space4': 1000.5,
  'space8': 1001.5,
  'space12': 1002.5,
  'space16': 1003.5,
  'space20': 1004.5,
  'space24': 1005.5,
  'space32': 1006.5,
  'space40': 1007.5,
  'space48': 1008.5,
  'pageGutterCompact': 1009.5,
  'pageGutter': 1010.5,
  'desktopGutter': 1011.5,
  'marginWidth': 1012.5,
  'gutter': 1013.5,
  'gutterPhone': 1014.5,
  'radiusSm': 1015.5,
  'radiusMd': 1016.5,
  'radiusLg': 1017.5,
  'radiusXl': 1018.5,
  'radiusFull': 1019.5,
  'radiusXs': 1020.5,
  'radius2xl': 1021.5,
  'panelRadius': 1022.5,
  'radiusKeycap': 1023.5,
  'radiusBadge': 1024.5,
  'radiusSegmentThumb': 1025.5,
  'radiusControl': 1026.5,
  'radiusTile': 1027.5,
  'radiusCard': 1028.5,
  'radiusCardLarge': 1029.5,
  'radiusDialog': 1030.5,
  'radiusSheet': 1031.5,
  'elevationNone': 1032.5,
  'elevationCard': 1033.5,
  'elevationSheet': 1034.5,
  'elevationModal': 1035.5,
  'elevationBar': 1036.5,
  'elevationSurface': 1037.5,
  'focusRingWidth': 1038.5,
  'strokeReferencePitch': 1039.5,
  'strokeYourPitch': 1040.5,
  'strokeLoopBracket': 1041.5,
  'strokeRulerTrack': 1042.5,
  'breakpointCompact': 1043.5,
  'breakpointRail': 1044.5,
  'breakpointTranscriptSideBySide': 1045.5,
  'breakpointMarginDrawer': 1046.5,
  'contentMaxWidth': 1047.5,
  'formMaxWidth': 1048.5,
  'hubMaxWidth': 1049.5,
  'sidebarWidth': 1050.5,
  'sidebarBrandHeight': 1051.5,
  'transportHeight': 1052.5,
  'bottomNavHeight': 1053.5,
  'modalMaxWidth': 1054.5,
  'modalMaxWidthLarge': 1055.5,
  'shellInset': 1056.5,
  'tabBarHeight': 1057.5,
  'tabBarSafeInset': 1058.5,
  'playerTopBarHeight': 1059.5,
  'subpageHeaderHeight': 1060.5,
  'rulerHitHeight': 1061.5,
  'transcriptMaxListen': 1062.5,
  'transcriptMaxEcho': 1063.5,
  'videoColumnMin': 1064.5,
  'videoColumnMax': 1065.5,
  'videoColumnShare': 1066.5,
  'pageMaxBrowse': 1067.5,
  'pageMaxCraft': 1068.5,
  'pageMaxHub': 1069.5,
  'pageMaxForm': 1070.5,
  'miniBarBlurSigma': 1071.5,
  'heroTitleLetterSpacing': 1072.5,
  'controlHeightSm': 1073.5,
  'controlHeight': 1074.5,
  'controlHeightLg': 1075.5,
  'touchTargetMin': 1076.5,
  'iconButtonSize': 1077.5,
  'iconButtonSizePhone': 1078.5,
  'segmentHeight': 1079.5,
  'chipHeight': 1080.5,
  'takeChipHeight': 1081.5,
  'playButtonSize': 1082.5,
  'playButtonSizePhone': 1083.5,
  'recordButtonSize': 1084.5,
  'recordButtonSizePhone': 1085.5,
  'originalPillWidth': 1086.5,
  'originalPillHeight': 1087.5,
  'originalButtonPhoneSize': 1088.5,
  'referencePitchOpacity': 1089.5,
};

const _colorSentinels = <String, Color>{
  'glassTint': Color(0xFF13579B),
  'glassBorder': Color(0xFF13579C),
  'gradientStart': Color(0xFF13579D),
  'gradientEnd': Color(0xFF13579E),
  'canvas': Color(0xFF13579F),
  'card': Color(0xFF1357A0),
  'popover': Color(0xFF1357A1),
  'hairline': Color(0xFF1357A2),
  'fill': Color(0xFF1357A3),
  'textFaint': Color(0xFF1357A4),
  'logoStart': Color(0xFF1357A5),
  'logoEnd': Color(0xFF1357A6),
  'topHighlight': Color(0xFF1357A7),
  'ground': Color(0xFF1357A8),
  'paper': Color(0xFF1357A9),
  'raised': Color(0xFF1357AA),
  'sunk': Color(0xFF1357AB),
  'line': Color(0xFF1357AC),
  'ink': Color(0xFF1357AD),
  'ink2': Color(0xFF1357AE),
  'ink3': Color(0xFF1357AF),
  'shape': Color(0xFF1357B0),
  'tick': Color(0xFF1357B1),
  'scrim': Color(0xFF1357B2),
  'video': Color(0xFF1357B3),
  'echoActive': Color(0xFF1357B4),
  'blurActive': Color(0xFF1357B5),
  'scoreGood': Color(0xFF1357B6),
  'scoreWarn': Color(0xFF1357B7),
  'scoreBad': Color(0xFF1357B8),
  'scoreGoodContainer': Color(0xFF1357B9),
  'scoreWarnContainer': Color(0xFF1357BA),
  'scoreBadContainer': Color(0xFF1357BB),
  'accentSoft': Color(0xFF1357BC),
  'accentInk': Color(0xFF1357BD),
  'intelligenceInk': Color(0xFF1357BE),
  'echoInk': Color(0xFF1357BF),
  'ccBadge': Color(0xFF1357C0),
  'original': Color(0xFF1357C1),
  'originalInk': Color(0xFF1357C2),
  'originalSoft': Color(0xFF1357C3),
  'you': Color(0xFF1357C4),
  'youInk': Color(0xFF1357C5),
  'youSoft': Color(0xFF1357C6),
  'youLine': Color(0xFF1357C7),
  'originalLine': Color(0xFF1357C8),
  'onYou': Color(0xFF1357C9),
  'brandInk': Color(0xFF1357CA),
  'brandSoft': Color(0xFF1357CB),
  'primary': Color(0xFF1357CC),
  'onPrimary': Color(0xFF1357CD),
  'danger': Color(0xFF1357CE),
  'vocabNew': Color(0xFF1357CF),
  'vocabLearning': Color(0xFF1357D0),
  'vocabReviewing': Color(0xFF1357D1),
  'vocabMastered': Color(0xFF1357D2),
};

const _durationSentinels = <String, Duration>{
  'motionFast': Duration(milliseconds: 999),
  'motionStandard': Duration(milliseconds: 1001),
  'motionEnter': Duration(milliseconds: 1002),
  'motionExit': Duration(milliseconds: 1003),
  'motionMedium': Duration(milliseconds: 1004),
  'motionLens': Duration(milliseconds: 1005),
  'motionMargin': Duration(milliseconds: 1006),
};

const _shadowSentinels = <String, List<BoxShadow>>{
  'shadowLift': [BoxShadow(color: Color(0x1F13579B), blurRadius: 9)],
  'shadowFloat': [BoxShadow(color: Color(0x1F13579C), blurRadius: 10)],
  'shadowPopover': [BoxShadow(color: Color(0x1F13579D), blurRadius: 11)],
  'shadowBrandButton': [BoxShadow(color: Color(0x1F13579E), blurRadius: 12)],
  'shadowRecordButton': [BoxShadow(color: Color(0x1F13579F), blurRadius: 13)],
};

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

const _componentsTokenNames = <String>[
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

const _accentsTokenNames = <String>[
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

const _effectsTokenNames = <String>[
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
  'components': _componentsTokenNames,
  'palette': _paletteTokenNames,
  'accents': _accentsTokenNames,
  'effects': _effectsTokenNames,
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

String _defaultSources() {
  final partFiles = Directory('lib/core/theme/tokens')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .map((file) => file.readAsStringSync());
  return [
    partFiles,
    File('lib/core/theme/colors.dart').readAsStringSync(),
  ].join('\n').toLowerCase();
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
              '${entry.key} group fields drifted; update the pin manifest and'
              ' the facade copyWith together',
        );

        final accessors = _scanAccessors();
        expect(
          accessors[entry.key],
          fields,
          reason: '${entry.key} accessor extension is missing a token getter',
        );
      }

      final sentinelNames = <String>{
        ..._doubleSentinels.keys,
        ..._colorSentinels.keys,
        ..._durationSentinels.keys,
        ..._shadowSentinels.keys,
        'transcriptLinePadding',
        'echoLensOpacity',
      };
      expect(
        sentinelNames,
        _tokenGroups.values.expand((names) => names).toSet(),
      );
    });

    test('per-token sentinels are unique and absent from the defaults', () {
      final sources = _defaultSources();

      expect(_doubleSentinels.values.toSet().length, _doubleSentinels.length);
      expect(_colorSentinels.values.toSet().length, _colorSentinels.length);
      expect(
        _durationSentinels.values.toSet().length,
        _durationSentinels.length,
      );
      expect(
        _shadowSentinels.values
            .map((shadows) => shadows.single.color.toARGB32())
            .toSet()
            .length,
        _shadowSentinels.length,
      );

      for (final entry in _doubleSentinels.entries) {
        expect(
          sources.contains('${entry.value}'),
          isFalse,
          reason:
              '${entry.key} sentinel ${entry.value} collides with a default',
        );
      }
      for (final entry in _colorSentinels.entries) {
        expect(
          sources.contains('0x${entry.value.toARGB32().toRadixString(16)}'),
          isFalse,
          reason: '${entry.key} sentinel collides with a default color',
        );
      }
      for (final entry in _durationSentinels.entries) {
        expect(
          sources.contains('milliseconds: ${entry.value.inMilliseconds}'),
          isFalse,
          reason: '${entry.key} sentinel collides with a default duration',
        );
      }
      for (final entry in _shadowSentinels.entries) {
        expect(
          sources.contains(
            '0x${entry.value.single.color.toARGB32().toRadixString(16)}',
          ),
          isFalse,
          reason: '${entry.key} sentinel collides with a default shadow color',
        );
      }
      expect(sources.contains('edgeinsets.all(9)'), isFalse);
      expect(sources.contains('[1.5]'), isFalse);
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
        space4: _doubleSentinels['space4'],
        space8: _doubleSentinels['space8'],
        space12: _doubleSentinels['space12'],
        space16: _doubleSentinels['space16'],
        space20: _doubleSentinels['space20'],
        space24: _doubleSentinels['space24'],
        space32: _doubleSentinels['space32'],
        space40: _doubleSentinels['space40'],
        space48: _doubleSentinels['space48'],
        pageGutterCompact: _doubleSentinels['pageGutterCompact'],
        pageGutter: _doubleSentinels['pageGutter'],
        desktopGutter: _doubleSentinels['desktopGutter'],
        marginWidth: _doubleSentinels['marginWidth'],
        gutter: _doubleSentinels['gutter'],
        gutterPhone: _doubleSentinels['gutterPhone'],
        radiusSm: _doubleSentinels['radiusSm'],
        radiusMd: _doubleSentinels['radiusMd'],
        radiusLg: _doubleSentinels['radiusLg'],
        radiusXl: _doubleSentinels['radiusXl'],
        radiusFull: _doubleSentinels['radiusFull'],
        radiusXs: _doubleSentinels['radiusXs'],
        radius2xl: _doubleSentinels['radius2xl'],
        panelRadius: _doubleSentinels['panelRadius'],
        radiusKeycap: _doubleSentinels['radiusKeycap'],
        radiusBadge: _doubleSentinels['radiusBadge'],
        radiusSegmentThumb: _doubleSentinels['radiusSegmentThumb'],
        radiusControl: _doubleSentinels['radiusControl'],
        radiusTile: _doubleSentinels['radiusTile'],
        radiusCard: _doubleSentinels['radiusCard'],
        radiusCardLarge: _doubleSentinels['radiusCardLarge'],
        radiusDialog: _doubleSentinels['radiusDialog'],
        radiusSheet: _doubleSentinels['radiusSheet'],
        motionFast: _durationSentinels['motionFast'],
        motionStandard: _durationSentinels['motionStandard'],
        motionEnter: _durationSentinels['motionEnter'],
        motionExit: _durationSentinels['motionExit'],
        motionMedium: _durationSentinels['motionMedium'],
        motionLens: _durationSentinels['motionLens'],
        motionMargin: _durationSentinels['motionMargin'],
        elevationNone: _doubleSentinels['elevationNone'],
        elevationCard: _doubleSentinels['elevationCard'],
        elevationSheet: _doubleSentinels['elevationSheet'],
        elevationModal: _doubleSentinels['elevationModal'],
        elevationBar: _doubleSentinels['elevationBar'],
        elevationSurface: _doubleSentinels['elevationSurface'],
        focusRingWidth: _doubleSentinels['focusRingWidth'],
        shadowLift: _shadowSentinels['shadowLift'],
        shadowFloat: _shadowSentinels['shadowFloat'],
        shadowPopover: _shadowSentinels['shadowPopover'],
        strokeReferencePitch: _doubleSentinels['strokeReferencePitch'],
        strokeYourPitch: _doubleSentinels['strokeYourPitch'],
        strokeLoopBracket: _doubleSentinels['strokeLoopBracket'],
        strokeRulerTrack: _doubleSentinels['strokeRulerTrack'],
        shadowBrandButton: _shadowSentinels['shadowBrandButton'],
        shadowRecordButton: _shadowSentinels['shadowRecordButton'],
        breakpointCompact: _doubleSentinels['breakpointCompact'],
        breakpointRail: _doubleSentinels['breakpointRail'],
        breakpointTranscriptSideBySide:
            _doubleSentinels['breakpointTranscriptSideBySide'],
        breakpointMarginDrawer: _doubleSentinels['breakpointMarginDrawer'],
        contentMaxWidth: _doubleSentinels['contentMaxWidth'],
        formMaxWidth: _doubleSentinels['formMaxWidth'],
        hubMaxWidth: _doubleSentinels['hubMaxWidth'],
        sidebarWidth: _doubleSentinels['sidebarWidth'],
        sidebarBrandHeight: _doubleSentinels['sidebarBrandHeight'],
        transportHeight: _doubleSentinels['transportHeight'],
        bottomNavHeight: _doubleSentinels['bottomNavHeight'],
        modalMaxWidth: _doubleSentinels['modalMaxWidth'],
        modalMaxWidthLarge: _doubleSentinels['modalMaxWidthLarge'],
        shellInset: _doubleSentinels['shellInset'],
        tabBarHeight: _doubleSentinels['tabBarHeight'],
        tabBarSafeInset: _doubleSentinels['tabBarSafeInset'],
        playerTopBarHeight: _doubleSentinels['playerTopBarHeight'],
        subpageHeaderHeight: _doubleSentinels['subpageHeaderHeight'],
        rulerHitHeight: _doubleSentinels['rulerHitHeight'],
        transcriptMaxListen: _doubleSentinels['transcriptMaxListen'],
        transcriptMaxEcho: _doubleSentinels['transcriptMaxEcho'],
        videoColumnMin: _doubleSentinels['videoColumnMin'],
        videoColumnMax: _doubleSentinels['videoColumnMax'],
        videoColumnShare: _doubleSentinels['videoColumnShare'],
        pageMaxBrowse: _doubleSentinels['pageMaxBrowse'],
        pageMaxCraft: _doubleSentinels['pageMaxCraft'],
        pageMaxHub: _doubleSentinels['pageMaxHub'],
        pageMaxForm: _doubleSentinels['pageMaxForm'],
        miniBarBlurSigma: _doubleSentinels['miniBarBlurSigma'],
        heroTitleLetterSpacing: _doubleSentinels['heroTitleLetterSpacing'],
        controlHeightSm: _doubleSentinels['controlHeightSm'],
        controlHeight: _doubleSentinels['controlHeight'],
        controlHeightLg: _doubleSentinels['controlHeightLg'],
        touchTargetMin: _doubleSentinels['touchTargetMin'],
        iconButtonSize: _doubleSentinels['iconButtonSize'],
        iconButtonSizePhone: _doubleSentinels['iconButtonSizePhone'],
        segmentHeight: _doubleSentinels['segmentHeight'],
        chipHeight: _doubleSentinels['chipHeight'],
        takeChipHeight: _doubleSentinels['takeChipHeight'],
        playButtonSize: _doubleSentinels['playButtonSize'],
        playButtonSizePhone: _doubleSentinels['playButtonSizePhone'],
        recordButtonSize: _doubleSentinels['recordButtonSize'],
        recordButtonSizePhone: _doubleSentinels['recordButtonSizePhone'],
        originalPillWidth: _doubleSentinels['originalPillWidth'],
        originalPillHeight: _doubleSentinels['originalPillHeight'],
        originalButtonPhoneSize: _doubleSentinels['originalButtonPhoneSize'],
        glassTint: _colorSentinels['glassTint'],
        glassBorder: _colorSentinels['glassBorder'],
        gradientStart: _colorSentinels['gradientStart'],
        gradientEnd: _colorSentinels['gradientEnd'],
        canvas: _colorSentinels['canvas'],
        card: _colorSentinels['card'],
        popover: _colorSentinels['popover'],
        hairline: _colorSentinels['hairline'],
        fill: _colorSentinels['fill'],
        textFaint: _colorSentinels['textFaint'],
        logoStart: _colorSentinels['logoStart'],
        logoEnd: _colorSentinels['logoEnd'],
        topHighlight: _colorSentinels['topHighlight'],
        ground: _colorSentinels['ground'],
        paper: _colorSentinels['paper'],
        raised: _colorSentinels['raised'],
        sunk: _colorSentinels['sunk'],
        line: _colorSentinels['line'],
        ink: _colorSentinels['ink'],
        ink2: _colorSentinels['ink2'],
        ink3: _colorSentinels['ink3'],
        shape: _colorSentinels['shape'],
        tick: _colorSentinels['tick'],
        scrim: _colorSentinels['scrim'],
        video: _colorSentinels['video'],
        echoActive: _colorSentinels['echoActive'],
        blurActive: _colorSentinels['blurActive'],
        scoreGood: _colorSentinels['scoreGood'],
        scoreWarn: _colorSentinels['scoreWarn'],
        scoreBad: _colorSentinels['scoreBad'],
        scoreGoodContainer: _colorSentinels['scoreGoodContainer'],
        scoreWarnContainer: _colorSentinels['scoreWarnContainer'],
        scoreBadContainer: _colorSentinels['scoreBadContainer'],
        accentSoft: _colorSentinels['accentSoft'],
        accentInk: _colorSentinels['accentInk'],
        intelligenceInk: _colorSentinels['intelligenceInk'],
        echoInk: _colorSentinels['echoInk'],
        ccBadge: _colorSentinels['ccBadge'],
        original: _colorSentinels['original'],
        originalInk: _colorSentinels['originalInk'],
        originalSoft: _colorSentinels['originalSoft'],
        you: _colorSentinels['you'],
        youInk: _colorSentinels['youInk'],
        youSoft: _colorSentinels['youSoft'],
        youLine: _colorSentinels['youLine'],
        originalLine: _colorSentinels['originalLine'],
        onYou: _colorSentinels['onYou'],
        brandInk: _colorSentinels['brandInk'],
        brandSoft: _colorSentinels['brandSoft'],
        primary: _colorSentinels['primary'],
        onPrimary: _colorSentinels['onPrimary'],
        danger: _colorSentinels['danger'],
        vocabNew: _colorSentinels['vocabNew'],
        vocabLearning: _colorSentinels['vocabLearning'],
        vocabReviewing: _colorSentinels['vocabReviewing'],
        vocabMastered: _colorSentinels['vocabMastered'],
        transcriptLinePadding: _sentinelPadding,
        echoLensOpacity: _sentinelLens,
        referencePitchOpacity: _doubleSentinels['referencePitchOpacity'],
      );

      expect(copy.space4, _doubleSentinels['space4']);
      expect(copy.space8, _doubleSentinels['space8']);
      expect(copy.space12, _doubleSentinels['space12']);
      expect(copy.space16, _doubleSentinels['space16']);
      expect(copy.space20, _doubleSentinels['space20']);
      expect(copy.space24, _doubleSentinels['space24']);
      expect(copy.space32, _doubleSentinels['space32']);
      expect(copy.space40, _doubleSentinels['space40']);
      expect(copy.space48, _doubleSentinels['space48']);
      expect(copy.pageGutterCompact, _doubleSentinels['pageGutterCompact']);
      expect(copy.pageGutter, _doubleSentinels['pageGutter']);
      expect(copy.desktopGutter, _doubleSentinels['desktopGutter']);
      expect(copy.marginWidth, _doubleSentinels['marginWidth']);
      expect(copy.gutter, _doubleSentinels['gutter']);
      expect(copy.gutterPhone, _doubleSentinels['gutterPhone']);
      expect(copy.radiusSm, _doubleSentinels['radiusSm']);
      expect(copy.radiusMd, _doubleSentinels['radiusMd']);
      expect(copy.radiusLg, _doubleSentinels['radiusLg']);
      expect(copy.radiusXl, _doubleSentinels['radiusXl']);
      expect(copy.radiusFull, _doubleSentinels['radiusFull']);
      expect(copy.radiusXs, _doubleSentinels['radiusXs']);
      expect(copy.radius2xl, _doubleSentinels['radius2xl']);
      expect(copy.panelRadius, _doubleSentinels['panelRadius']);
      expect(copy.radiusKeycap, _doubleSentinels['radiusKeycap']);
      expect(copy.radiusBadge, _doubleSentinels['radiusBadge']);
      expect(copy.radiusSegmentThumb, _doubleSentinels['radiusSegmentThumb']);
      expect(copy.radiusControl, _doubleSentinels['radiusControl']);
      expect(copy.radiusTile, _doubleSentinels['radiusTile']);
      expect(copy.radiusCard, _doubleSentinels['radiusCard']);
      expect(copy.radiusCardLarge, _doubleSentinels['radiusCardLarge']);
      expect(copy.radiusDialog, _doubleSentinels['radiusDialog']);
      expect(copy.radiusSheet, _doubleSentinels['radiusSheet']);
      expect(copy.motionFast, _durationSentinels['motionFast']);
      expect(copy.motionStandard, _durationSentinels['motionStandard']);
      expect(copy.motionEnter, _durationSentinels['motionEnter']);
      expect(copy.motionExit, _durationSentinels['motionExit']);
      expect(copy.motionMedium, _durationSentinels['motionMedium']);
      expect(copy.motionLens, _durationSentinels['motionLens']);
      expect(copy.motionMargin, _durationSentinels['motionMargin']);
      expect(copy.elevationNone, _doubleSentinels['elevationNone']);
      expect(copy.elevationCard, _doubleSentinels['elevationCard']);
      expect(copy.elevationSheet, _doubleSentinels['elevationSheet']);
      expect(copy.elevationModal, _doubleSentinels['elevationModal']);
      expect(copy.elevationBar, _doubleSentinels['elevationBar']);
      expect(copy.elevationSurface, _doubleSentinels['elevationSurface']);
      expect(copy.focusRingWidth, _doubleSentinels['focusRingWidth']);
      expect(copy.shadowLift, _shadowSentinels['shadowLift']);
      expect(copy.shadowFloat, _shadowSentinels['shadowFloat']);
      expect(copy.shadowPopover, _shadowSentinels['shadowPopover']);
      expect(
        copy.strokeReferencePitch,
        _doubleSentinels['strokeReferencePitch'],
      );
      expect(copy.strokeYourPitch, _doubleSentinels['strokeYourPitch']);
      expect(copy.strokeLoopBracket, _doubleSentinels['strokeLoopBracket']);
      expect(copy.strokeRulerTrack, _doubleSentinels['strokeRulerTrack']);
      expect(copy.shadowBrandButton, _shadowSentinels['shadowBrandButton']);
      expect(copy.shadowRecordButton, _shadowSentinels['shadowRecordButton']);
      expect(copy.breakpointCompact, _doubleSentinels['breakpointCompact']);
      expect(copy.breakpointRail, _doubleSentinels['breakpointRail']);
      expect(
        copy.breakpointTranscriptSideBySide,
        _doubleSentinels['breakpointTranscriptSideBySide'],
      );
      expect(
        copy.breakpointMarginDrawer,
        _doubleSentinels['breakpointMarginDrawer'],
      );
      expect(copy.contentMaxWidth, _doubleSentinels['contentMaxWidth']);
      expect(copy.formMaxWidth, _doubleSentinels['formMaxWidth']);
      expect(copy.hubMaxWidth, _doubleSentinels['hubMaxWidth']);
      expect(copy.sidebarWidth, _doubleSentinels['sidebarWidth']);
      expect(copy.sidebarBrandHeight, _doubleSentinels['sidebarBrandHeight']);
      expect(copy.transportHeight, _doubleSentinels['transportHeight']);
      expect(copy.bottomNavHeight, _doubleSentinels['bottomNavHeight']);
      expect(copy.modalMaxWidth, _doubleSentinels['modalMaxWidth']);
      expect(copy.modalMaxWidthLarge, _doubleSentinels['modalMaxWidthLarge']);
      expect(copy.shellInset, _doubleSentinels['shellInset']);
      expect(copy.tabBarHeight, _doubleSentinels['tabBarHeight']);
      expect(copy.tabBarSafeInset, _doubleSentinels['tabBarSafeInset']);
      expect(copy.playerTopBarHeight, _doubleSentinels['playerTopBarHeight']);
      expect(copy.subpageHeaderHeight, _doubleSentinels['subpageHeaderHeight']);
      expect(copy.rulerHitHeight, _doubleSentinels['rulerHitHeight']);
      expect(copy.transcriptMaxListen, _doubleSentinels['transcriptMaxListen']);
      expect(copy.transcriptMaxEcho, _doubleSentinels['transcriptMaxEcho']);
      expect(copy.videoColumnMin, _doubleSentinels['videoColumnMin']);
      expect(copy.videoColumnMax, _doubleSentinels['videoColumnMax']);
      expect(copy.videoColumnShare, _doubleSentinels['videoColumnShare']);
      expect(copy.pageMaxBrowse, _doubleSentinels['pageMaxBrowse']);
      expect(copy.pageMaxCraft, _doubleSentinels['pageMaxCraft']);
      expect(copy.pageMaxHub, _doubleSentinels['pageMaxHub']);
      expect(copy.pageMaxForm, _doubleSentinels['pageMaxForm']);
      expect(copy.miniBarBlurSigma, _doubleSentinels['miniBarBlurSigma']);
      expect(
        copy.heroTitleLetterSpacing,
        _doubleSentinels['heroTitleLetterSpacing'],
      );
      expect(copy.controlHeightSm, _doubleSentinels['controlHeightSm']);
      expect(copy.controlHeight, _doubleSentinels['controlHeight']);
      expect(copy.controlHeightLg, _doubleSentinels['controlHeightLg']);
      expect(copy.touchTargetMin, _doubleSentinels['touchTargetMin']);
      expect(copy.iconButtonSize, _doubleSentinels['iconButtonSize']);
      expect(copy.iconButtonSizePhone, _doubleSentinels['iconButtonSizePhone']);
      expect(copy.segmentHeight, _doubleSentinels['segmentHeight']);
      expect(copy.chipHeight, _doubleSentinels['chipHeight']);
      expect(copy.takeChipHeight, _doubleSentinels['takeChipHeight']);
      expect(copy.playButtonSize, _doubleSentinels['playButtonSize']);
      expect(copy.playButtonSizePhone, _doubleSentinels['playButtonSizePhone']);
      expect(copy.recordButtonSize, _doubleSentinels['recordButtonSize']);
      expect(
        copy.recordButtonSizePhone,
        _doubleSentinels['recordButtonSizePhone'],
      );
      expect(copy.originalPillWidth, _doubleSentinels['originalPillWidth']);
      expect(copy.originalPillHeight, _doubleSentinels['originalPillHeight']);
      expect(
        copy.originalButtonPhoneSize,
        _doubleSentinels['originalButtonPhoneSize'],
      );
      expect(copy.glassTint, _colorSentinels['glassTint']);
      expect(copy.glassBorder, _colorSentinels['glassBorder']);
      expect(copy.gradientStart, _colorSentinels['gradientStart']);
      expect(copy.gradientEnd, _colorSentinels['gradientEnd']);
      expect(copy.canvas, _colorSentinels['canvas']);
      expect(copy.card, _colorSentinels['card']);
      expect(copy.popover, _colorSentinels['popover']);
      expect(copy.hairline, _colorSentinels['hairline']);
      expect(copy.fill, _colorSentinels['fill']);
      expect(copy.textFaint, _colorSentinels['textFaint']);
      expect(copy.logoStart, _colorSentinels['logoStart']);
      expect(copy.logoEnd, _colorSentinels['logoEnd']);
      expect(copy.topHighlight, _colorSentinels['topHighlight']);
      expect(copy.ground, _colorSentinels['ground']);
      expect(copy.paper, _colorSentinels['paper']);
      expect(copy.raised, _colorSentinels['raised']);
      expect(copy.sunk, _colorSentinels['sunk']);
      expect(copy.line, _colorSentinels['line']);
      expect(copy.ink, _colorSentinels['ink']);
      expect(copy.ink2, _colorSentinels['ink2']);
      expect(copy.ink3, _colorSentinels['ink3']);
      expect(copy.shape, _colorSentinels['shape']);
      expect(copy.tick, _colorSentinels['tick']);
      expect(copy.scrim, _colorSentinels['scrim']);
      expect(copy.video, _colorSentinels['video']);
      expect(copy.echoActive, _colorSentinels['echoActive']);
      expect(copy.blurActive, _colorSentinels['blurActive']);
      expect(copy.scoreGood, _colorSentinels['scoreGood']);
      expect(copy.scoreWarn, _colorSentinels['scoreWarn']);
      expect(copy.scoreBad, _colorSentinels['scoreBad']);
      expect(copy.scoreGoodContainer, _colorSentinels['scoreGoodContainer']);
      expect(copy.scoreWarnContainer, _colorSentinels['scoreWarnContainer']);
      expect(copy.scoreBadContainer, _colorSentinels['scoreBadContainer']);
      expect(copy.accentSoft, _colorSentinels['accentSoft']);
      expect(copy.accentInk, _colorSentinels['accentInk']);
      expect(copy.intelligenceInk, _colorSentinels['intelligenceInk']);
      expect(copy.echoInk, _colorSentinels['echoInk']);
      expect(copy.ccBadge, _colorSentinels['ccBadge']);
      expect(copy.original, _colorSentinels['original']);
      expect(copy.originalInk, _colorSentinels['originalInk']);
      expect(copy.originalSoft, _colorSentinels['originalSoft']);
      expect(copy.you, _colorSentinels['you']);
      expect(copy.youInk, _colorSentinels['youInk']);
      expect(copy.youSoft, _colorSentinels['youSoft']);
      expect(copy.youLine, _colorSentinels['youLine']);
      expect(copy.originalLine, _colorSentinels['originalLine']);
      expect(copy.onYou, _colorSentinels['onYou']);
      expect(copy.brandInk, _colorSentinels['brandInk']);
      expect(copy.brandSoft, _colorSentinels['brandSoft']);
      expect(copy.primary, _colorSentinels['primary']);
      expect(copy.onPrimary, _colorSentinels['onPrimary']);
      expect(copy.danger, _colorSentinels['danger']);
      expect(copy.vocabNew, _colorSentinels['vocabNew']);
      expect(copy.vocabLearning, _colorSentinels['vocabLearning']);
      expect(copy.vocabReviewing, _colorSentinels['vocabReviewing']);
      expect(copy.vocabMastered, _colorSentinels['vocabMastered']);
      expect(copy.transcriptLinePadding, _sentinelPadding);
      expect(copy.echoLensOpacity, _sentinelLens);
      expect(
        copy.referencePitchOpacity,
        _doubleSentinels['referencePitchOpacity'],
      );
    });

    test('copyWith with no overrides preserves every token', () {
      final tokens = EnjoyThemeTokens.build(const ColorScheme.dark());
      final copy = tokens.copyWith();

      expect(copy.space4, tokens.space4);
      expect(copy.space8, tokens.space8);
      expect(copy.space12, tokens.space12);
      expect(copy.space16, tokens.space16);
      expect(copy.space20, tokens.space20);
      expect(copy.space24, tokens.space24);
      expect(copy.space32, tokens.space32);
      expect(copy.space40, tokens.space40);
      expect(copy.space48, tokens.space48);
      expect(copy.pageGutterCompact, tokens.pageGutterCompact);
      expect(copy.pageGutter, tokens.pageGutter);
      expect(copy.desktopGutter, tokens.desktopGutter);
      expect(copy.marginWidth, tokens.marginWidth);
      expect(copy.gutter, tokens.gutter);
      expect(copy.gutterPhone, tokens.gutterPhone);
      expect(copy.radiusSm, tokens.radiusSm);
      expect(copy.radiusMd, tokens.radiusMd);
      expect(copy.radiusLg, tokens.radiusLg);
      expect(copy.radiusXl, tokens.radiusXl);
      expect(copy.radiusFull, tokens.radiusFull);
      expect(copy.radiusXs, tokens.radiusXs);
      expect(copy.radius2xl, tokens.radius2xl);
      expect(copy.panelRadius, tokens.panelRadius);
      expect(copy.radiusKeycap, tokens.radiusKeycap);
      expect(copy.radiusBadge, tokens.radiusBadge);
      expect(copy.radiusSegmentThumb, tokens.radiusSegmentThumb);
      expect(copy.radiusControl, tokens.radiusControl);
      expect(copy.radiusTile, tokens.radiusTile);
      expect(copy.radiusCard, tokens.radiusCard);
      expect(copy.radiusCardLarge, tokens.radiusCardLarge);
      expect(copy.radiusDialog, tokens.radiusDialog);
      expect(copy.radiusSheet, tokens.radiusSheet);
      expect(copy.motionFast, tokens.motionFast);
      expect(copy.motionStandard, tokens.motionStandard);
      expect(copy.motionEnter, tokens.motionEnter);
      expect(copy.motionExit, tokens.motionExit);
      expect(copy.motionMedium, tokens.motionMedium);
      expect(copy.motionLens, tokens.motionLens);
      expect(copy.motionMargin, tokens.motionMargin);
      expect(copy.elevationNone, tokens.elevationNone);
      expect(copy.elevationCard, tokens.elevationCard);
      expect(copy.elevationSheet, tokens.elevationSheet);
      expect(copy.elevationModal, tokens.elevationModal);
      expect(copy.elevationBar, tokens.elevationBar);
      expect(copy.elevationSurface, tokens.elevationSurface);
      expect(copy.focusRingWidth, tokens.focusRingWidth);
      expect(copy.shadowLift, tokens.shadowLift);
      expect(copy.shadowFloat, tokens.shadowFloat);
      expect(copy.shadowPopover, tokens.shadowPopover);
      expect(copy.strokeReferencePitch, tokens.strokeReferencePitch);
      expect(copy.strokeYourPitch, tokens.strokeYourPitch);
      expect(copy.strokeLoopBracket, tokens.strokeLoopBracket);
      expect(copy.strokeRulerTrack, tokens.strokeRulerTrack);
      expect(copy.shadowBrandButton, tokens.shadowBrandButton);
      expect(copy.shadowRecordButton, tokens.shadowRecordButton);
      expect(copy.breakpointCompact, tokens.breakpointCompact);
      expect(copy.breakpointRail, tokens.breakpointRail);
      expect(
        copy.breakpointTranscriptSideBySide,
        tokens.breakpointTranscriptSideBySide,
      );
      expect(copy.breakpointMarginDrawer, tokens.breakpointMarginDrawer);
      expect(copy.contentMaxWidth, tokens.contentMaxWidth);
      expect(copy.formMaxWidth, tokens.formMaxWidth);
      expect(copy.hubMaxWidth, tokens.hubMaxWidth);
      expect(copy.sidebarWidth, tokens.sidebarWidth);
      expect(copy.sidebarBrandHeight, tokens.sidebarBrandHeight);
      expect(copy.transportHeight, tokens.transportHeight);
      expect(copy.bottomNavHeight, tokens.bottomNavHeight);
      expect(copy.modalMaxWidth, tokens.modalMaxWidth);
      expect(copy.modalMaxWidthLarge, tokens.modalMaxWidthLarge);
      expect(copy.shellInset, tokens.shellInset);
      expect(copy.tabBarHeight, tokens.tabBarHeight);
      expect(copy.tabBarSafeInset, tokens.tabBarSafeInset);
      expect(copy.playerTopBarHeight, tokens.playerTopBarHeight);
      expect(copy.subpageHeaderHeight, tokens.subpageHeaderHeight);
      expect(copy.rulerHitHeight, tokens.rulerHitHeight);
      expect(copy.transcriptMaxListen, tokens.transcriptMaxListen);
      expect(copy.transcriptMaxEcho, tokens.transcriptMaxEcho);
      expect(copy.videoColumnMin, tokens.videoColumnMin);
      expect(copy.videoColumnMax, tokens.videoColumnMax);
      expect(copy.videoColumnShare, tokens.videoColumnShare);
      expect(copy.pageMaxBrowse, tokens.pageMaxBrowse);
      expect(copy.pageMaxCraft, tokens.pageMaxCraft);
      expect(copy.pageMaxHub, tokens.pageMaxHub);
      expect(copy.pageMaxForm, tokens.pageMaxForm);
      expect(copy.miniBarBlurSigma, tokens.miniBarBlurSigma);
      expect(copy.heroTitleLetterSpacing, tokens.heroTitleLetterSpacing);
      expect(copy.controlHeightSm, tokens.controlHeightSm);
      expect(copy.controlHeight, tokens.controlHeight);
      expect(copy.controlHeightLg, tokens.controlHeightLg);
      expect(copy.touchTargetMin, tokens.touchTargetMin);
      expect(copy.iconButtonSize, tokens.iconButtonSize);
      expect(copy.iconButtonSizePhone, tokens.iconButtonSizePhone);
      expect(copy.segmentHeight, tokens.segmentHeight);
      expect(copy.chipHeight, tokens.chipHeight);
      expect(copy.takeChipHeight, tokens.takeChipHeight);
      expect(copy.playButtonSize, tokens.playButtonSize);
      expect(copy.playButtonSizePhone, tokens.playButtonSizePhone);
      expect(copy.recordButtonSize, tokens.recordButtonSize);
      expect(copy.recordButtonSizePhone, tokens.recordButtonSizePhone);
      expect(copy.originalPillWidth, tokens.originalPillWidth);
      expect(copy.originalPillHeight, tokens.originalPillHeight);
      expect(copy.originalButtonPhoneSize, tokens.originalButtonPhoneSize);
      expect(copy.glassTint, tokens.glassTint);
      expect(copy.glassBorder, tokens.glassBorder);
      expect(copy.gradientStart, tokens.gradientStart);
      expect(copy.gradientEnd, tokens.gradientEnd);
      expect(copy.canvas, tokens.canvas);
      expect(copy.card, tokens.card);
      expect(copy.popover, tokens.popover);
      expect(copy.hairline, tokens.hairline);
      expect(copy.fill, tokens.fill);
      expect(copy.textFaint, tokens.textFaint);
      expect(copy.logoStart, tokens.logoStart);
      expect(copy.logoEnd, tokens.logoEnd);
      expect(copy.topHighlight, tokens.topHighlight);
      expect(copy.ground, tokens.ground);
      expect(copy.paper, tokens.paper);
      expect(copy.raised, tokens.raised);
      expect(copy.sunk, tokens.sunk);
      expect(copy.line, tokens.line);
      expect(copy.ink, tokens.ink);
      expect(copy.ink2, tokens.ink2);
      expect(copy.ink3, tokens.ink3);
      expect(copy.shape, tokens.shape);
      expect(copy.tick, tokens.tick);
      expect(copy.scrim, tokens.scrim);
      expect(copy.video, tokens.video);
      expect(copy.echoActive, tokens.echoActive);
      expect(copy.blurActive, tokens.blurActive);
      expect(copy.scoreGood, tokens.scoreGood);
      expect(copy.scoreWarn, tokens.scoreWarn);
      expect(copy.scoreBad, tokens.scoreBad);
      expect(copy.scoreGoodContainer, tokens.scoreGoodContainer);
      expect(copy.scoreWarnContainer, tokens.scoreWarnContainer);
      expect(copy.scoreBadContainer, tokens.scoreBadContainer);
      expect(copy.accentSoft, tokens.accentSoft);
      expect(copy.accentInk, tokens.accentInk);
      expect(copy.intelligenceInk, tokens.intelligenceInk);
      expect(copy.echoInk, tokens.echoInk);
      expect(copy.ccBadge, tokens.ccBadge);
      expect(copy.original, tokens.original);
      expect(copy.originalInk, tokens.originalInk);
      expect(copy.originalSoft, tokens.originalSoft);
      expect(copy.you, tokens.you);
      expect(copy.youInk, tokens.youInk);
      expect(copy.youSoft, tokens.youSoft);
      expect(copy.youLine, tokens.youLine);
      expect(copy.originalLine, tokens.originalLine);
      expect(copy.onYou, tokens.onYou);
      expect(copy.brandInk, tokens.brandInk);
      expect(copy.brandSoft, tokens.brandSoft);
      expect(copy.primary, tokens.primary);
      expect(copy.onPrimary, tokens.onPrimary);
      expect(copy.danger, tokens.danger);
      expect(copy.vocabNew, tokens.vocabNew);
      expect(copy.vocabLearning, tokens.vocabLearning);
      expect(copy.vocabReviewing, tokens.vocabReviewing);
      expect(copy.vocabMastered, tokens.vocabMastered);
      expect(copy.transcriptLinePadding, tokens.transcriptLinePadding);
      expect(copy.echoLensOpacity, tokens.echoLensOpacity);
      expect(copy.referencePitchOpacity, tokens.referencePitchOpacity);
    });
  });
}
