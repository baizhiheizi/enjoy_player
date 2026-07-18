/// Optional and mandatory update dialogs with Android download progress.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/features/update/domain/update_types.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Starts applying an update and yields progress for the prompt UI.
typedef UpdateApplyStreamFactory = Stream<UpdateInstallProgress> Function();

/// Cancels an in-flight update download when supported.
typedef UpdateCancelCallback = Future<void> Function();

Future<void> showUpdatePromptDialog({
  required BuildContext context,
  required AppRelease release,
  required UpdateApplyStreamFactory onApply,
  required VoidCallback onLater,
  VoidCallback? onDismiss,
  UpdateCancelCallback? onCancelApply,
}) {
  final mandatory = release.severity == UpdateSeverity.mandatory;

  return showEnjoyDialog<void>(
    context: context,
    barrierDismissible: !mandatory,
    builder: (ctx) {
      return UpdatePromptDialog(
        release: release,
        onApply: onApply,
        onLater: onLater,
        onDismiss: onDismiss,
        onCancelApply: onCancelApply,
      );
    },
  );
}

class UpdatePromptDialog extends StatefulWidget {
  const UpdatePromptDialog({
    required this.release,
    required this.onApply,
    required this.onLater,
    this.onDismiss,
    this.onCancelApply,
    super.key,
  });

  final AppRelease release;
  final UpdateApplyStreamFactory onApply;
  final VoidCallback onLater;
  final VoidCallback? onDismiss;
  final UpdateCancelCallback? onCancelApply;

  @override
  State<UpdatePromptDialog> createState() => _UpdatePromptDialogState();
}

class _UpdatePromptDialogState extends State<UpdatePromptDialog> {
  UpdateInstallProgress? _progress;
  StreamSubscription<UpdateInstallProgress>? _subscription;
  var _starting = false;

  /// Enables a single programmatic [Navigator.pop] while mandatory prompts keep
  /// system-back blocked via [PopScope].
  var _allowProgrammaticClose = false;

  bool get _mandatory => widget.release.severity == UpdateSeverity.mandatory;

  bool get _busy {
    final phase = _progress?.phase;
    return _starting ||
        phase == UpdateInstallPhase.preparing ||
        phase == UpdateInstallPhase.downloading ||
        phase == UpdateInstallPhase.verifying ||
        phase == UpdateInstallPhase.openingInstaller;
  }

  bool get _failed => _progress?.phase == UpdateInstallPhase.failed;

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }

  void _startApply() {
    if (_busy) return;
    unawaited(_subscription?.cancel());
    _subscription = null;

    setState(() {
      _starting = true;
      _progress = const UpdateInstallProgress.preparing();
    });

    _subscription = widget.onApply().listen(
      _onProgress,
      onError: (Object e, StackTrace st) {
        _onProgress(
          UpdateInstallProgress.failed(
            reason: UpdateInstallFailureReason.internal,
            detail: e.toString(),
          ),
        );
      },
      onDone: () {
        if (!mounted) return;
        final phase = _progress?.phase;
        if (phase == UpdateInstallPhase.openingInstaller ||
            phase == UpdateInstallPhase.completed) {
          _closeDialog();
        }
      },
      cancelOnError: false,
    );
  }

  void _onProgress(UpdateInstallProgress progress) {
    if (!mounted) return;
    setState(() {
      _starting = false;
      _progress = progress;
    });
    if (progress.phase == UpdateInstallPhase.completed) {
      _closeDialog();
    }
  }

  void _closeDialog() {
    if (!mounted) return;
    // Optional prompts are always poppable; pop immediately.
    if (!_mandatory) {
      Navigator.of(context).pop();
      return;
    }
    // Mandatory PopScope blocks pops until we flip this flag and rebuild.
    if (_allowProgrammaticClose) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _allowProgrammaticClose = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  void _cancelBusy() {
    unawaited(_subscription?.cancel());
    _subscription = null;

    final cancel = widget.onCancelApply;
    if (cancel != null) {
      unawaited(cancel());
    }
    if (!mounted) return;
    if (_mandatory) {
      // Stay on the blocking prompt so the user can retry.
      setState(() {
        _starting = false;
        _progress = null;
      });
      return;
    }
    _closeDialog();
  }

  void _closeOptional({required VoidCallback after}) {
    if (_busy) return;
    _closeDialog();
    after();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final notes = widget.release.manifest.notes.trim();
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      // Optional prompts stay dismissible; mandatory stays blocked unless we
      // intentionally open the system installer and close via [_closeDialog].
      canPop: !_mandatory || _allowProgrammaticClose,
      child: AlertDialog(
        title: Text(
          _mandatory ? l10n.updateMandatoryTitle : l10n.updateAvailableTitle,
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: t.modalMaxWidth),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.updateVersionLine(
                    widget.release.currentVersion,
                    widget.release.manifest.version,
                  ),
                ),
                if (notes.isNotEmpty && !_busy && !_failed) ...[
                  SizedBox(height: t.space12),
                  Text(notes),
                ],
                if (_busy || _failed) ...[
                  SizedBox(height: t.space16),
                  _UpdateProgressBody(
                    progress: _progress,
                    l10n: l10n,
                    colorScheme: cs,
                    tokens: t,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: _buildActions(l10n),
      ),
    );
  }

  List<Widget> _buildActions(AppLocalizations l10n) {
    if (_busy) {
      return [
        TextButton(onPressed: _cancelBusy, child: Text(l10n.updateCancel)),
      ];
    }
    if (_failed) {
      return [
        if (!_mandatory)
          TextButton(
            onPressed: () => _closeOptional(after: widget.onLater),
            child: Text(l10n.updateLater),
          ),
        FilledButton(onPressed: _startApply, child: Text(l10n.updateRetry)),
      ];
    }

    return [
      if (!_mandatory && widget.onDismiss != null)
        TextButton(
          onPressed: () => _closeOptional(after: widget.onDismiss!),
          child: Text(l10n.updateDismiss),
        ),
      if (!_mandatory)
        TextButton(
          onPressed: () => _closeOptional(after: widget.onLater),
          child: Text(l10n.updateLater),
        ),
      FilledButton(onPressed: _startApply, child: Text(l10n.updateNow)),
    ];
  }
}

class _UpdateProgressBody extends StatelessWidget {
  const _UpdateProgressBody({
    required this.progress,
    required this.l10n,
    required this.colorScheme,
    required this.tokens,
  });

  final UpdateInstallProgress? progress;
  final AppLocalizations l10n;
  final ColorScheme colorScheme;
  final EnjoyThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    if (p == null) {
      return const SizedBox.shrink();
    }

    if (p.phase == UpdateInstallPhase.failed) {
      return Text(
        _failureMessage(l10n, p.failureReason),
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colorScheme.error),
      );
    }

    final statusText = switch (p.phase) {
      UpdateInstallPhase.preparing => l10n.updatePreparing,
      UpdateInstallPhase.downloading => l10n.updateDownloading(
        ((p.percent ?? 0) * 100).round().clamp(0, 100),
      ),
      UpdateInstallPhase.verifying => l10n.updateVerifying,
      UpdateInstallPhase.openingInstaller => l10n.updateOpeningInstaller,
      UpdateInstallPhase.completed => l10n.updateOpeningInstaller,
      UpdateInstallPhase.canceled => l10n.updatePreparing,
      UpdateInstallPhase.failed => l10n.updateErrorGeneric,
    };

    final showDeterminate = p.phase == UpdateInstallPhase.downloading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (!showDeterminate) ...[
              const LoadingIcon(size: 18),
              SizedBox(width: tokens.space12),
            ],
            Expanded(child: Text(statusText)),
          ],
        ),
        if (showDeterminate) ...[
          SizedBox(height: tokens.space12),
          LinearProgressIndicator(value: (p.percent ?? 0).clamp(0.0, 1.0)),
        ] else if (p.phase == UpdateInstallPhase.preparing ||
            p.phase == UpdateInstallPhase.verifying ||
            p.phase == UpdateInstallPhase.openingInstaller) ...[
          SizedBox(height: tokens.space12),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  String _failureMessage(
    AppLocalizations l10n,
    UpdateInstallFailureReason? reason,
  ) {
    return switch (reason) {
      UpdateInstallFailureReason.download => l10n.updateErrorDownload,
      UpdateInstallFailureReason.checksum => l10n.updateErrorChecksum,
      UpdateInstallFailureReason.permission => l10n.updateErrorPermission,
      UpdateInstallFailureReason.alreadyRunning =>
        l10n.updateErrorAlreadyRunning,
      UpdateInstallFailureReason.installation => l10n.updateErrorInstallation,
      UpdateInstallFailureReason.canceled => l10n.updateErrorGeneric,
      UpdateInstallFailureReason.internal => l10n.updateErrorGeneric,
      UpdateInstallFailureReason.unknown => l10n.updateErrorGeneric,
      null => l10n.updateErrorGeneric,
    };
  }
}
