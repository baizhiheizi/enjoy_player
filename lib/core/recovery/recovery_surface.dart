/// Full-screen error surface shown when the local Drift database cannot
/// be opened. Offers copy-to-clipboard, open-logs-folder, and a
/// destructive "Reset local library" action that backs up before wiping.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/recovery/recovery_actions.dart';
import 'package:enjoy_player/core/recovery/recovery_busy_action.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class RecoverySurface extends StatefulWidget {
  const RecoverySurface({
    required this.error,
    this.stack,
    this.onReset,
    super.key,
  });

  final Object error;
  final StackTrace? stack;

  /// Performs the actual backup + wipe, and (unlike the bare
  /// [resetLocalLibraryWithBackup] it defaults to) is responsible for also
  /// closing and re-initializing any live Drift connections so the app can
  /// recover in place. Injected by `app.dart`, which has Riverpod `ref`
  /// access; defaults to the plain file-only reset for standalone use/tests.
  final Future<RecoveryResetOutcome> Function()? onReset;

  @override
  State<RecoverySurface> createState() => _RecoverySurfaceState();
}

class _RecoverySurfaceState extends State<RecoverySurface>
    with RecoveryBusyAction {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(t.space24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 64, color: cs.error),
                  SizedBox(height: t.space16),
                  Text(
                    l10n.recoveryTitle,
                    textAlign: TextAlign.center,
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: t.space12),
                  Text(
                    l10n.recoverySubtitle,
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: t.space24),
                  EnjoyCard(
                    padding: EdgeInsets.all(t.space20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.error.toString(),
                          style: tt.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: t.space16),
                        SizedBox(
                          width: double.infinity,
                          child: EnjoyButton.secondary(
                            icon: Icons.copy_rounded,
                            onPressed: busy ? null : _onCopy,
                            child: Text(l10n.recoveryCopyError),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: t.space16),
                  SizedBox(
                    width: double.infinity,
                    child: EnjoyButton.secondary(
                      icon: Icons.folder_open_rounded,
                      onPressed: busy ? null : _onOpenLogs,
                      child: Text(l10n.recoveryOpenLogs),
                    ),
                  ),
                  SizedBox(height: t.space24),
                  EnjoyCard(
                    padding: EdgeInsets.all(t.space20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.recoveryResetLibrary,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: t.space8),
                        Text(
                          l10n.recoveryResetLibrarySubtitle,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        SizedBox(height: t.space16),
                        SizedBox(
                          width: double.infinity,
                          child: EnjoyButton.destructive(
                            icon: Icons.delete_outline_rounded,
                            onPressed: busy ? null : _onResetRequest,
                            child: Text(l10n.recoveryResetLibrary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onCopy() => runBusyAction<bool>(
        () => copyErrorToClipboard(widget.error, widget.stack),
        (ctx, ok) async {
          final l10n = AppLocalizations.of(ctx)!;
          if (ok) {
            AppNotice.success(ctx, l10n.recoveryCopiedToClipboard);
          } else {
            AppNotice.error(ctx, l10n.recoveryCopiedToClipboard);
          }
        },
      );

  Future<void> _onOpenLogs() => runBusyAction<bool>(
        openLogsFolder,
        (ctx, ok) async {
          if (ok) return;
          final l10n = AppLocalizations.of(ctx)!;
          AppNotice.error(ctx, l10n.recoveryOpenLogsError);
        },
      );

  Future<void> _onResetRequest() async {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.recoveryResetLibraryConfirmTitle),
        content: Text(
          l10n.recoveryResetLibraryConfirmBody,
          style: tt.bodyMedium?.copyWith(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.authCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: cs.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.recoveryResetLibraryConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _onResetConfirm();
    }
  }

  Future<void> _onResetConfirm() => runBusyAction<RecoveryResetOutcome>(
        () => (widget.onReset ?? resetLocalLibraryWithBackup)(),
        (ctx, outcome) async {
          final l10n = AppLocalizations.of(ctx)!;
          switch (outcome) {
            case RecoveryResetOutcome.success:
              AppNotice.success(ctx, l10n.recoveryResetLibrarySuccess);
            case RecoveryResetOutcome.backupFailed:
              AppNotice.error(ctx, l10n.recoveryResetLibraryBackupError);
            case RecoveryResetOutcome.wipeFailed:
              AppNotice.error(ctx, l10n.recoveryResetLibraryError);
          }
        },
      );
}
