/// Full-screen fallback when a widget throws during build (release builds).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/recovery/recovery_actions.dart';
import 'package:enjoy_player/core/recovery/recovery_busy_action.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Shown via [ErrorWidget.builder] when the widget tree hits an uncaught error.
class WidgetErrorSurface extends StatefulWidget {
  const WidgetErrorSurface({required this.details, super.key});

  final FlutterErrorDetails details;

  @override
  State<WidgetErrorSurface> createState() => _WidgetErrorSurfaceState();
}

class _WidgetErrorSurfaceState extends State<WidgetErrorSurface>
    with RecoveryBusyAction {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final message = widget.details.exceptionAsString();

    return Material(
      color: cs.surface,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(t.space24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.error_outline_rounded, size: 56, color: cs.error),
                  SizedBox(height: t.space16),
                  Text(
                    l10n.widgetErrorTitle,
                    textAlign: TextAlign.center,
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: t.space12),
                  Text(
                    l10n.widgetErrorSubtitle,
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
                          message,
                          style: tt.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 8,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onCopy() => runBusyAction<bool>(
    () => copyErrorToClipboard(widget.details.exception, widget.details.stack),
    copyErrorShowNotice,
  );
}

/// Installs [ErrorWidget.builder] for release/profile (debug keeps red screen).
void installReleaseWidgetErrorBuilder() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return WidgetErrorSurface(details: details);
  };
}
