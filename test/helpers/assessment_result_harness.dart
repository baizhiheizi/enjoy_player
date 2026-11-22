import 'dart:convert';

import 'package:azure_speech/azure_speech.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Azure assessment payload with three scored words.
const String kAssessmentResultJson = '''
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
        },
        {
          "Word": "there",
          "Offset": 10000000,
          "Duration": 10000000,
          "PronunciationAssessment": {
            "AccuracyScore": 88,
            "ErrorType": "Mispronunciation"
          }
        },
        {
          "Word": "friend",
          "Offset": 20000000,
          "Duration": 10000000,
          "PronunciationAssessment": {
            "AccuracyScore": 95,
            "ErrorType": "None"
          }
        }
      ]
    }
  ]
}''';

/// Azure assessment payload whose word list is empty.
const String kAssessmentResultNoWordsJson = '''
{
  "RecognitionStatus": "Success",
  "Offset": 0,
  "Duration": 10000000,
  "DisplayText": "",
  "NBest": [
    {
      "Confidence": 0.0,
      "Lexical": "",
      "ITN": "",
      "MaskedITN": "",
      "Display": "",
      "PronunciationAssessment": {
        "AccuracyScore": 0,
        "FluencyScore": 0,
        "CompletenessScore": 0,
        "PronScore": 0
      },
      "Words": []
    }
  ]
}''';

/// Azure assessment payload without any NBest entry.
const String kAssessmentResultEmptyJson = '''
{
  "RecognitionStatus": "Success",
  "Offset": 0,
  "Duration": 0,
  "DisplayText": "",
  "NBest": []
}''';

/// Parses an [AzurePronunciationAssessmentResult] from a JSON payload.
AzurePronunciationAssessmentResult parseAssessmentResult(String json) {
  return AzurePronunciationAssessmentResult.fromJson(
    jsonDecode(json) as Map<String, dynamic>,
  );
}

/// Wraps [body] in the themed, localized app shell the assessment result
/// surfaces render inside.
Widget wrapAssessmentHarness(
  Widget body, {
  double width = 800,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF003366));
  return ProviderScope(
    child: MaterialApp(
      navigatorKey: navigatorKey,
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
        body: Center(
          child: SizedBox(width: width, height: 600, child: body),
        ),
      ),
    ),
  );
}

/// Initializes the media_kit native library the assessment widgets pull in.
///
/// Returns the initialization error, or `null` when the library is
/// available — the caller skips its suite when it is not.
Object? initAssessmentMediaKit() {
  try {
    MediaKit.ensureInitialized();
    return null;
  } on Object catch (e) {
    return e;
  }
}

/// Loads the English localizations the assessment widgets assert against.
Future<AppLocalizations> loadAssessmentL10n() =>
    AppLocalizations.delegate.load(const Locale('en'));
