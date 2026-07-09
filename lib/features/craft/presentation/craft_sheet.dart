/// Craft from text: entry sheet shown from the import chooser.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/theme/widgets/sheet_drag_handle.dart';
import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/craft/domain/craft_failure.dart';
import 'package:enjoy_player/features/craft/domain/craft_job_state.dart';
import 'package:enjoy_player/features/craft/domain/craft_job_status.dart';
import 'package:enjoy_player/features/craft/domain/craft_mode.dart';
import 'package:enjoy_player/features/library/presentation/widgets/content_language_picker.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Shows the Craft from text bottom sheet.
Future<void> showCraftSheet(BuildContext context, WidgetRef ref) async {
  await showEnjoySheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => const CraftSheet(),
  );
}

class CraftSheet extends ConsumerStatefulWidget {
  const CraftSheet({super.key});

  @override
  ConsumerState<CraftSheet> createState() => _CraftSheetState();
}

class _CraftSheetState extends ConsumerState<CraftSheet> {
  late final TextEditingController _textController;
  String? _sourceLanguage;
  late String _targetLanguage;
  bool _dialogShown = false;
  bool _completionHandled = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    final prefs = ref.read(appPreferencesCtrlProvider);
    final prefsState = prefs.whenOrNull(data: (s) => s);
    _targetLanguage = canonicalMediaLanguageTag(
      prefsState?.effectiveLearningLanguage ?? 'en',
    );
    // Reset any stale controller state from a previous sheet open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = ref.read(craftControllerProvider.notifier);
      controller.reset();
      controller.setSourceLanguage(_sourceLanguage);
      controller.setTargetLanguage(_targetLanguage);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final jobState = ref.watch(craftControllerProvider);
    final controller = ref.read(craftControllerProvider.notifier);
    final theme = Theme.of(context);

    // Handle running state → show blocking dialog.
    if (jobState.isRunning && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showProgressDialog(l10n);
      });
    }

    // Handle completion.
    if (jobState.status == CraftJobStatus.completed && !_completionHandled) {
      _completionHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleCompletion(jobState);
      });
    }

    // Reset dialog flag when idle/failed.
    if (!jobState.isRunning && _dialogShown && !_completionHandled) {
      _dismissDialog();
      _dialogShown = false;
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PaddedSheetDragHandle(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  l10n.craftSheetTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 16),

              // Mode selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SegmentedButton<CraftMode>(
                  segments: [
                    ButtonSegment(
                      value: CraftMode.translateThenSpeak,
                      label: Text(
                        l10n.craftModeTranslateThenSpeak,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    ButtonSegment(
                      value: CraftMode.speakDirectly,
                      label: Text(
                        l10n.craftModeSpeakDirectly,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                  selected: {jobState.mode},
                  onSelectionChanged: (s) => controller.selectMode(s.first),
                ),
              ),
              const SizedBox(height: 16),

              // Source language (Translate then speak only)
              if (jobState.mode == CraftMode.translateThenSpeak) ...[
                _LanguageTile(
                  label: l10n.craftSourceLanguageLabel,
                  value: _sourceLanguage ?? '—',
                  onTap: _pickSourceLanguage,
                ),
                const SizedBox(height: 8),
              ],

              // Target language
              _LanguageTile(
                label: l10n.craftTargetLanguageLabel,
                value: _targetLanguage,
                onTap: _pickTargetLanguage,
              ),
              const SizedBox(height: 16),

              // Text input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _textController,
                  maxLines: 6,
                  minLines: 3,
                  decoration: InputDecoration(
                    hintText: l10n.craftTextInputHint,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.paste_rounded, size: 18),
                      tooltip: l10n.craftPasteFromClipboard,
                      onPressed: _pasteFromClipboard,
                    ),
                  ),
                  onChanged: (v) => controller.setText(v),
                ),
              ),

              // Character count / length cap notice
              if (controller.isOverLengthCap)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    l10n.craftLengthCapNotice,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),

              // Same-language suggestion
              if (controller.shouldSuggestSpeakDirectly)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.craftSameLanguageHint,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () =>
                                controller.selectMode(CraftMode.speakDirectly),
                            child: Text(l10n.craftSameLanguageSwitch),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Failure display
              if (jobState.failure != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: _FailureCard(failure: jobState.failure!),
                ),

              const SizedBox(height: 16),

              // Craft action button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FilledButton.icon(
                  onPressed: controller.canSubmit ? _submit : null,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(l10n.craftAction),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final clip = await Clipboard.getData('text/plain');
    final t = clip?.text;
    if (t != null && t.isNotEmpty) {
      _textController.text = t;
      ref.read(craftControllerProvider.notifier).setText(t);
    }
  }

  Future<void> _pickSourceLanguage() async {
    final picked = await showContentLanguagePicker(
      context: context,
      ref: ref,
      selectedValue: _sourceLanguage,
      title: AppLocalizations.of(context)!.craftSourceLanguageLabel,
    );
    if (picked != null) {
      setState(() => _sourceLanguage = picked);
      ref.read(craftControllerProvider.notifier).setSourceLanguage(picked);
    }
  }

  Future<void> _pickTargetLanguage() async {
    final picked = await showContentLanguagePicker(
      context: context,
      ref: ref,
      selectedValue: _targetLanguage,
      title: AppLocalizations.of(context)!.craftTargetLanguageLabel,
    );
    if (picked != null) {
      setState(() => _targetLanguage = picked);
      ref.read(craftControllerProvider.notifier).setTargetLanguage(picked);
    }
  }

  Future<void> _submit() async {
    final controller = ref.read(craftControllerProvider.notifier);
    final currentState = ref.read(craftControllerProvider);
    // Sync mode-specific language settings before submit.
    controller.setSourceLanguage(
      currentState.mode == CraftMode.translateThenSpeak
          ? _sourceLanguage
          : null,
    );
    controller.setTargetLanguage(_targetLanguage);
    await controller.submit();
  }

  void _showProgressDialog(AppLocalizations l10n) {
    unawaited(
      showEnjoyDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (dialogContext) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              content: Row(
                children: [
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(width: 24),
                  Expanded(child: Text(l10n.craftCraftingProgress)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _dismissDialog() {
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
  }

  void _handleCompletion(CraftJobState jobState) {
    _dismissDialog();

    // Close the Craft sheet.
    if (mounted) Navigator.of(context).pop();

    final l10n = AppLocalizations.of(context)!;
    if (jobState.dedupedExistingId != null) {
      _showAlreadyInLibrary(jobState.dedupedExistingId!, l10n);
    } else if (jobState.resultMediaId != null) {
      openPlayerRoute(context, jobState.resultMediaId!);
    }

    ref.read(craftControllerProvider.notifier).reset();
  }

  void _showAlreadyInLibrary(String mediaId, AppLocalizations l10n) {
    unawaited(
      showEnjoyAlertDialog<void>(
        context: context,
        title: Text(l10n.craftAlreadyInLibrary),
        actionsBuilder: (ctx) => [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).closeButtonLabel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              openPlayerRoute(context, mediaId);
            },
            child: Text(l10n.craftOpenExisting),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          dense: true,
          title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          trailing: Text(
            value.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _FailureCard extends StatelessWidget {
  const _FailureCard({required this.failure});

  final CraftFailure failure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(failure.message(l10n))),
            TextButton(
              onPressed: () => _handleAction(context, failure.action),
              child: Text(_actionLabel(context, l10n, failure.action)),
            ),
          ],
        ),
      ),
    );
  }

  String _actionLabel(
    BuildContext context,
    AppLocalizations l10n,
    CraftFailureAction action,
  ) {
    return switch (action) {
      CraftFailureAction.retry => l10n.craftRetry,
      CraftFailureAction.openAiSettings => l10n.craftOpenAiSettings,
      CraftFailureAction.switchToSpeakDirectly => l10n.craftSameLanguageSwitch,
      CraftFailureAction.signIn => MaterialLocalizations.of(
        context,
      ).okButtonLabel,
    };
  }

  void _handleAction(BuildContext context, CraftFailureAction action) {
    switch (action) {
      case CraftFailureAction.openAiSettings:
        GoRouter.of(context).go('/settings/ai-providers');
        break;
      case CraftFailureAction.retry:
      case CraftFailureAction.switchToSpeakDirectly:
      case CraftFailureAction.signIn:
        break;
    }
  }
}
