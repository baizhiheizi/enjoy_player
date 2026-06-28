/// Full-screen fallback when a widget throws during build (release builds).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/recovery/recovery_actions.dart';
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

class _WidgetErrorSurfaceState extends State<WidgetErrorSurface> {
  bool _busy = false;

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
                            onPressed: _busy ? null : _onCopy,
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

  Future<void> _onCopy() async {
    setState(() => _busy = true);
    try {
      final ok = await copyErrorToClipboard(
        widget.details.exception,
        widget.details.stack,
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      if (ok) {
        AppNotice.success(context, l10n.recoveryCopiedToClipboard);
      } else {
        AppNotice.error(context, l10n.recoveryCopiedToClipboard);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// Installs [ErrorWidget.builder] for release/profile (debug keeps red screen).
void installReleaseWidgetErrorBuilder() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return WidgetErrorSurface(details: details);
  };
}
