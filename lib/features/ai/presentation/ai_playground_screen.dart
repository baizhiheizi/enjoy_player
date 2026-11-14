/// Debug screen to exercise Enjoy AI HTTP APIs (ASR, chat, translation, dictionary).
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/features/ai/application/ai_modality_config_controller.dart';
import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/ai/presentation/ai_playground_actions.dart';
import 'package:enjoy_player/features/ai/presentation/ai_playground_console_panel.dart';
import 'package:enjoy_player/features/ai/presentation/ai_playground_inputs.dart';
import 'package:enjoy_player/features/ai/presentation/ai_playground_provider_card.dart';
import 'package:enjoy_player/features/ai/presentation/ai_playground_provider_label.dart';
import 'package:enjoy_player/features/ai/presentation/ai_playground_sections.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const int _maxConsoleEntries = 200;

class AiPlaygroundScreen extends ConsumerStatefulWidget {
  const AiPlaygroundScreen({super.key});

  @override
  ConsumerState<AiPlaygroundScreen> createState() => _AiPlaygroundScreenState();
}

class _AiPlaygroundScreenState extends ConsumerState<AiPlaygroundScreen> {
  final List<PlaygroundConsoleEntry> _entries = [];

  late final _inputs = PlaygroundInputs(
    systemPrompt: TextEditingController(),
    userPrompt: TextEditingController(text: 'Hello, summarize in one line.'),
    translateSource: TextEditingController(text: 'en'),
    translateTarget: TextEditingController(text: 'zh'),
    translateText: TextEditingController(text: 'Good morning.'),
    dictionaryWord: TextEditingController(text: 'run'),
    dictionarySource: TextEditingController(text: 'en'),
    dictionaryTarget: TextEditingController(text: 'zh'),
    assessmentReference: TextEditingController(text: 'Hello world.'),
    assessmentLanguage: TextEditingController(text: 'en'),
  );

  PlaygroundAction? _busy;

  late final _actions = AiPlaygroundActions(
    context: context,
    asr: ref.read(asrServiceProvider),
    chat: ref.read(chatServiceProvider),
    translation: ref.read(translationServiceProvider),
    dictionary: ref.read(dictionaryServiceProvider),
    assessment: ref.read(assessmentServiceProvider),
    inputs: _inputs,
    output: _append,
    setBusy: _setBusy,
    isBusy: () => _busy != null,
    isMounted: () => mounted,
    onPicked: _setPicked,
  );

  @override
  void dispose() {
    _inputs.dispose();
    super.dispose();
  }

  void _append(String line, {bool isError = false}) {
    setState(() {
      _entries.add(PlaygroundConsoleEntry(line, isError: isError));
      if (_entries.length > _maxConsoleEntries) _entries.removeAt(0);
    });
  }

  void _clearOutput() => setState(_entries.clear);

  void _setBusy(PlaygroundAction? action) {
    if (!mounted) return;
    setState(() => _busy = action);
  }

  void _setPicked(Uint8List bytes, String name) {
    if (!mounted) return;
    setState(() => _inputs.setPicked(bytes, name));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final t = EnjoyThemeTokens.of(context);
    final configs = ref.watch(aiModalityConfigCtrlProvider);
    final llmLabel = formatPlaygroundProviderLabel(l10n, configs.llm);
    final asrLabel = formatPlaygroundProviderLabel(l10n, configs.asr);
    final ttsLabel = formatPlaygroundProviderLabel(l10n, configs.tts);
    final assessmentLabel = formatPlaygroundProviderLabel(
      l10n,
      configs.assessment,
    );
    final busy = _busy;

    return EnjoyPage(
      kind: EnjoyPageKind.hub,
      title: l10n.aiPlaygroundTitle,
      showBack: true,
      body: (context, metrics) => ListView(
        padding: metrics.padding(top: t.space16, bottom: t.space32),
        children: [
          Text(
            l10n.aiPlaygroundIntro,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          SizedBox(height: t.space24),
          AiPlaygroundProvidersCard(
            llmLabel: llmLabel,
            asrLabel: asrLabel,
            ttsLabel: ttsLabel,
            assessmentLabel: assessmentLabel,
          ),
          SizedBox(height: t.space24),
          AsrPlaygroundSection(
            providerLabel: asrLabel,
            busy: busy,
            pickedName: _inputs.pickedName,
            pickedByteCount: _inputs.pickedByteCount,
            onPickAudio: _actions.pickAudio,
            onRun: _actions.runAsr,
          ),
          ChatPlaygroundSection(
            providerLabel: llmLabel,
            busy: busy,
            systemController: _inputs.systemPrompt,
            userController: _inputs.userPrompt,
            onRun: _actions.runChat,
          ),
          TranslationPlaygroundSection(
            providerLabel: llmLabel,
            busy: busy,
            sourceController: _inputs.translateSource,
            targetController: _inputs.translateTarget,
            textController: _inputs.translateText,
            onRun: _actions.runTranslate,
          ),
          DictionaryPlaygroundSection(
            providerLabel: llmLabel,
            busy: busy,
            wordController: _inputs.dictionaryWord,
            sourceController: _inputs.dictionarySource,
            targetController: _inputs.dictionaryTarget,
            onRun: _actions.runDictionary,
          ),
          AssessmentPlaygroundSection(
            providerLabel: assessmentLabel,
            busy: busy,
            referenceController: _inputs.assessmentReference,
            languageController: _inputs.assessmentLanguage,
            onRun: _actions.runAssessment,
          ),
          EnjoySectionHeader(
            title: l10n.aiPlaygroundOutput,
            trailing: EnjoyButton.ghost(
              onPressed: _entries.isEmpty ? null : _clearOutput,
              icon: EnjoyIcons.clearAll,
              size: EnjoyButtonSize.small,
              child: Text(l10n.aiPlaygroundClearOutput),
            ),
          ),
          SizedBox(height: t.space12),
          EnjoyCard(
            padding: EdgeInsets.all(t.space16),
            child: PlaygroundConsolePanel(entries: _entries),
          ),
        ],
      ),
    );
  }
}
