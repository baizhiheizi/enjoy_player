/// Synthesize tool panel for the Craft screen.
library;

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/craft/domain/craft_request.dart';
import 'package:enjoy_player/features/craft/presentation/voice_picker.dart';
import 'package:enjoy_player/features/library/presentation/widgets/content_language_picker.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SynthesizeTool extends ConsumerStatefulWidget {
  const SynthesizeTool({super.key});

  @override
  ConsumerState<SynthesizeTool> createState() => _SynthesizeToolState();
}

class _SynthesizeToolState extends ConsumerState<SynthesizeTool> {
  late final TextEditingController _textCtrl;
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    unawaited(_audioPlayer?.dispose() ?? Future.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(craftControllerProvider);
    final controller = ref.read(craftControllerProvider.notifier);
    final theme = Theme.of(context);

    // Sync text controller with state (e.g. when "Use translated text" fires).
    if (_textCtrl.text != state.synthText) {
      _textCtrl.text = state.synthText;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.craftSynthesizeTool, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),

            // Language picker
            _SynthLangTile(
              label: l10n.craftTargetLanguageLabel,
              value: state.synthLanguage.toUpperCase(),
              onTap: () => _pickLanguage(state.synthLanguage, controller),
            ),
            const SizedBox(height: 8),

            // Voice picker
            VoicePicker(
              language: state.synthLanguage,
              selectedVoice: state.selectedVoice,
              onChanged: controller.setSelectedVoice,
            ),
            const SizedBox(height: 12),

            // Text input
            TextField(
              controller: _textCtrl,
              maxLines: 4,
              minLines: 2,
              decoration: InputDecoration(
                labelText: l10n.craftSynthText,
                hintText: l10n.craftTextInputHint,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste_rounded, size: 18),
                  tooltip: l10n.craftPasteFromClipboard,
                  onPressed: () => _paste(controller),
                ),
              ),
              onChanged: controller.setSynthText,
            ),
            const SizedBox(height: 8),

            // Synthesize button
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed:
                    state.isSynthesizing ||
                        state.isSaving ||
                        normalizeCraftText(state.synthText).length <
                            craftMinTextLength
                    ? null
                    : () => _synthesizeWithOverlay(l10n),
                icon: state.isSynthesizing
                    ? const LoadingIcon(size: 16)
                    : const Icon(Icons.record_voice_over_rounded, size: 18),
                label: Text(
                  state.hasPreview
                      ? l10n.craftReSynthesizeButton
                      : l10n.craftSynthesizeButton,
                ),
              ),
            ),

            // Audio preview
            if (state.hasPreview) ...[
              const SizedBox(height: 16),
              Text(l10n.craftPreviewLabel, style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              _PreviewPlayer(
                audioBytes: state.previewAudioBytes!,
                isPlaying: _isPlaying,
                onPlayPause: _togglePlay,
              ),
              const SizedBox(height: 12),
            ],

            // Save to library
            if (state.hasPreview) ...[
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: state.isSaving ? null : _save,
                  icon: state.isSaving
                      ? const LoadingIcon(size: 16)
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(l10n.craftSaveToLibrary),
                ),
              ),
            ],

            // Failure
            if (state.failure != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  state.failure!.message(l10n),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLanguage(String current, CraftController controller) async {
    final picked = await showContentLanguagePicker(
      context: context,
      ref: ref,
      selectedValue: current,
    );
    if (picked != null) {
      controller.setSynthLanguage(picked);
    }
  }

  Future<void> _paste(CraftController controller) async {
    final clip = await Clipboard.getData('text/plain');
    final t = clip?.text;
    if (t != null && t.isNotEmpty) {
      _textCtrl.text = t;
      controller.setSynthText(t);
    }
  }

  Future<void> _synthesizeWithOverlay(AppLocalizations l10n) async {
    final controller = ref.read(craftControllerProvider.notifier);

    // Show a non-dismissible blocking dialog during synthesis — the native
    // Azure Speech SDK call blocks the platform thread, so we need to show
    // a spinner before the freeze kicks in.
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
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.craftCraftingProgress),
                ],
              ),
            ),
          );
        },
      ),
    );
    // Let the dialog paint before the platform thread blocks.
    await WidgetsBinding.instance.endOfFrame;

    await controller.synthesize();

    // Dismiss the blocking dialog.
    if (mounted) {
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) nav.pop();
    }
  }

  Future<void> _togglePlay() async {
    final bytes = ref.read(craftControllerProvider).previewAudioBytes;
    if (bytes == null) return;

    _audioPlayer ??= AudioPlayer();

    if (_isPlaying) {
      await _audioPlayer!.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer!.play(BytesSource(bytes));
      setState(() => _isPlaying = true);
      _audioPlayer!.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  Future<void> _save() async {
    final controller = ref.read(craftControllerProvider.notifier);
    final mediaId = await controller.saveToLibrary();
    if (!mounted || mediaId == null) return;

    controller.clearResult();

    final state = ref.read(craftControllerProvider);
    if (state.dedupedExistingId != null) {
      // Already in library — open it.
      openPlayerRoute(context, state.dedupedExistingId!);
    } else {
      openPlayerRoute(context, mediaId);
    }
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
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        dense: true,
        title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        trailing: Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _PreviewPlayer extends StatelessWidget {
  const _PreviewPlayer({
    required this.audioBytes,
    required this.isPlaying,
    required this.onPlayPause,
  });

  final dynamic audioBytes; // Uint8List
  final bool isPlaying;
  final VoidCallback onPlayPause;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
            onPressed: onPlayPause,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.craftPreviewLabel,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
