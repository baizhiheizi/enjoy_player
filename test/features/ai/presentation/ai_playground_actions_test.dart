import 'dart:typed_data';

import 'package:azure_speech/azure_speech.dart';
import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/features/ai/application/ai_byok_error_mapping.dart';
import 'package:enjoy_player/features/ai/application/ai_capability_providers.dart';
import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/ai/domain/byok_not_configured_failure.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/asr_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/assessment_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/dictionary_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/llm_capability.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/translation_capability.dart';
import 'package:enjoy_player/features/ai/domain/chat_message.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_request.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_result.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/ai/domain/models/translation_result.dart';
import 'package:enjoy_player/features/ai/presentation/ai_playground_actions.dart';
import 'package:enjoy_player/features/ai/presentation/ai_playground_inputs.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _settingsPageMarker = 'AI_PROVIDERS_SETTINGS_PAGE';

class _FakeAsr implements AsrCapability {
  int calls = 0;
  Object? throwOn;
  AsrRequest? lastRequest;

  @override
  Future<AsrResult> transcribe(AsrRequest request) async {
    calls++;
    lastRequest = request;
    final error = throwOn;
    if (error != null) throw error;
    return const AsrResult(text: 'fake asr transcription');
  }
}

class _FakeLlm implements LlmCapability {
  int calls = 0;
  Object? throwOnComplete;

  @override
  Future<String> generateChatCompletion({
    required List<ChatMessage> messages,
    double? temperature,
    int? maxTokens,
    Map<String, dynamic>? responseFormat,
  }) async {
    calls++;
    final error = throwOnComplete;
    if (error != null) throw error;
    return 'fake chat reply';
  }

  @override
  Future<String> generateText({
    String? systemPrompt,
    required String userPrompt,
    double? temperature,
    int? maxTokens,
  }) {
    throw UnimplementedError();
  }
}

class _FakeTranslation implements TranslationCapability {
  @override
  Future<TranslationResult> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    bool? forceRefresh,
  }) {
    throw UnimplementedError();
  }
}

class _FakeDictionary implements DictionaryCapability {
  int calls = 0;
  Object? throwOnLookup;
  String? lastWord;
  DictionaryResult result = const DictionaryResult(
    word: 'fake',
    sourceLanguage: 'en',
    targetLanguage: 'zh',
    senses: <DictionarySense>[],
  );

  @override
  Future<DictionaryResult> lookupDictionary({
    required String word,
    required String sourceLanguage,
    required String targetLanguage,
    bool? forceRefresh,
  }) async {
    calls++;
    lastWord = word;
    final error = throwOnLookup;
    if (error != null) throw error;
    return result;
  }
}

class _FakeAssessment implements AssessmentCapability {
  int calls = 0;
  Object? throwOnAssess;
  AssessmentRequest? lastRequest;
  AssessmentResult? result;

  @override
  Future<AssessmentResult> assess(AssessmentRequest request) async {
    calls++;
    lastRequest = request;
    final error = throwOnAssess;
    if (error != null) throw error;
    final r = result;
    if (r == null) throw UnimplementedError('no result configured');
    return r;
  }
}

class _Harness {
  final asr = _FakeAsr();
  final llm = _FakeLlm();
  final translation = _FakeTranslation();
  final dictionary = _FakeDictionary();
  final assessment = _FakeAssessment();

  late final ProviderContainer container = ProviderContainer(
    overrides: [
      asrCapabilityProvider.overrideWithValue(asr),
      llmCapabilityProvider.overrideWithValue(llm),
      translationCapabilityProvider.overrideWithValue(translation),
      dictionaryCapabilityProvider.overrideWithValue(dictionary),
      assessmentCapabilityProvider.overrideWithValue(assessment),
    ],
  );

  final outputLines = <({String text, bool isError})>[];
  PlaygroundInputs? inputs;
  AiPlaygroundActions? actions;
}

class _HostPage extends StatefulWidget {
  const _HostPage({required this.harness});

  final _Harness harness;

  @override
  State<_HostPage> createState() => _HostPageState();
}

class _HostPageState extends State<_HostPage> {
  late final _inputs = PlaygroundInputs(
    systemPrompt: TextEditingController(),
    userPrompt: TextEditingController(),
    translateSource: TextEditingController(),
    translateTarget: TextEditingController(),
    translateText: TextEditingController(),
    dictionaryWord: TextEditingController(),
    dictionarySource: TextEditingController(),
    dictionaryTarget: TextEditingController(),
    assessmentReference: TextEditingController(),
    assessmentLanguage: TextEditingController(),
  );

  PlaygroundAction? _busy;

  late final _actions = AiPlaygroundActions(
    context: context,
    asr: widget.harness.container.read(asrServiceProvider),
    chat: widget.harness.container.read(chatServiceProvider),
    translation: widget.harness.container.read(translationServiceProvider),
    dictionary: widget.harness.container.read(dictionaryServiceProvider),
    assessment: widget.harness.container.read(assessmentServiceProvider),
    inputs: _inputs,
    output: (line, {isError = false}) =>
        widget.harness.outputLines.add((text: line, isError: isError)),
    setBusy: (action) {
      if (!mounted) return;
      setState(() => _busy = action);
    },
    isBusy: () => _busy != null,
    isMounted: () => mounted,
    onPicked: _inputs.setPicked,
  );

  @override
  void initState() {
    super.initState();
    widget.harness.inputs = _inputs;
    widget.harness.actions = _actions;
  }

  @override
  void dispose() {
    _inputs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.shrink());
}

Widget _buildApp(_Harness harness) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => _HostPage(harness: harness),
      ),
      GoRoute(
        path: aiProvidersSettingsPath,
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text(_settingsPageMarker))),
      ),
    ],
  );
  return MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

Future<(_Harness, AppLocalizations)> _pumpHarness(WidgetTester tester) async {
  final harness = _Harness();
  await tester.pumpWidget(_buildApp(harness));
  await tester.pump();
  final l10n = AppLocalizations.of(tester.element(find.byType(_HostPage)))!;
  return (harness, l10n);
}

Map<String, dynamic> _assessmentJson({
  Map<String, dynamic>? scores,
  List<Map<String, dynamic>> words = const [],
}) {
  return {
    'RecognitionStatus': 'Success',
    'Offset': 0,
    'Duration': 12000000,
    'DisplayText': 'Good morning world.',
    'NBest': [
      {
        'Confidence': 0.9,
        'Lexical': 'Good morning world.',
        'ITN': 'Good morning world.',
        'MaskedITN': 'Good morning world.',
        'Display': 'Good morning world.',
        'PronunciationAssessment':
            scores ??
            {
              'AccuracyScore': 80.0,
              'FluencyScore': 84.0,
              'CompletenessScore': 90.0,
              'PronScore': 82.0,
            },
        'Words': words,
      },
    ],
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('run guards', () {
    testWidgets(
      'runAsr without picked audio reports the error and never calls the service',
      (tester) async {
        final (harness, l10n) = await _pumpHarness(tester);

        await harness.actions!.runAsr();

        expect(harness.asr.calls, 0);
        expect(harness.outputLines.single.isError, isTrue);
        expect(
          harness.outputLines.single.text,
          '${l10n.error}: pick an audio file first.',
        );
      },
    );

    testWidgets(
      'runAssessment without picked audio reports the error and never calls the service',
      (tester) async {
        final (harness, l10n) = await _pumpHarness(tester);

        await harness.actions!.runAssessment();

        expect(harness.assessment.calls, 0);
        expect(harness.outputLines.single.isError, isTrue);
        expect(
          harness.outputLines.single.text,
          contains('pick a WAV (or other) file first'),
        );
        expect(harness.outputLines.single.text, startsWith(l10n.error));
      },
    );

    testWidgets(
      'runAssessment with empty reference text reports the error and never calls the service',
      (tester) async {
        final (harness, l10n) = await _pumpHarness(tester);
        harness.inputs!.setPicked(
          Uint8List.fromList(const [1, 2, 3]),
          'clip.wav',
        );

        await harness.actions!.runAssessment();

        expect(harness.assessment.calls, 0);
        expect(harness.outputLines.single.isError, isTrue);
        expect(
          harness.outputLines.single.text,
          '${l10n.error}: enter reference text.',
        );
      },
    );
  });

  group('error routing', () {
    testWidgets(
      'runChat on a BYOK failure hints the settings route and shows a notice with a settings action',
      (tester) async {
        final (harness, l10n) = await _pumpHarness(tester);
        harness.llm.throwOnComplete = const ByokNotConfiguredFailure(
          ModalityKind.llm,
        );

        await harness.actions!.runChat();
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(harness.llm.calls, 1);
        expect(
          harness.outputLines.single.text,
          'Chat ${l10n.byokNotConfiguredMessage(l10n.settingsAiProvidersModalityLlm)}\n'
          '${l10n.byokNotConfiguredOpenSettings}',
        );
        expect(find.byType(SnackBar), findsOneWidget);
        final actionButton = find.widgetWithText(
          TextButton,
          l10n.settingsAiProvidersTileTitle,
        );
        expect(actionButton, findsOneWidget);

        await tester.tap(actionButton);
        await tester.pumpAndSettle();

        expect(find.text(_settingsPageMarker), findsOneWidget);
      },
    );

    testWidgets(
      'runChat on an AppFailure surfaces the message without a notice',
      (tester) async {
        final (harness, l10n) = await _pumpHarness(tester);
        harness.llm.throwOnComplete = const NetworkFailure('offline');

        await harness.actions!.runChat();
        await tester.pump();
        await tester.pump();

        expect(harness.outputLines.single.text, 'Chat offline');
        expect(harness.outputLines.single.isError, isTrue);
        expect(find.byType(SnackBar), findsNothing);
      },
    );

    testWidgets('runChat on an unexpected error surfaces the error itself', (
      tester,
    ) async {
      final (harness, _) = await _pumpHarness(tester);
      harness.llm.throwOnComplete = StateError('chat boom');

      await harness.actions!.runChat();

      expect(harness.outputLines.single.text, contains('chat boom'));
    });

    testWidgets(
      'runAsr on a BYOK failure routes through the same notice path',
      (tester) async {
        final (harness, l10n) = await _pumpHarness(tester);
        harness.asr.throwOn = const ByokNotConfiguredFailure(ModalityKind.asr);
        harness.inputs!.setPicked(Uint8List.fromList(const [1]), 'clip.wav');

        await harness.actions!.runAsr();
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(
          harness.outputLines.single.text,
          contains(
            l10n.byokNotConfiguredMessage(l10n.settingsAiProvidersModalityAsr),
          ),
        );
        expect(find.byType(SnackBar), findsOneWidget);
      },
    );

    testWidgets(
      'runAssessment on an Azure speech exception formats the SDK error',
      (tester) async {
        final (harness, _) = await _pumpHarness(tester);
        harness.assessment.throwOnAssess = const AzureSpeechException(
          code: 'BadRequest',
          message: 'bad audio',
        );
        harness.inputs!.setPicked(Uint8List.fromList(const [1]), 'clip.wav');
        harness.inputs!.assessmentReference.text = 'Good morning world.';

        await harness.actions!.runAssessment();

        expect(
          harness.outputLines.single.text,
          'Assessment AzureSpeech BadRequest: bad audio',
        );
      },
    );
  });

  group('output formatting', () {
    testWidgets(
      'runAsr passes the picked file through and prints the transcription',
      (tester) async {
        final (harness, _) = await _pumpHarness(tester);
        harness.inputs!.setPicked(
          Uint8List.fromList(const [4, 5, 6]),
          'clip.wav',
        );

        await harness.actions!.runAsr();

        expect(harness.asr.calls, 1);
        expect(harness.asr.lastRequest?.filename, 'clip.wav');
        expect(
          harness.outputLines.single.text,
          'ASR text:\nfake asr transcription',
        );
        expect(harness.outputLines.single.isError, isFalse);
      },
    );

    testWidgets('runDictionary renders the header, metadata and every sense', (
      tester,
    ) async {
      final (harness, _) = await _pumpHarness(tester);
      harness.inputs!.dictionaryWord.text = ' run ';
      harness.dictionary.result = const DictionaryResult(
        word: 'run',
        sourceLanguage: 'en',
        targetLanguage: 'zh',
        lemma: 'ran',
        ipa: '/rʌn/',
        senses: [
          DictionarySense(
            definition: 'to move quickly',
            translation: '跑',
            partOfSpeech: 'verb',
          ),
          DictionarySense(definition: 'a flow of water', partOfSpeech: 'noun'),
        ],
      );

      await harness.actions!.runDictionary();

      expect(harness.dictionary.calls, 1);
      expect(harness.dictionary.lastWord, 'run');
      final text = harness.outputLines.single.text;
      expect(text, contains('run (en → zh)'));
      expect(text, contains('lemma: ran'));
      expect(text, contains('ipa: /rʌn/'));
      expect(text, contains('[0] verb'));
      expect(text, contains('to move quickly'));
      expect(text, contains('⇄ 跑'));
      expect(text, contains('[1] noun'));
      expect(text, contains('a flow of water'));
    });

    testWidgets(
      'runAssessment renders scores, prosody, display text and per-word results',
      (tester) async {
        final (harness, _) = await _pumpHarness(tester);
        final json = _assessmentJson(
          scores: {
            'AccuracyScore': 80.0,
            'FluencyScore': 84.0,
            'CompletenessScore': 90.0,
            'PronScore': 82.0,
            'ProsodyScore': 75.0,
          },
          words: [
            {
              'Word': 'good',
              'Offset': 0,
              'Duration': 3000000,
              'PronunciationAssessment': {
                'AccuracyScore': 88.0,
                'ErrorType': 'None',
              },
            },
            {
              'Word': 'morning',
              'Offset': 3000000,
              'Duration': 4000000,
              'PronunciationAssessment': {
                'AccuracyScore': 62.0,
                'ErrorType': 'Mispronunciation',
              },
            },
          ],
        );
        harness.assessment.result = AssessmentResult(
          detail: AzurePronunciationAssessmentResult.fromJson(json),
          rawJson: json,
        );
        harness.inputs!.setPicked(Uint8List.fromList(const [1]), 'clip.wav');
        harness.inputs!.assessmentReference.text = 'Good morning world.';
        harness.inputs!.assessmentLanguage.text = 'en';

        await harness.actions!.runAssessment();

        expect(harness.assessment.calls, 1);
        expect(
          harness.assessment.lastRequest?.referenceText,
          'Good morning world.',
        );
        final text = harness.outputLines.single.text;
        expect(text, contains('Pronunciation assessment'));
        expect(
          text,
          contains(
            'PronScore: 82.0 · Accuracy: 80.0 · Fluency: 84.0 · Completeness: 90.0',
          ),
        );
        expect(text, contains('Prosody: 75.0'));
        expect(text, contains('Display: Good morning world.'));
        expect(text, contains('Words:'));
        expect(text, contains('· good  acc=88  None'));
        expect(text, contains('· morning  acc=62  Mispronunciation'));
      },
    );

    testWidgets(
      'runAssessment omits the prosody and word sections when absent',
      (tester) async {
        final (harness, _) = await _pumpHarness(tester);
        final json = _assessmentJson();
        harness.assessment.result = AssessmentResult(
          detail: AzurePronunciationAssessmentResult.fromJson(json),
          rawJson: json,
        );
        harness.inputs!.setPicked(Uint8List.fromList(const [1]), 'clip.wav');
        harness.inputs!.assessmentReference.text = 'Good morning world.';

        await harness.actions!.runAssessment();

        final text = harness.outputLines.single.text;
        expect(text, contains('PronScore: 82.0'));
        expect(text, contains('Display: Good morning world.'));
        expect(text, isNot(contains('Prosody:')));
        expect(text, isNot(contains('Words:')));
      },
    );
  });
}
