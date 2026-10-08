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
import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_icon_tile.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/features/ai/application/ai_byok_error_mapping.dart';
import 'package:enjoy_player/features/ai/application/ai_modality_config_controller.dart';
import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/ai/domain/byok_not_configured_failure.dart';
import 'package:enjoy_player/features/ai/domain/chat_message.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_request.dart';
import 'package:enjoy_player/features/ai/presentation/ai_playground_azure_error.dart';
import 'package:enjoy_player/features/ai/presentation/ai_playground_provider_label.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

final Logger _log = logNamed('ai.playground');

const double _rowLeadingSize = 30;
const double _rowLeadingGap = 12;
const double _rowHorizontalPadding = 12;
const double _consoleViewportHeight = 320;
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

  final List<_ConsoleEntry> _entries = [];

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
      _entries.add(_ConsoleEntry(line, isError: isError));
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
          EnjoySectionHeader(title: l10n.aiPlaygroundActiveProviders),
          SizedBox(height: t.space12),
          EnjoyCard(
            padding: EdgeInsets.symmetric(vertical: t.space4),
            child: Column(
              children: [
                _GroupRow(
                  icon: EnjoyIcons.robot,
                  label: l10n.settingsAiProvidersModalityLlm,
                  value: llmLabel,
                ),
                const _RowDivider(),
                _GroupRow(
                  icon: EnjoyIcons.mic,
                  label: l10n.settingsAiProvidersModalityAsr,
                  value: asrLabel,
                ),
                const _RowDivider(),
                _GroupRow(
                  icon: EnjoyIcons.speak,
                  label: l10n.settingsAiProvidersModalityTts,
                  value: ttsLabel,
                ),
                const _RowDivider(),
                _GroupRow(
                  icon: EnjoyIcons.insights,
                  label: l10n.settingsAiProvidersModalityAssessment,
                  value: assessmentLabel,
                ),
                const _RowDivider(),
                _GroupRow(
                  icon: EnjoyIcons.tune,
                  label: l10n.settingsAiProvidersTileTitle,
                  onTap: () => context.push(aiProvidersSettingsPath),
                ),
              ],
            ),
          ),
          SizedBox(height: t.space24),
          _PlaygroundSection(
            title: l10n.aiPlaygroundSectionAsr,
            providerLabel: asrLabel,
            children: [
              if (pickedBytes != null) ...[
                _PickedFileChip(name: _pickedName, byteCount: pickedBytes),
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
                    child: _RunLabel(
                      busy: busy == _PlaygroundAction.asr,
                      label: l10n.aiPlaygroundTranscribe,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _PlaygroundSection(
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
                  child: _RunLabel(
                    busy: busy == _PlaygroundAction.chat,
                    label: l10n.aiPlaygroundSendChat,
                  ),
                ),
              ),
            ],
          ),
          _PlaygroundSection(
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
                  child: _RunLabel(
                    busy: busy == _PlaygroundAction.translate,
                    label: l10n.aiPlaygroundTranslate,
                  ),
                ),
              ),
            ],
          ),
          _PlaygroundSection(
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
                  child: _RunLabel(
                    busy: busy == _PlaygroundAction.dictionary,
                    label: l10n.aiPlaygroundDictLookup,
                  ),
                ),
              ),
            ],
          ),
          _PlaygroundSection(
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
                  child: _RunLabel(
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
            child: _ConsolePanel(entries: _entries),
          ),
        ],
      ),
    );
  }
}

class _ConsoleEntry {
  const _ConsoleEntry(this.text, {required this.isError});

  final String text;
  final bool isError;
}

class _PlaygroundSection extends StatelessWidget {
  const _PlaygroundSection({
    required this.title,
    required this.providerLabel,
    required this.children,
  });

  final String title;
  final String providerLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: t.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EnjoySectionHeader(title: title, caption: providerLabel),
          SizedBox(height: t.space12),
          EnjoyCard(
            padding: EdgeInsets.all(t.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _RunLabel extends StatelessWidget {
  const _RunLabel({required this.busy, required this.label});

  final bool busy;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!busy) return Text(label);
    return LoadingIcon(
      size: 18,
      color: Theme.of(context).colorScheme.onPrimary,
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final value = this.value;

    final body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: _rowHorizontalPadding,
          vertical: t.space8,
        ),
        child: Row(
          children: [
            EnjoyIconTile(icon: icon, size: _rowLeadingSize),
            const SizedBox(width: _rowLeadingGap),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodyMedium,
              ),
            ),
            if (value != null) ...[
              SizedBox(width: t.space8),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ] else
              Icon(EnjoyIcons.chevronRight, size: 15, color: t.ink3),
          ],
        ),
      ),
    );

    if (onTap == null) return body;
    return EnjoyPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(t.radiusMd),
      pressedScale: 0.995,
      child: body,
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: _rowHorizontalPadding + _rowLeadingSize + _rowLeadingGap,
      endIndent: _rowHorizontalPadding,
      color: EnjoyThemeTokens.of(context).hairline,
    );
  }
}

class _PickedFileChip extends StatelessWidget {
  const _PickedFileChip({required this.name, required this.byteCount});

  final String name;
  final int byteCount;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: t.fill,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(t.radiusSm),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: t.space12,
          vertical: t.space8,
        ),
        child: Row(
          children: [
            Icon(EnjoyIcons.waveform, size: 16, color: cs.onSurfaceVariant),
            SizedBox(width: t.space8),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: enjoyMonoStyle(context, size: 12.5),
              ),
            ),
            SizedBox(width: t.space8),
            Text(
              '$byteCount B',
              style: enjoyMonoStyle(
                context,
                size: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsolePanel extends StatelessWidget {
  const _ConsolePanel({required this.entries});

  final List<_ConsoleEntry> entries;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    if (entries.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: t.space16),
        child: Column(
          children: [
            const EnjoyIconOrb(icon: EnjoyIcons.code, size: 56),
            SizedBox(height: t.space16),
            Text(
              AppLocalizations.of(context)!.aiPlaygroundOutput,
              textAlign: TextAlign.center,
              style: enjoyDisplayStyle(context, size: 20, color: cs.onSurface),
            ),
            SizedBox(height: t.space8),
            Text('—', style: enjoyMonoStyle(context, size: 13, color: t.ink3)),
          ],
        ),
      );
    }

    return SizedBox(
      height: _consoleViewportHeight,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[entries.length - 1 - index];
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : t.space16),
            child: SelectableText(
              entry.text,
              style: enjoyMonoStyle(
                context,
                size: 12.5,
                color: entry.isError ? cs.error : cs.onSurface,
              ),
            ),
          );
        },
      ),
    );
  }
}
