/// Synthesize tool panel for the Craft screen.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/features/craft/presentation/craft_lang_tile.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/craft/presentation/widgets/craft_failure_card.dart';
import 'package:enjoy_player/features/craft/presentation/widgets/craft_field_border.dart';
import 'package:enjoy_player/features/craft/domain/craft_request.dart';
import 'package:enjoy_player/features/craft/presentation/craft_solid_transcript_stt_hint.dart';
import 'package:enjoy_player/features/craft/presentation/voice_picker.dart';
import 'package:enjoy_player/features/craft/presentation/widgets/craft_preview_player.dart';
import 'package:enjoy_player/features/library/presentation/widgets/content_language_picker.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SynthesizeTool extends ConsumerStatefulWidget {
  const SynthesizeTool({super.key});

  @override
  ConsumerState<SynthesizeTool> createState() => _SynthesizeToolState();
}

class _SynthesizeToolState extends ConsumerState<SynthesizeTool> {
  late final TextEditingController _textCtrl;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(craftControllerProvider);
    final controller = ref.read(craftControllerProvider.notifier);

    if (_textCtrl.text != state.synthText) {
      _textCtrl.text = state.synthText;
    }

    final tokens = EnjoyThemeTokens.of(context);
    final canSynthesize =
        !state.isSynthesizing &&
        !state.isSaving &&
        normalizeCraftText(state.synthText).length >= craftMinTextLength;

    return EnjoyCard(
      padding: EdgeInsets.all(tokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EnjoySectionHeader(title: l10n.craftSynthesizeTool),
          SizedBox(height: tokens.space16),
          _SynthLangTile(
            label: l10n.craftTargetLanguageLabel,
            value: state.synthLanguage.toUpperCase(),
            onTap: () => _pickLanguage(state.synthLanguage, controller),
          ),
          SizedBox(height: tokens.space12),
          VoicePicker(
            language: state.synthLanguage,
            selectedVoice: state.selectedVoice,
            onChanged: controller.setSelectedVoice,
          ),
          SizedBox(height: tokens.space16),
          TextField(
            controller: _textCtrl,
            maxLines: 5,
            minLines: 3,
            decoration: InputDecoration(
              labelText: l10n.craftSynthText,
              hintText: l10n.craftTextInputHint,
              border: craftFieldBorder(tokens),
              enabledBorder: craftFieldBorder(tokens),
              focusedBorder: craftFieldBorder(tokens, focused: true),
              suffixIcon: EnjoyIconButton(
                icon: EnjoyIcons.paste,
                tooltip: l10n.craftPasteFromClipboard,
                variant: EnjoyButtonVariant.ghost,
                size: 32,
                onPressed: () => _paste(controller),
              ),
            ),
            onChanged: controller.setSynthText,
          ),
          SizedBox(height: tokens.space16),
          EnjoyButton.brand(
            onPressed: canSynthesize
                ? () => _synthesizeWithOverlay(l10n)
                : null,
            icon: state.isSynthesizing ? null : EnjoyIcons.speak,
            child: state.isSynthesizing
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const LoadingIcon(size: 18),
                      const SizedBox(width: 8),
                      Text(l10n.craftLoadingSynthesizing),
                    ],
                  )
                : Text(
                    state.hasPreview
                        ? l10n.craftReSynthesizeButton
                        : l10n.craftSynthesizeButton,
                  ),
          ),
          if (state.hasPreview) ...[
            SizedBox(height: tokens.space20),
            EnjoySectionHeader(title: l10n.craftPreviewLabel),
            SizedBox(height: tokens.space8),
            CraftPreviewPlayer(audioBytes: state.previewAudioBytes!),
            SizedBox(height: tokens.space12),
            EnjoyButton.secondary(
              onPressed: state.isSaving ? null : _save,
              icon: state.isSaving ? null : EnjoyIcons.save,
              child: state.isSaving
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LoadingIcon(size: 18),
                        SizedBox(width: 8),
                        Text('…'),
                      ],
                    )
                  : Text(l10n.craftSaveToLibrary),
            ),
          ],
          if (state.failure != null)
            CraftInlineFailure(failure: state.failure!, l10n: l10n),
        ],
      ),
    );
  }

  Future<void> _pickLanguage(String current, CraftController controller) async {
    final picked = await showContentLanguagePicker(
      context: context,
      ref: ref,
      selectedValue: current,
    );
    if (!mounted || picked == null) return;
    controller.setSynthLanguage(picked);
  }

  Future<void> _paste(CraftController controller) async {
    final clip = await Clipboard.getData('text/plain');
    if (!mounted) return;
    final t = clip?.text;
    if (t != null && t.isNotEmpty) {
      _textCtrl.text = t;
      controller.setSynthText(t);
    }
  }

  Future<void> _synthesizeWithOverlay(AppLocalizations l10n) async {
    final controller = ref.read(craftControllerProvider.notifier);

    unawaited(
      showEnjoyDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (dialogContext) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LoadingIcon(size: 28, strokeWidth: 2.5),
                  SizedBox(height: EnjoyThemeTokens.of(context).space16),
                  Text(l10n.craftCraftingProgress),
                ],
              ),
            ),
          );
        },
      ),
    );
    await WidgetsBinding.instance.endOfFrame;

    await controller.synthesize();

    if (!mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
  }

  Future<void> _save() async {
    final controller = ref.read(craftControllerProvider.notifier);
    final result = await controller.saveToLibrary();
    if (!mounted || result == null) return;

    maybeShowCraftSolidTranscriptSttHint(
      context,
      savedSolidTimeline: result.wroteSolidTranscript,
    );
    controller.clearResult();
    openPlayerRoute(context, result.mediaId);
  }
}

class _SynthLangTile extends StatelessWidget {
  const _SynthLangTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    return CraftLangTile(
      onTap: onTap,
      verticalPadding: t.space12,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Text(
            value,
            style: enjoyMonoStyle(
              context,
              size: 14,
              weight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          SizedBox(width: t.space4),
          Icon(EnjoyIcons.chevronRight, size: 18, color: t.ink3),
        ],
      ),
    );
  }
}
