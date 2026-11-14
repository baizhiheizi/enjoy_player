/// Modality runners, busy guard, and error mapping for the AI playground.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/features/ai/application/ai_byok_error_mapping.dart';
import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/ai/domain/byok_not_configured_failure.dart';
import 'package:enjoy_player/features/ai/domain/chat_message.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/assessment_request.dart';
import 'package:enjoy_player/features/ai/presentation/ai_playground_azure_error.dart';
import 'package:enjoy_player/features/ai/presentation/ai_playground_inputs.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

final Logger _log = logNamed('ai.playground');

enum PlaygroundAction { pick, asr, chat, translate, dictionary, assessment }

class AiPlaygroundActions {
  AiPlaygroundActions({
    required this.context,
    required this.asr,
    required this.chat,
    required this.translation,
    required this.dictionary,
    required this.assessment,
    required this.inputs,
    required this.output,
    required this.setBusy,
    required this.isBusy,
    required this.isMounted,
    required this.onPicked,
  });

  final BuildContext context;
  final AsrService asr;
  final ChatService chat;
  final TranslationService translation;
  final DictionaryService dictionary;
  final AssessmentService assessment;
  final PlaygroundInputs inputs;
  final void Function(String line, {bool isError}) output;
  final void Function(PlaygroundAction? action) setBusy;
  final bool Function() isBusy;
  final bool Function() isMounted;
  final void Function(Uint8List bytes, String name) onPicked;

  Future<void> pickAudio() => _run(PlaygroundAction.pick, () async {
    final l10n = AppLocalizations.of(context)!;
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['wav', 'mp3', 'm4a', 'webm', 'ogg', 'flac'],
    );
    if (!isMounted()) return;
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
      output('${l10n.error}: could not read file bytes.', isError: true);
      return;
    }
    onPicked(bytes, f.name);
    output('Selected: ${f.name} (${bytes.length} bytes)');
  });

  Future<void> runAsr() => _run(PlaygroundAction.asr, () async {
    final l10n = AppLocalizations.of(context)!;
    final bytes = inputs.pickedAudio;
    if (bytes == null) {
      output('${l10n.error}: pick an audio file first.', isError: true);
      return;
    }
    try {
      final result = await asr.transcribe(
        AsrRequest(audioBytes: bytes, filename: inputs.pickedName),
      );
      output('ASR text:\n${result.text}');
    } catch (e, st) {
      _log.warning('ASR failed', e, st);
      _maybePromptByokSettings(e);
      output('ASR ${_err(e)}', isError: true);
    }
  });

  Future<void> runChat() => _run(PlaygroundAction.chat, () async {
    try {
      final system = inputs.systemPrompt.text.trim();
      final messages = <ChatMessage>[
        if (system.isNotEmpty)
          ChatMessage(role: ChatMessage.roleSystem, content: system),
        ChatMessage(
          role: ChatMessage.roleUser,
          content: inputs.userPrompt.text.trim(),
        ),
      ];
      final reply = await chat.complete(messages: messages);
      output('Chat reply:\n$reply');
    } catch (e, st) {
      _log.warning('Chat failed', e, st);
      _maybePromptByokSettings(e);
      output('Chat ${_err(e)}', isError: true);
    }
  });

  Future<void> runTranslate() => _run(PlaygroundAction.translate, () async {
    try {
      final r = await translation.translate(
        text: inputs.translateText.text.trim(),
        sourceLanguage: inputs.translateSource.text.trim(),
        targetLanguage: inputs.translateTarget.text.trim(),
      );
      output('Translation:\n${r.translatedText}');
    } catch (e, st) {
      _log.warning('Translate failed', e, st);
      _maybePromptByokSettings(e);
      output('Translate ${_err(e)}', isError: true);
    }
  });

  Future<void> runDictionary() => _run(PlaygroundAction.dictionary, () async {
    try {
      final r = await dictionary.lookup(
        word: inputs.dictionaryWord.text.trim(),
        sourceLanguage: inputs.dictionarySource.text.trim(),
        targetLanguage: inputs.dictionaryTarget.text.trim(),
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
      output(buf.toString());
    } catch (e, st) {
      _log.warning('Dictionary failed', e, st);
      _maybePromptByokSettings(e);
      output('Dictionary ${_err(e)}', isError: true);
    }
  });

  Future<void> runAssessment() => _run(PlaygroundAction.assessment, () async {
    final l10n = AppLocalizations.of(context)!;
    final bytes = inputs.pickedAudio;
    if (bytes == null) {
      output(
        '${l10n.error}: pick a WAV (or other) file first; assessment uses the same pick as ASR.',
        isError: true,
      );
      return;
    }
    final refText = inputs.assessmentReference.text.trim();
    if (refText.isEmpty) {
      output('${l10n.error}: enter reference text.', isError: true);
      return;
    }
    try {
      final r = await assessment.assess(
        AssessmentRequest(
          audioBytes: bytes,
          referenceText: refText,
          language: inputs.assessmentLanguage.text.trim(),
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
      final words = r.detail.primaryNBest?.words;
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
      output(buf.toString());
    } catch (e, st) {
      _log.warning('Assessment failed', e, st);
      _maybePromptByokSettings(e);
      if (isAzureSpeechException(e)) {
        output('Assessment ${formatAzureSpeechError(e)}', isError: true);
      } else {
        output('Assessment ${_err(e)}', isError: true);
      }
    }
  });

  Future<void> _run(
    PlaygroundAction action,
    Future<void> Function() body,
  ) async {
    if (isBusy()) return;
    setBusy(action);
    try {
      await body();
    } finally {
      setBusy(null);
    }
  }

  String _err(Object e) {
    if (e is ByokNotConfiguredFailure) {
      final l10n = AppLocalizations.of(context)!;
      return formatByokNotConfiguredWithSettingsHint(e, l10n);
    }
    if (e is AppFailure) return e.message;
    return e.toString();
  }

  void _maybePromptByokSettings(Object e) {
    if (e is! ByokNotConfiguredFailure || !isMounted()) return;
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
}
