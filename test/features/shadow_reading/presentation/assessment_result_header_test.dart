import 'dart:convert';

import 'package:azure_speech/azure_speech.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/assessment_result_dialog.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/assessment_result_header.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/assessment_result_sheet.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const _kJson = '''
{
  "RecognitionStatus": "Success",
  "Offset": 0,
  "Duration": 10000000,
  "DisplayText": "Hi there friend.",
  "NBest": [
    {
      "Confidence": 0.9,
      "Lexical": "hi there friend",
      "ITN": "hi there friend",
      "MaskedITN": "hi there friend",
      "Display": "Hi there friend.",
      "PronunciationAssessment": {
        "AccuracyScore": 90,
        "FluencyScore": 88,
        "CompletenessScore": 95,
        "PronScore": 91,
        "ProsodyScore": 80
      },
      "Words": [
        {
          "Word": "hi",
          "Offset": 0,
          "Duration": 10000000,
          "PronunciationAssessment": {
            "AccuracyScore": 92,
            "ErrorType": "None"
          }
        }
      ]
    }
  ]
}''';

AzurePronunciationAssessmentResult _assessment() =>
    AzurePronunciationAssessmentResult.fromJson(
      jsonDecode(_kJson) as Map<String, dynamic>,
    );

Widget _wrap(Widget child) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF003366));
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: scheme,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(child: SizedBox(width: 600, height: 600, child: child)),
      ),
    ),
  );
}

late final AppLocalizations l10n;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  try {
    MediaKit.ensureInitialized();
  } on Object catch (e) {
    test('(skipped) media_kit native library not available', () {}, skip: '$e');
    return;
  }

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets('the dialog and the sheet mount the same header', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AssessmentResultDialog(assessment: _assessment(), localeTag: 'en-US'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AssessmentResultHeader), findsOneWidget);
    expect(find.text(l10n.assessmentTitle), findsOneWidget);
    expect(find.text(l10n.assessmentDescription), findsOneWidget);
    expect(find.byIcon(EnjoyIcons.close), findsOneWidget);

    await tester.pumpWidget(
      _wrap(
        AssessmentResultSheet(assessment: _assessment(), localeTag: 'en-US'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AssessmentResultHeader), findsOneWidget);
    expect(find.text(l10n.assessmentTitle), findsOneWidget);
    expect(find.text(l10n.assessmentDescription), findsOneWidget);
    expect(find.byIcon(EnjoyIcons.close), findsOneWidget);
  });

  testWidgets('the close affordance is 48x48 on both surfaces', (tester) async {
    for (final child in <Widget>[
      AssessmentResultDialog(assessment: _assessment(), localeTag: 'en-US'),
      AssessmentResultSheet(assessment: _assessment(), localeTag: 'en-US'),
    ]) {
      await tester.pumpWidget(_wrap(child));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(
          find.ancestor(
            of: find.byIcon(EnjoyIcons.close),
            matching: find.byType(IconButton),
          ),
        ),
        const Size(48, 48),
      );
    }
  });
}
