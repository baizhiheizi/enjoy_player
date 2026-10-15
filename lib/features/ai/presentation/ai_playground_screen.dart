/// Debug screen to exercise Enjoy AI HTTP APIs (ASR, chat, translation, dictionary).
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/features/ai/application/ai_byok_error_mapping.dart';
import 'package:enjoy_player/features/ai/application/ai_modality_config_controller.dart';
import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/ai/domain/byok_not_configured_failure.dart';
import 'package:enjoy_player/features/ai/domain/chat_message.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_request.dart';
import 'package:enjoy_player/features/ai/presentation/ai_playground_azure_error.dart';
import 'package:enjoy_player/features/ai/presentation/ai_playground_console_panel.dart';
import 'package:enjoy_player/features/ai/presentation/ai_playground_provider_card.dart';
import 'package:enjoy_player/features/ai/presentation/ai_playground_provider_label.dart';
import 'package:enjoy_player/features/ai/presentation/ai_playground_section.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

final Logger _log = logNamed('ai.playground');

const int _maxConsoleEntries = 200;

enum _PlaygroundAction { pick, asr, chat, translate, dictionary, assessment }

class AiPlaygroundScreen extends ConsumerStatefulWidget {
  const AiPlaygroundScreen({super.key});

  @override
  ConsumerState<AiPlaygroundScreen> createState() => _AiPlaygroundScreenState();
}

class _AiPlaygroundScreenState extends ConsumerState<AiPlaygroundScreen> {
  final _systemCtrl = TextEditingController();
  final _userCtrl = TextEditingController(
    text: 'Hello, summarize in one line.',
  );
  final _translateSourceCtrl = TextEditingController(text: 'en');
  final _translateTargetCtrl = TextEditingController(text: 'zh');
  final _translateTextCtrl = TextEditingController(text: 'Good morning.');
  final _dictWordCtrl = TextEditingController(text: 'run');
  final _dictSourceCtrl = TextEditingController(text: 'en');
  final _dictTargetCtrl = TextEditingController(text: 'zh');
  final _assessRefCtrl = TextEditingController(text: 'Hello world.');
  final _assessLangCtrl = TextEditingController(text: 'en');

  final List<PlaygroundConsoleEntry> _entries = [];

  Uint8List? _pickedAudio;
  String _pickedName = 'audio.wav';
  _PlaygroundAction? _busy;

  @override
  void dispose() {
    _systemCtrl.dispose();
    _userCtrl.dispose();
    _translateSourceCtrl.dispose();
    _translateTargetCtrl.dispose();
    _translateTextCtrl.dispose();
    _dictWordCtrl.dispose();
    _dictSourceCtrl.dispose();
    _dictTargetCtrl.dispose();
    _assessRefCtrl.dispose();
    _assessLangCtrl.dispose();
    super.dispose();
  }

  void _append(String line, {bool isError = false}) {
    setState(() {
      _entries.add(PlaygroundConsoleEntry(line, isError: isError));
      if (_entries.length > _maxConsoleEntries) _entries.removeAt(0);
    });
  }

  void _clearOutput() => setState(_entries.clear);

  String _err(Object e) {
    if (e is ByokNotConfiguredFailure) {
      final l10n = AppLocalizations.of(context)!;
      return formatByokNotConfiguredWithSettingsHint(e, l10n);
    }
    if (e is AppFailure) return e.message;
    return e.toString();
  }

  void _maybePromptByokSettings(Object e) {
    if (e is! ByokNotConfiguredFailure || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final router = GoRouter.of(context);
    AppNotice.warning(
      context,
      formatByokNotConfiguredMessage(e, l10n),
      action: (
        label: l10n.settingsAiProvidersTileTitle,
        onPressed: () => router.push(aiProvidersSettingsPath),
      ),
    );
  }

  Future<void> _run(
    _PlaygroundAction action,
    Future<void> Function() body,
  ) async {
    if (_busy != null) return;
    setState(() => _busy = action);
    try {
      await body();
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _pickAudio() => _run(_PlaygroundAction.pick, () async {
    final l10n = AppLocalizations.of(context)!;
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['wav', 'mp3', 'm4a', 'webm', 'ogg', 'flac'],
    );
    if (!mounted) return;
    if (f == null) return;
    Uint8List? bytes;
    try {
      bytes = await f.readAsBytes();
    } on Object {
      bytes = null;
    }
    final path = f.path;
    if (bytes == null && path != null && path.isNotEmpty) {
      bytes = await File(path).readAsBytes();
    }
    if (bytes == null) {
      _append('${l10n.error}: could not read file bytes.', isError: true);
      return;
    }
    setState(() {
      _pickedAudio = bytes;
      _pickedName = f.name;
    });
    _append('Selected: ${f.name} (${bytes.length} bytes)');
  });

  Future<void> _runAsr() => _run(_PlaygroundAction.asr, () async {
    final l10n = AppLocalizations.of(context)!;
    final bytes = _pickedAudio;
    if (bytes == null) {
      _append('${l10n.error}: pick an audio file first.', isError: true);
      return;
    }
    try {
      final result = await ref
          .read(asrServiceProvider)
          .transcribe(AsrRequest(audioBytes: bytes, filename: _pickedName));
      _append('ASR text:\n${result.text}');
    } catch (e, st) {
      _log.warning('ASR failed', e, st);
      _maybePromptByokSettings(e);
      _append('ASR ${_err(e)}', isError: true);
    }
  });

  Future<void> _runChat() => _run(_PlaygroundAction.chat, () async {
    try {
      final messages = <ChatMessage>[
        if (_systemCtrl.text.trim().isNotEmpty)
          ChatMessage(
            role: ChatMessage.roleSystem,
            content: _systemCtrl.text.trim(),
          ),
        ChatMessage(role: ChatMessage.roleUser, content: _userCtrl.text.trim()),
      ];
      final reply = await ref
          .read(chatServiceProvider)
          .complete(messages: messages);
      _append('Chat reply:\n$reply');
    } catch (e, st) {
      _log.warning('Chat failed', e, st);
      _maybePromptByokSettings(e);
      _append('Chat ${_err(e)}', isError: true);
    }
  });

  Future<void> _runTranslate() => _run(_PlaygroundAction.translate, () async {
    try {
      final r = await ref
          .read(translationServiceProvider)
          .translate(
            text: _translateTextCtrl.text.trim(),
            sourceLanguage: _translateSourceCtrl.text.trim(),
            targetLanguage: _translateTargetCtrl.text.trim(),
          );
      _append('Translation:\n${r.translatedText}');
    } catch (e, st) {
      _log.warning('Translate failed', e, st);
      _maybePromptByokSettings(e);
      _append('Translate ${_err(e)}', isError: true);
    }
  });

  Future<void> _runDictionary() => _run(_PlaygroundAction.dictionary, () async {
    try {
      final r = await ref
          .read(dictionaryServiceProvider)
          .lookup(
            word: _dictWordCtrl.text.trim(),
            sourceLanguage: _dictSourceCtrl.text.trim(),
            targetLanguage: _dictTargetCtrl.text.trim(),
          );
      final buf = StringBuffer()
        ..writeln('${r.word} (${r.sourceLanguage} → ${r.targetLanguage})');
      if (r.lemma != null) buf.writeln('lemma: ${r.lemma}');
      if (r.ipa != null) buf.writeln('ipa: ${r.ipa}');
      for (var i = 0; i < r.senses.length; i++) {
        final s = r.senses[i];
        buf
          ..writeln()
          ..writeln('[$i] ${s.partOfSpeech ?? ''}');
        buf.writeln(s.definition);
        if (s.translation != null) buf.writeln('⇄ ${s.translation}');
      }
      _append(buf.toString());
    } catch (e, st) {
      _log.warning('Dictionary failed', e, st);
      _maybePromptByokSettings(e);
      _append('Dictionary ${_err(e)}', isError: true);
    }
  });

  Future<void> _runAssessment() => _run(_PlaygroundAction.assessment, () async {
    final l10n = AppLocalizations.of(context)!;
    final bytes = _pickedAudio;
    if (bytes == null) {
      _append(
        '${l10n.error}: pick a WAV (or other) file first; assessment uses the same pick as ASR.',
        isError: true,
      );
      return;
    }
    final refText = _assessRefCtrl.text.trim();
    if (refText.isEmpty) {
      _append('${l10n.error}: enter reference text.', isError: true);
      return;
    }
    try {
      final r = await ref
          .read(assessmentServiceProvider)
          .assess(
            AssessmentRequest(
              audioBytes: bytes,
              referenceText: refText,
              language: _assessLangCtrl.text.trim(),
            ),
          );
      final scores = r.detail.primaryScores;
      final buf = StringBuffer()..writeln('Pronunciation assessment');
      if (scores != null) {
        buf.writeln(
          'PronScore: ${scores.pronScore.toStringAsFixed(1)} · '
          'Accuracy: ${scores.accuracyScore.toStringAsFixed(1)} · '
          'Fluency: ${scores.fluencyScore.toStringAsFixed(1)} · '
          'Completeness: ${scores.completenessScore.toStringAsFixed(1)}',
        );
        if (scores.prosodyScore != null) {
          buf.writeln('Prosody: ${scores.prosodyScore!.toStringAsFixed(1)}');
        }
      }
      buf.writeln('Display: ${r.detail.displayText}');
      final words = r.detail.nBest.isEmpty ? null : r.detail.nBest.first.words;
      if (words != null && words.isNotEmpty) {
        buf
          ..writeln()
          ..writeln('Words:');
        for (final w in words) {
          buf.writeln(
            '  · ${w.word}  acc=${w.pronunciationAssessment.accuracyScore.toStringAsFixed(0)}  '
            '${w.pronunciationAssessment.errorType}',
          );
        }
      }
      _append(buf.toString());
    } catch (e, st) {
      _log.warning('Assessment failed', e, st);
      _maybePromptByokSettings(e);
      if (isAzureSpeechException(e)) {
        _append('Assessment ${formatAzureSpeechError(e)}', isError: true);
      } else {
        _append('Assessment ${_err(e)}', isError: true);
      }
    }
  });

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
    final pickedBytes = _pickedAudio?.length;

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
          PlaygroundSection(
            title: l10n.aiPlaygroundSectionAsr,
            providerLabel: asrLabel,
            children: [
              if (pickedBytes != null) ...[
                PlaygroundPickedFileChip(
                  name: _pickedName,
                  byteCount: pickedBytes,
                ),
                SizedBox(height: t.space12),
              ],
              Wrap(
                spacing: t.space8,
                runSpacing: t.space8,
                children: [
                  EnjoyButton.secondary(
                    onPressed: busy == null ? _pickAudio : null,
                    icon: EnjoyIcons.upload,
                    child: Text(l10n.aiPlaygroundPickAudio),
                  ),
                  EnjoyButton.brand(
                    onPressed: busy == null ? _runAsr : null,
                    child: PlaygroundRunLabel(
                      busy: busy == _PlaygroundAction.asr,
                      label: l10n.aiPlaygroundTranscribe,
                    ),
                  ),
                ],
              ),
            ],
          ),
          PlaygroundSection(
            title: l10n.aiPlaygroundSectionChat,
            providerLabel: llmLabel,
            children: [
              TextField(
                controller: _systemCtrl,
                decoration: InputDecoration(
                  labelText: l10n.aiPlaygroundChatSystem,
                ),
              ),
              SizedBox(height: t.space12),
              TextField(
                controller: _userCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.aiPlaygroundChatUser,
                ),
              ),
              SizedBox(height: t.space12),
              Align(
                alignment: Alignment.centerLeft,
                child: EnjoyButton.brand(
                  onPressed: busy == null ? _runChat : null,
                  child: PlaygroundRunLabel(
                    busy: busy == _PlaygroundAction.chat,
                    label: l10n.aiPlaygroundSendChat,
                  ),
                ),
              ),
            ],
          ),
          PlaygroundSection(
            title: l10n.aiPlaygroundSectionTranslation,
            providerLabel: llmLabel,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _translateSourceCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.aiPlaygroundTranslateSource,
                      ),
                    ),
                  ),
                  SizedBox(width: t.space12),
                  Expanded(
                    child: TextField(
                      controller: _translateTargetCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.aiPlaygroundTranslateTarget,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: t.space12),
              TextField(
                controller: _translateTextCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.aiPlaygroundTranslateText,
                ),
              ),
              SizedBox(height: t.space12),
              Align(
                alignment: Alignment.centerLeft,
                child: EnjoyButton.brand(
                  onPressed: busy == null ? _runTranslate : null,
                  child: PlaygroundRunLabel(
                    busy: busy == _PlaygroundAction.translate,
                    label: l10n.aiPlaygroundTranslate,
                  ),
                ),
              ),
            ],
          ),
          PlaygroundSection(
            title: l10n.aiPlaygroundSectionDictionary,
            providerLabel: llmLabel,
            children: [
              TextField(
                controller: _dictWordCtrl,
                decoration: InputDecoration(
                  labelText: l10n.aiPlaygroundDictWord,
                ),
              ),
              SizedBox(height: t.space12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dictSourceCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.aiPlaygroundDictSource,
                      ),
                    ),
                  ),
                  SizedBox(width: t.space12),
                  Expanded(
                    child: TextField(
                      controller: _dictTargetCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.aiPlaygroundDictTarget,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: t.space12),
              Align(
                alignment: Alignment.centerLeft,
                child: EnjoyButton.brand(
                  onPressed: busy == null ? _runDictionary : null,
                  child: PlaygroundRunLabel(
                    busy: busy == _PlaygroundAction.dictionary,
                    label: l10n.aiPlaygroundDictLookup,
                  ),
                ),
              ),
            ],
          ),
          PlaygroundSection(
            title: l10n.aiPlaygroundSectionTtsAssessment,
            providerLabel: assessmentLabel,
            children: [
              Text(
                l10n.aiPlaygroundAssessmentTtsNote,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              SizedBox(height: t.space12),
              TextField(
                controller: _assessRefCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.aiPlaygroundAssessmentReference,
                ),
              ),
              SizedBox(height: t.space12),
              TextField(
                controller: _assessLangCtrl,
                decoration: InputDecoration(
                  labelText: l10n.aiPlaygroundAssessmentLanguage,
                ),
              ),
              SizedBox(height: t.space12),
              Align(
                alignment: Alignment.centerLeft,
                child: EnjoyButton.brand(
                  onPressed: busy == null ? _runAssessment : null,
                  child: PlaygroundRunLabel(
                    busy: busy == _PlaygroundAction.assessment,
                    label: l10n.aiPlaygroundAssess,
                  ),
                ),
              ),
            ],
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
