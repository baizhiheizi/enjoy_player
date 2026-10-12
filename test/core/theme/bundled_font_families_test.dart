import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/core/theme/typography.dart';

Future<Map<String, Set<int>>> _manifestWeights() async {
  final raw = await rootBundle.loadString('FontManifest.json');
  return {
    for (final entry in json.decode(raw) as List<dynamic>)
      (entry as Map<String, dynamic>)['family'] as String: {
        for (final font in entry['fonts'] as List<dynamic>)
          ((font as Map<String, dynamic>)['weight'] as int?) ?? 400,
      },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('text faces are declared as multi-weight families', () async {
    final weights = await _manifestWeights();

    expect(weights[kGeistFamily], {400, 500, 600});
    expect(weights[kLiterataFamily], {400, 500, 600});
    expect(weights[kGeistMonoFamily], {500, 600});
    expect(weights[kNotoSansFamily], {400});
  });

  test('theme and transcript styles address the declared families', () {
    for (final brightness in Brightness.values) {
      final theme = buildAppTheme(brightness);
      final tt = theme.textTheme;
      for (final style in [tt.bodyMedium, tt.labelMedium, tt.titleSmall]) {
        expect(style?.fontFamily, kGeistFamily);
      }
      expect(tt.displaySmall?.fontFamily, kLiterataFamily);

      final transcript = theme.extension<TranscriptTypographyTokens>()!;
      expect(transcript.bodyStyle.fontFamily, kLiterataFamily);
      expect(transcript.secondaryStyle.fontFamily, kNotoSansFamily);
      expect(transcript.timestampStyle.fontFamily, kGeistMonoFamily);
      expect(transcript.monoStyle.fontFamily, kGeistMonoFamily);
    }
  });
}
