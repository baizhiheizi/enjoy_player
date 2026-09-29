import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/features/ai/domain/speech_byok_kind.dart';
import 'package:enjoy_player/features/ai/presentation/settings/widgets/byok_api_key_field.dart';
import 'package:enjoy_player/features/ai/presentation/settings/widgets/speech_byok_form.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(_wrap(child));
  await tester.pump();
}

void main() {
  testWidgets(
    'assessment mode hides SegmentedButton and baseUrl/model fields',
    (tester) async {
      final apiKey = TextEditingController();
      final region = TextEditingController();
      await _pump(
        tester,
        SpeechByokForm(
          mode: SpeechByokFormMode.assessment,
          apiKeyController: apiKey,
          regionController: region,
          hasExistingKey: false,
        ),
      );

      expect(find.byType(SegmentedButton<SpeechByokKind>), findsNothing);
      expect(find.text('Vendor'), findsNothing);
      expect(find.text('Base URL'), findsNothing);
      expect(find.text('Whisper model'), findsNothing);
      expect(find.text('Azure subscription key'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.byType(ByokApiKeyField), findsOneWidget);
    },
  );

  testWidgets('assessment mode exposes Azure region field with hint text', (
    tester,
  ) async {
    final apiKey = TextEditingController();
    final region = TextEditingController();
    await _pump(
      tester,
      SpeechByokForm(
        mode: SpeechByokFormMode.assessment,
        apiKeyController: apiKey,
        regionController: region,
        hasExistingKey: false,
      ),
    );

    expect(find.text('Azure region'), findsOneWidget);
    expect(find.text('eastus'), findsOneWidget);
  });

  testWidgets(
    'speech + openAi shows SegmentedButton, baseUrl, model fields (no region)',
    (tester) async {
      final apiKey = TextEditingController();
      final region = TextEditingController();
      final baseUrl = TextEditingController();
      final model = TextEditingController();
      await _pump(
        tester,
        SpeechByokForm(
          mode: SpeechByokFormMode.speech,
          apiKeyController: apiKey,
          regionController: region,
          hasExistingKey: false,
          kind: SpeechByokKind.openAiCompatible,
          baseUrlController: baseUrl,
          modelController: model,
        ),
      );

      expect(find.byType(SegmentedButton<SpeechByokKind>), findsOneWidget);
      expect(find.text('OpenAI Whisper'), findsOneWidget);
      expect(find.text('Azure Speech'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.byType(ByokApiKeyField), findsOneWidget);
      expect(find.text('Base URL'), findsOneWidget);
      expect(find.text('Whisper model'), findsOneWidget);
      expect(find.text('Azure region'), findsNothing);
    },
  );

  testWidgets(
    'speech + azureSpeech shows SegmentedButton and Azure region (no baseUrl/model)',
    (tester) async {
      final apiKey = TextEditingController();
      final region = TextEditingController();
      final baseUrl = TextEditingController();
      final model = TextEditingController();
      await _pump(
        tester,
        SpeechByokForm(
          mode: SpeechByokFormMode.speech,
          apiKeyController: apiKey,
          regionController: region,
          hasExistingKey: false,
          kind: SpeechByokKind.azureSpeech,
          baseUrlController: baseUrl,
          modelController: model,
        ),
      );

      expect(find.byType(SegmentedButton<SpeechByokKind>), findsOneWidget);
      expect(find.text('Base URL'), findsNothing);
      expect(find.text('Whisper model'), findsNothing);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Azure region'), findsOneWidget);
      expect(find.text('Azure subscription key'), findsOneWidget);
    },
  );

  testWidgets(
    'SegmentedButton onSelectionChanged invokes onKindChanged callback',
    (tester) async {
      final apiKey = TextEditingController();
      final region = TextEditingController();
      SpeechByokKind? changed;
      await _pump(
        tester,
        SpeechByokForm(
          mode: SpeechByokFormMode.speech,
          apiKeyController: apiKey,
          regionController: region,
          hasExistingKey: false,
          kind: SpeechByokKind.openAiCompatible,
          onKindChanged: (k) => changed = k,
        ),
      );

      await tester.tap(find.text('Azure Speech'));
      await tester.pump();
      expect(changed, SpeechByokKind.azureSpeech);
    },
  );

  testWidgets(
    'speech mode without baseUrl/model controllers skips those TextFields',
    (tester) async {
      final apiKey = TextEditingController();
      final region = TextEditingController();
      await _pump(
        tester,
        SpeechByokForm(
          mode: SpeechByokFormMode.speech,
          apiKeyController: apiKey,
          regionController: region,
          hasExistingKey: false,
          kind: SpeechByokKind.openAiCompatible,
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Base URL'), findsNothing);
      expect(find.text('Whisper model'), findsNothing);
    },
  );

  testWidgets('modelLabelText/modelHintText override default Whisper labels', (
    tester,
  ) async {
    final apiKey = TextEditingController();
    final region = TextEditingController();
    final baseUrl = TextEditingController();
    final model = TextEditingController();
    await _pump(
      tester,
      SpeechByokForm(
        mode: SpeechByokFormMode.speech,
        apiKeyController: apiKey,
        regionController: region,
        hasExistingKey: false,
        kind: SpeechByokKind.openAiCompatible,
        baseUrlController: baseUrl,
        modelController: model,
        modelLabelText: 'Custom model',
        modelHintText: 'my-model-name',
      ),
    );

    expect(find.text('Custom model'), findsOneWidget);
    expect(find.text('my-model-name'), findsOneWidget);
    expect(find.text('Whisper model'), findsNothing);
  });

  testWidgets('SectionLabel renders "Vendor" for speech mode with route icon', (
    tester,
  ) async {
    final apiKey = TextEditingController();
    final region = TextEditingController();
    await _pump(
      tester,
      SpeechByokForm(
        mode: SpeechByokFormMode.speech,
        apiKeyController: apiKey,
        regionController: region,
        hasExistingKey: false,
      ),
    );

    expect(find.text('Vendor'), findsOneWidget);
    expect(find.byIcon(EnjoyIcons.route), findsOneWidget);
  });
}
