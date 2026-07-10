/// Translate tool panel for the Craft screen.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/craft/domain/craft_request.dart';
import 'package:enjoy_player/features/craft/domain/translation_style.dart';
import 'package:enjoy_player/features/craft/presentation/style_picker.dart';
import 'package:enjoy_player/features/library/presentation/widgets/content_language_picker.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class TranslateTool extends ConsumerStatefulWidget {
  const TranslateTool({super.key});

  @override
  ConsumerState<TranslateTool> createState() => _TranslateToolState();
}

class _TranslateToolState extends ConsumerState<TranslateTool> {
  late final TextEditingController _sourceCtrl;
  late final TextEditingController _resultCtrl;

  @override
  void initState() {
    super.initState();
    _sourceCtrl = TextEditingController();
    _resultCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prefs = ref.read(appPreferencesCtrlProvider);
      final prefsState = prefs.whenOrNull(data: (s) => s);
      final nativeLang = canonicalMediaLanguageTag(
        prefsState?.effectiveNativeLanguage ?? 'en',
      );
      final learnLang = canonicalMediaLanguageTag(
        prefsState?.effectiveLearningLanguage ?? 'en',
      );
      ref.read(craftControllerProvider.notifier)
        ..setSourceLanguage(nativeLang)
        ..setTargetLanguage(learnLang);
    });
  }

  @override
  void dispose() {
    _sourceCtrl.dispose();
    _resultCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(craftControllerProvider);
    final controller = ref.read(craftControllerProvider.notifier);
    final theme = Theme.of(context);

    // Sync result controller with state.
    if (state.translatedText != null &&
        _resultCtrl.text != state.translatedText &&
        !_resultCtrl.selection.isValid) {
      _resultCtrl.text = state.translatedText!;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.craftTranslateTool, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),

            // Language selectors with swap
            _LanguageRow(
              sourceLabel: l10n.craftSourceLanguageLabel,
              targetLabel: l10n.craftTargetLanguageLabel,
              sourceValue: state.sourceLanguage ?? '—',
              targetValue: state.targetLanguage,
              onSwap: controller.swapLanguages,
              onPickSource: () =>
                  _pickLanguage(isSource: true, current: state.sourceLanguage),
              onPickTarget: () =>
                  _pickLanguage(isSource: false, current: state.targetLanguage),
            ),
            const SizedBox(height: 12),

            // Style picker
            StylePicker(value: state.style, onChanged: controller.setStyle),

            // Custom prompt input
            if (state.style == TranslationStyle.custom) ...[
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: l10n.craftCustomPromptHint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
                onChanged: controller.setCustomPrompt,
              ),
            ],
            const SizedBox(height: 12),

            // Source text input
            TextField(
              controller: _sourceCtrl,
              maxLines: 4,
              minLines: 2,
              decoration: InputDecoration(
                labelText: l10n.craftSourceText,
                hintText: l10n.craftTextInputHint,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste_rounded, size: 18),
                  tooltip: l10n.craftPasteFromClipboard,
                  onPressed: () =>
                      _paste(_sourceCtrl, controller.setSourceText),
                ),
              ),
              onChanged: controller.setSourceText,
            ),
            const SizedBox(height: 8),

            // Translate button
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed:
                    state.isTranslating ||
                        normalizeCraftText(state.sourceText).length <
                            craftMinTextLength
                    ? null
                    : controller.translate,
                icon: state.isTranslating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.translate_rounded, size: 18),
                label: Text(
                  state.translatedText != null
                      ? l10n.craftReTranslateButton
                      : l10n.craftTranslateButton,
                ),
              ),
            ),

            // Result (editable)
            if (state.translatedText != null) ...[
              const SizedBox(height: 16),
              Text(l10n.craftTranslatedText, style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              TextField(
                controller: _resultCtrl,
                maxLines: 6,
                minLines: 3,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: controller.setTranslatedText,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _copy(state.translatedText!, l10n),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: Text(l10n.craftCopyTranslation),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: controller.useTranslatedText,
                    icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                    label: Text(l10n.craftUseTranslatedText),
                  ),
                ],
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

  Future<void> _pickLanguage({
    required bool isSource,
    required String? current,
  }) async {
    final picked = await showContentLanguagePicker(
      context: context,
      ref: ref,
      selectedValue: current,
    );
    if (picked != null) {
      final controller = ref.read(craftControllerProvider.notifier);
      if (isSource) {
        controller.setSourceLanguage(picked);
      } else {
        controller.setTargetLanguage(picked);
      }
    }
  }

  Future<void> _paste(
    TextEditingController ctrl,
    void Function(String) onChanged,
  ) async {
    final clip = await Clipboard.getData('text/plain');
    final t = clip?.text;
    if (t != null && t.isNotEmpty) {
      ctrl.text = t;
      onChanged(t);
    }
  }

  void _copy(String text, AppLocalizations l10n) {
    unawaited(Clipboard.setData(ClipboardData(text: text)));
    if (!mounted) return;
    AppNotice.success(context, l10n.craftCopiedToClipboard);
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.sourceLabel,
    required this.targetLabel,
    required this.sourceValue,
    required this.targetValue,
    required this.onSwap,
    required this.onPickSource,
    required this.onPickTarget,
  });

  final String sourceLabel;
  final String targetLabel;
  final String sourceValue;
  final String targetValue;
  final VoidCallback onSwap;
  final VoidCallback onPickSource;
  final VoidCallback onPickTarget;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LangTile(
            label: sourceLabel,
            value: sourceValue.toUpperCase(),
            onTap: onPickSource,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.swap_horiz_rounded),
          tooltip: AppLocalizations.of(context)!.craftSwapLanguages,
          onPressed: onSwap,
        ),
        Expanded(
          child: _LangTile(
            label: targetLabel,
            value: targetValue.toUpperCase(),
            onTap: onPickTarget,
          ),
        ),
      ],
    );
  }
}

class _LangTile extends StatelessWidget {
  const _LangTile({
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
