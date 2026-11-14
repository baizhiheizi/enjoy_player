/// Per-modality form sections for the AI playground.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/features/ai/presentation/ai_playground_actions.dart';
import 'package:enjoy_player/features/ai/presentation/ai_playground_section.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class AsrPlaygroundSection extends StatelessWidget {
  const AsrPlaygroundSection({
    required this.providerLabel,
    required this.busy,
    required this.pickedName,
    required this.pickedByteCount,
    required this.onPickAudio,
    required this.onRun,
    super.key,
  });

  final String providerLabel;
  final PlaygroundAction? busy;
  final String pickedName;
  final int? pickedByteCount;
  final VoidCallback onPickAudio;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final bytes = pickedByteCount;

    return PlaygroundSection(
      title: l10n.aiPlaygroundSectionAsr,
      providerLabel: providerLabel,
      children: [
        if (bytes != null) ...[
          PlaygroundPickedFileChip(name: pickedName, byteCount: bytes),
          SizedBox(height: t.space12),
        ],
        Wrap(
          spacing: t.space8,
          runSpacing: t.space8,
          children: [
            EnjoyButton.secondary(
              onPressed: busy == null ? onPickAudio : null,
              icon: EnjoyIcons.upload,
              child: Text(l10n.aiPlaygroundPickAudio),
            ),
            EnjoyButton.brand(
              onPressed: busy == null ? onRun : null,
              child: PlaygroundRunLabel(
                busy: busy == PlaygroundAction.asr,
                label: l10n.aiPlaygroundTranscribe,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ChatPlaygroundSection extends StatelessWidget {
  const ChatPlaygroundSection({
    required this.providerLabel,
    required this.busy,
    required this.systemController,
    required this.userController,
    required this.onRun,
    super.key,
  });

  final String providerLabel;
  final PlaygroundAction? busy;
  final TextEditingController systemController;
  final TextEditingController userController;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    return PlaygroundFormSection(
      title: l10n.aiPlaygroundSectionChat,
      providerLabel: providerLabel,
      runLabel: l10n.aiPlaygroundSendChat,
      isEnabled: busy == null,
      isRunning: busy == PlaygroundAction.chat,
      onRun: onRun,
      children: [
        TextField(
          controller: systemController,
          decoration: InputDecoration(labelText: l10n.aiPlaygroundChatSystem),
        ),
        SizedBox(height: t.space12),
        TextField(
          controller: userController,
          maxLines: 3,
          decoration: InputDecoration(labelText: l10n.aiPlaygroundChatUser),
        ),
      ],
    );
  }
}

class TranslationPlaygroundSection extends StatelessWidget {
  const TranslationPlaygroundSection({
    required this.providerLabel,
    required this.busy,
    required this.sourceController,
    required this.targetController,
    required this.textController,
    required this.onRun,
    super.key,
  });

  final String providerLabel;
  final PlaygroundAction? busy;
  final TextEditingController sourceController;
  final TextEditingController targetController;
  final TextEditingController textController;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    return PlaygroundFormSection(
      title: l10n.aiPlaygroundSectionTranslation,
      providerLabel: providerLabel,
      runLabel: l10n.aiPlaygroundTranslate,
      isEnabled: busy == null,
      isRunning: busy == PlaygroundAction.translate,
      onRun: onRun,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: sourceController,
                decoration: InputDecoration(
                  labelText: l10n.aiPlaygroundTranslateSource,
                ),
              ),
            ),
            SizedBox(width: t.space12),
            Expanded(
              child: TextField(
                controller: targetController,
                decoration: InputDecoration(
                  labelText: l10n.aiPlaygroundTranslateTarget,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: t.space12),
        TextField(
          controller: textController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: l10n.aiPlaygroundTranslateText,
          ),
        ),
      ],
    );
  }
}

class DictionaryPlaygroundSection extends StatelessWidget {
  const DictionaryPlaygroundSection({
    required this.providerLabel,
    required this.busy,
    required this.wordController,
    required this.sourceController,
    required this.targetController,
    required this.onRun,
    super.key,
  });

  final String providerLabel;
  final PlaygroundAction? busy;
  final TextEditingController wordController;
  final TextEditingController sourceController;
  final TextEditingController targetController;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    return PlaygroundFormSection(
      title: l10n.aiPlaygroundSectionDictionary,
      providerLabel: providerLabel,
      runLabel: l10n.aiPlaygroundDictLookup,
      isEnabled: busy == null,
      isRunning: busy == PlaygroundAction.dictionary,
      onRun: onRun,
      children: [
        TextField(
          controller: wordController,
          decoration: InputDecoration(labelText: l10n.aiPlaygroundDictWord),
        ),
        SizedBox(height: t.space12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: sourceController,
                decoration: InputDecoration(
                  labelText: l10n.aiPlaygroundDictSource,
                ),
              ),
            ),
            SizedBox(width: t.space12),
            Expanded(
              child: TextField(
                controller: targetController,
                decoration: InputDecoration(
                  labelText: l10n.aiPlaygroundDictTarget,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AssessmentPlaygroundSection extends StatelessWidget {
  const AssessmentPlaygroundSection({
    required this.providerLabel,
    required this.busy,
    required this.referenceController,
    required this.languageController,
    required this.onRun,
    super.key,
  });

  final String providerLabel;
  final PlaygroundAction? busy;
  final TextEditingController referenceController;
  final TextEditingController languageController;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return PlaygroundFormSection(
      title: l10n.aiPlaygroundSectionTtsAssessment,
      providerLabel: providerLabel,
      runLabel: l10n.aiPlaygroundAssess,
      isEnabled: busy == null,
      isRunning: busy == PlaygroundAction.assessment,
      onRun: onRun,
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
          controller: referenceController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: l10n.aiPlaygroundAssessmentReference,
          ),
        ),
        SizedBox(height: t.space12),
        TextField(
          controller: languageController,
          decoration: InputDecoration(
            labelText: l10n.aiPlaygroundAssessmentLanguage,
          ),
        ),
      ],
    );
  }
}
