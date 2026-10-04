import 'dart:convert';
import 'dart:io';
import 'package:enjoy_player/core/theme/colors.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _loadTokens() =>
    json.decode(File('docs/design/duet/tokens.json').readAsStringSync())
        as Map<String, dynamic>;

Color _parseColor(String raw) {
  if (raw.startsWith('#')) {
    return Color(0xFF000000 | int.parse(raw.substring(1), radix: 16));
  }
  final match = RegExp(
    r'rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)',
  ).firstMatch(raw);
  if (match == null) {
    throw ArgumentError.value(raw, 'raw', 'unsupported color syntax');
  }
  return Color.fromRGBO(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
    double.parse(match.group(4)!),
  );
}

final Map<String, String> _radiusFieldNames = {
  'keycap': 'radiusKeycap',
  'badge': 'radiusBadge',
  'control': 'radiusControl',
  'segmentTrack': 'radiusControl',
  'segmentThumb': 'radiusSegmentThumb',
  'input': 'radiusControl',
  'tile': 'radiusTile',
  'card': 'radiusCard',
  'cardLarge': 'radiusCardLarge',
  'dialog': 'radiusDialog',
  'sheet': 'radiusSheet',
  'pill': 'radiusFull',
};

final Map<String, String> _sizeFieldNames = {
  'touchMin': 'touchTargetMin',
  'iconButton': 'iconButtonSize',
  'iconButtonPhone': 'iconButtonSizePhone',
  'button': 'controlHeight',
  'buttonSmall': 'controlHeightSm',
  'buttonLarge': 'controlHeightLg',
  'segmentHeight': 'segmentHeight',
  'chip': 'chipHeight',
  'takeChip': 'takeChipHeight',
  'playButton': 'playButtonSize',
  'playButtonPhone': 'playButtonSizePhone',
  'recordButton': 'recordButtonSize',
  'recordButtonPhone': 'recordButtonSizePhone',
  'originalButtonPhone': 'originalButtonPhoneSize',
  'sidebarWidth': 'sidebarWidth',
  'tabBarHeight': 'tabBarHeight',
  'tabBarSafeInset': 'tabBarSafeInset',
  'playerTopBar': 'playerTopBarHeight',
  'subpageHeader': 'subpageHeaderHeight',
  'rulerHitHeight': 'rulerHitHeight',
  'marginWidth': 'marginWidth',
  'transcriptMaxListen': 'transcriptMaxListen',
  'transcriptMaxEcho': 'transcriptMaxEcho',
  'pageMaxBrowse': 'pageMaxBrowse',
  'pageMaxCraft': 'pageMaxCraft',
  'pageMaxHub': 'pageMaxHub',
  'pageMaxForm': 'pageMaxForm',
  'gutter': 'gutter',
  'gutterPhone': 'gutterPhone',
};

final Map<String, String> _breakpointFieldNames = {
  'compact': 'breakpointCompact',
  'rail': 'breakpointRail',
  'marginDrawer': 'breakpointMarginDrawer',
};

final Map<String, Object? Function(EnjoyThemeTokens)> _tokenFields = {
  'ground': (t) => t.ground,
  'paper': (t) => t.paper,
  'raised': (t) => t.raised,
  'sunk': (t) => t.sunk,
  'line': (t) => t.line,
  'ink': (t) => t.ink,
  'ink2': (t) => t.ink2,
  'ink3': (t) => t.ink3,
  'original': (t) => t.original,
  'originalInk': (t) => t.originalInk,
  'originalSoft': (t) => t.originalSoft,
  'you': (t) => t.you,
  'youInk': (t) => t.youInk,
  'youSoft': (t) => t.youSoft,
  'youLine': (t) => t.youLine,
  'onYou': (t) => t.onYou,
  'brandInk': (t) => t.brandInk,
  'brandSoft': (t) => t.brandSoft,
  'primary': (t) => t.primary,
  'onPrimary': (t) => t.onPrimary,
  'danger': (t) => t.danger,
  'shape': (t) => t.shape,
  'tick': (t) => t.tick,
  'scrim': (t) => t.scrim,
  'video': (t) => t.video,
  'vocabNew': (t) => t.vocabNew,
  'vocabLearning': (t) => t.vocabLearning,
  'vocabReviewing': (t) => t.vocabReviewing,
  'vocabMastered': (t) => t.vocabMastered,
  'radiusKeycap': (t) => t.radiusKeycap,
  'radiusBadge': (t) => t.radiusBadge,
  'radiusSegmentThumb': (t) => t.radiusSegmentThumb,
  'radiusControl': (t) => t.radiusControl,
  'radiusTile': (t) => t.radiusTile,
  'radiusCard': (t) => t.radiusCard,
  'radiusCardLarge': (t) => t.radiusCardLarge,
  'radiusDialog': (t) => t.radiusDialog,
  'radiusSheet': (t) => t.radiusSheet,
  'radiusFull': (t) => t.radiusFull,
  'touchTargetMin': (t) => t.touchTargetMin,
  'iconButtonSize': (t) => t.iconButtonSize,
  'iconButtonSizePhone': (t) => t.iconButtonSizePhone,
  'controlHeight': (t) => t.controlHeight,
  'controlHeightSm': (t) => t.controlHeightSm,
  'controlHeightLg': (t) => t.controlHeightLg,
  'segmentHeight': (t) => t.segmentHeight,
  'chipHeight': (t) => t.chipHeight,
  'takeChipHeight': (t) => t.takeChipHeight,
  'playButtonSize': (t) => t.playButtonSize,
  'playButtonSizePhone': (t) => t.playButtonSizePhone,
  'recordButtonSize': (t) => t.recordButtonSize,
  'recordButtonSizePhone': (t) => t.recordButtonSizePhone,
  'originalPillWidth': (t) => t.originalPillWidth,
  'originalPillHeight': (t) => t.originalPillHeight,
  'originalButtonPhoneSize': (t) => t.originalButtonPhoneSize,
  'sidebarWidth': (t) => t.sidebarWidth,
  'tabBarHeight': (t) => t.tabBarHeight,
  'tabBarSafeInset': (t) => t.tabBarSafeInset,
  'playerTopBarHeight': (t) => t.playerTopBarHeight,
  'subpageHeaderHeight': (t) => t.subpageHeaderHeight,
  'rulerHitHeight': (t) => t.rulerHitHeight,
  'marginWidth': (t) => t.marginWidth,
  'transcriptMaxListen': (t) => t.transcriptMaxListen,
  'transcriptMaxEcho': (t) => t.transcriptMaxEcho,
  'videoColumnMax': (t) => t.videoColumnMax,
  'videoColumnShare': (t) => t.videoColumnShare,
  'pageMaxBrowse': (t) => t.pageMaxBrowse,
  'pageMaxCraft': (t) => t.pageMaxCraft,
  'pageMaxHub': (t) => t.pageMaxHub,
  'pageMaxForm': (t) => t.pageMaxForm,
  'gutter': (t) => t.gutter,
  'gutterPhone': (t) => t.gutterPhone,
  'breakpointCompact': (t) => t.breakpointCompact,
  'breakpointRail': (t) => t.breakpointRail,
  'breakpointMarginDrawer': (t) => t.breakpointMarginDrawer,
  'motionLens': (t) => t.motionLens,
  'motionMargin': (t) => t.motionMargin,
  'motionFast': (t) => t.motionFast,
  'echoLensOpacity': (t) => t.echoLensOpacity,
  'referencePitchOpacity': (t) => t.referencePitchOpacity,
  'strokeReferencePitch': (t) => t.strokeReferencePitch,
  'strokeYourPitch': (t) => t.strokeYourPitch,
  'strokeLoopBracket': (t) => t.strokeLoopBracket,
  'strokeRulerTrack': (t) => t.strokeRulerTrack,
  'focusRingWidth': (t) => t.focusRingWidth,
};

Object? _readField(EnjoyThemeTokens tokens, String name) =>
    _tokenFields[name]!(tokens);

void _expectTokens(Map<String, dynamic> tokensJson, Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: brightness,
  );
  final tokens = EnjoyThemeTokens.build(scheme);

  final colors =
      (tokensJson['color'] as Map<String, dynamic>)[brightness.name]
          as Map<String, dynamic>;
  colors.forEach((key, value) {
    if (key == 'vocabStatus') {
      final statuses = value as Map<String, dynamic>;
      statuses.forEach((status, color) {
        expect(
          _readField(tokens, 'vocab${_capitalize(status)}'),
          _parseColor(color as String),
          reason: 'vocabStatus.$status (${brightness.name}) drifts from code',
        );
      });
      return;
    }
    expect(
      _readField(tokens, key),
      _parseColor(value as String),
      reason: 'color.$key (${brightness.name}) drifts from code',
    );
  });

  (tokensJson['radius'] as Map<String, dynamic>).forEach((key, value) {
    final field = _radiusFieldNames[key];
    expect(field, isNotNull, reason: 'radius.$key has no code mapping');
    expect(
      _readField(tokens, field!),
      (value as num).toDouble(),
      reason: 'radius.$key drifts from code',
    );
  });

  (tokensJson['size'] as Map<String, dynamic>).forEach((key, value) {
    if (key == 'originalPill') {
      final pill = value as Map<String, dynamic>;
      expect(tokens.originalPillWidth, (pill['width'] as num).toDouble());
      expect(tokens.originalPillHeight, (pill['height'] as num).toDouble());
      return;
    }
    if (key == 'videoColumn') {
      final match = RegExp(
        r'min\((\d+(?:\.\d+)?)px,\s*(\d+(?:\.\d+)?)%\)',
      ).firstMatch(value as String);
      expect(match, isNotNull, reason: 'unexpected videoColumn syntax: $value');
      expect(tokens.videoColumnMax, double.parse(match!.group(1)!));
      expect(tokens.videoColumnShare, double.parse(match.group(2)!) / 100);
      return;
    }
    final field = _sizeFieldNames[key];
    expect(field, isNotNull, reason: 'size.$key has no code mapping');
    expect(
      _readField(tokens, field!),
      (value as num).toDouble(),
      reason: 'size.$key drifts from code',
    );
  });

  (tokensJson['breakpoints'] as Map<String, dynamic>).forEach((key, value) {
    final field = _breakpointFieldNames[key];
    expect(field, isNotNull, reason: 'breakpoint.$key has no code mapping');
    expect(
      _readField(tokens, field!),
      (value as num).toDouble(),
      reason: 'breakpoint.$key drifts from code',
    );
  });

  final motion = tokensJson['motion'] as Map<String, dynamic>;
  expect(
    tokens.motionLens,
    Duration(
      milliseconds:
          (motion['lens'] as Map<String, dynamic>)['durationMs'] as int,
    ),
  );
  expect(
    tokens.motionMargin,
    Duration(
      milliseconds:
          (motion['margin'] as Map<String, dynamic>)['durationMs'] as int,
    ),
  );
  expect(
    tokens.motionFast,
    Duration(
      milliseconds:
          (motion['fast'] as Map<String, dynamic>)['durationMs'] as int,
    ),
  );

  final opacity = tokensJson['opacity'] as Map<String, dynamic>;
  expect(
    tokens.echoLensOpacity,
    (opacity['echoLens'] as List<dynamic>).map((e) => (e as num).toDouble()),
  );
  expect(
    tokens.referencePitchOpacity,
    (opacity['referencePitchBand'] as num).toDouble(),
  );

  final strokes = tokensJson['stroke'] as Map<String, dynamic>;
  strokes.forEach((key, value) {
    final field = switch (key) {
      'referencePitch' => 'strokeReferencePitch',
      'yourPitch' => 'strokeYourPitch',
      'loopBracket' => 'strokeLoopBracket',
      'rulerTrack' => 'strokeRulerTrack',
      'focusRing' => 'focusRingWidth',
      _ => null,
    };
    expect(field, isNotNull, reason: 'stroke.$key has no code mapping');
    expect(
      _readField(tokens, field!),
      (value as num).toDouble(),
      reason: 'stroke.$key drifts from code',
    );
  });

  final gradients =
      (tokensJson['color'] as Map<String, dynamic>)['gradient']
          as Map<String, dynamic>;
  final brand = gradients['brand'] as Map<String, dynamic>;
  expect(
    tokens.brand.colors,
    (brand['stops'] as List<dynamic>).map(
      (stop) => _parseColor(stop as String),
    ),
  );
  final logo = gradients['logo'] as Map<String, dynamic>;
  expect(
    tokens.logo.colors,
    (logo['stops'] as List<dynamic>).map((stop) => _parseColor(stop as String)),
  );
}

String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

void main() {
  final tokensJson = _loadTokens();

  group('duet tokens match docs/design/duet/tokens.json', () {
    test('light', () => _expectTokens(tokensJson, Brightness.light));
    test('dark', () => _expectTokens(tokensJson, Brightness.dark));
  });

  group('Aurora fields alias the Duet values', () {
    test('surfaces and inks (light)', () {
      final t = EnjoyThemeTokens.build(const ColorScheme.light());

      expect(t.canvas, t.ground);
      expect(t.card, t.paper);
      expect(t.popover, t.raised);
      expect(t.fill, t.sunk);
      expect(t.hairline, t.line);
      expect(t.textFaint, t.ink3);
      expect(t.accentInk, t.brandInk);
      expect(t.accentSoft, t.brandSoft);
      expect(t.intelligenceInk, t.originalInk);
      expect(t.echoActive, t.you);
      expect(t.echoInk, t.youInk);
      expect(t.blurActive, t.ink);
      expect(t.scoreGood, t.ink2);
      expect(t.scoreWarn, t.ink2);
      expect(t.scoreBad, t.danger);
      expect(t.scoreGoodContainer, t.sunk);
      expect(t.scoreWarnContainer, t.sunk);
      expect(t.scoreBadContainer, t.sunk);
      expect(t.glassTint, t.paper);
      expect(t.glassBorder, t.line);
      expect(t.gradientStart, t.ground);
      expect(t.gradientEnd, t.ground);
      expect(t.topHighlight, Colors.transparent);
      expect(t.shellInset, 0);
      expect(t.panelRadius, 0);
      expect(t.sidebarWidth, 244);
      expect(t.pageGutter, t.gutter);
      expect(t.pageGutterCompact, t.gutterPhone);
      expect(t.contentMaxWidth, t.transcriptMaxListen);
      expect(t.formMaxWidth, t.pageMaxForm);
      expect(t.hubMaxWidth, t.pageMaxHub);
      expect(t.auroraStart, AppColors.logoStart);
      expect(t.auroraEnd, AppColors.logoEnd);
      expect(t.brandInk, AppColors.brandInkLight);
    });

    test('surfaces and inks (dark)', () {
      final t = EnjoyThemeTokens.build(const ColorScheme.dark());

      expect(t.canvas, t.ground);
      expect(t.card, t.paper);
      expect(t.accentInk, AppColors.brandInkDark);
      expect(t.you, AppColors.youDark);
      expect(t.scoreBad, AppColors.dangerDark);
      expect(t.video, AppColors.videoDark);
    });

    test('the two voices keep a lightness gap in both themes', () {
      final light = EnjoyThemeTokens.build(const ColorScheme.light());
      final dark = EnjoyThemeTokens.build(const ColorScheme.dark());

      double lightness(Color c) => 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;

      final originalLightL = lightness(light.original);
      final youLightL = lightness(light.you);
      expect(originalLightL / youLightL, greaterThanOrEqualTo(1.5));
      expect(youLightL / originalLightL, lessThanOrEqualTo(1 / 1.5));

      final originalDarkL = lightness(dark.original);
      final youDarkL = lightness(dark.you);
      expect(originalDarkL / youDarkL, greaterThanOrEqualTo(1.5));
      expect(youDarkL / originalDarkL, lessThanOrEqualTo(1 / 1.5));
    });
  });
}
