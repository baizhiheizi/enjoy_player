import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/features/settings/application/transcript_typeface_settings.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_typeface_scope.dart';

import '../../../helpers/transcript_settings_overrides.dart';

Future<TranscriptTypographyTokens> _tokensUnder(
  WidgetTester tester,
  TranscriptTypeface typeface,
) async {
  late TranscriptTypographyTokens tokens;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        transcriptTypefaceSettingsProvider.overrideWith(
          () => TranscriptTypefaceSettingsOverride(typeface),
        ),
      ],
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: TranscriptTypefaceScope(
          child: Builder(
            builder: (context) {
              tokens = TranscriptTypographyTokens.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tokens;
}

void main() {
  testWidgets('Book keeps the Literata transcript face', (tester) async {
    final tokens = await _tokensUnder(tester, TranscriptTypeface.book);
    expect(tokens.useSerif, isTrue);
    expect(tokens.bodyStyle.fontFamily, kLiterataFamily);
  });

  testWidgets('Clean switches the transcript face to Geist', (tester) async {
    final book = buildAppTheme(
      Brightness.light,
    ).extension<TranscriptTypographyTokens>()!;
    final clean = await _tokensUnder(tester, TranscriptTypeface.clean);
    expect(clean.useSerif, isFalse);
    expect(clean.bodyStyle.fontFamily, kGeistFamily);
    expect(clean.bodyStyle.fontSize, book.bodyStyle.fontSize);
    expect(clean.secondaryStyle, book.secondaryStyle);
  });
}
