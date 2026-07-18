/// Listens for pending updates and shows prompts; bootstraps startup checks.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/release/distribution_channel.dart';
import 'package:enjoy_player/features/update/application/update_controller.dart';
import 'package:enjoy_player/features/update/domain/update_types.dart';
import 'package:enjoy_player/features/update/presentation/update_prompt_dialog.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class UpdatePromptHost extends ConsumerStatefulWidget {
  const UpdatePromptHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<UpdatePromptHost> createState() => _UpdatePromptHostState();
}

class _UpdatePromptHostState extends ConsumerState<UpdatePromptHost> {
  var _bootstrapped = false;
  var _showingPrompt = false;

  @override
  void initState() {
    super.initState();
    if (isDirectDistributionChannel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_bootstrapped) {
          _bootstrapped = true;
          unawaited(ref.read(updateCtrlProvider.notifier).bootstrap());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UpdateCheckResult?>(updateCtrlProvider, (prev, next) {
      if (next == null || !next.hasUpdate || _showingPrompt) return;
      unawaited(_maybeShowPrompt(next));
    });
    return widget.child;
  }

  Future<void> _maybeShowPrompt(UpdateCheckResult result) async {
    final release = result.release;
    if (release == null || !mounted) return;
    _showingPrompt = true;
    try {
      await _showPrompt(context, ref, release);
    } finally {
      _showingPrompt = false;
    }
  }
}

Future<void> _showPrompt(
  BuildContext context,
  WidgetRef ref,
  AppRelease release,
) {
  final ctrl = ref.read(updateCtrlProvider.notifier);
  return showUpdatePromptDialog(
    context: context,
    release: release,
    onApply: ctrl.applyPendingUpdate,
    onCancelApply: ctrl.cancelPendingUpdate,
    onLater: () {
      unawaited(ctrl.snoozeOptionalUpdate(release));
    },
    onDismiss: release.severity == UpdateSeverity.optional
        ? ctrl.dismissOptionalPrompt
        : null,
  );
}

/// Manual check from Settings/About.
Future<void> runManualUpdateCheck(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  if (!isDirectDistributionChannel) {
    AppNotice.info(context, l10n.updateStoreChannelHint);
    return;
  }
  final result = await ref
      .read(updateCtrlProvider.notifier)
      .checkForUpdatesManual();
  if (!context.mounted) return;
  if (result.errorMessage != null && result.errorMessage == 'offline') {
    AppNotice.error(context, l10n.updateCheckOffline);
    return;
  }
  if (!result.hasUpdate) {
    AppNotice.success(context, l10n.updateUpToDate);
    return;
  }
  final release = result.release;
  if (release == null) return;
  await _showPrompt(context, ref, release);
}
