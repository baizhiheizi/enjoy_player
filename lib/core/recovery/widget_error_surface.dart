/// Full-screen fallback when a widget throws during build (release builds).
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';

import 'package:enjoy_player/core/recovery/recovery_actions.dart';
import 'package:enjoy_player/core/recovery/recovery_busy_action.dart';
import 'package:enjoy_player/core/recovery/recovery_error_panel.dart';
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
    final cs = Theme.of(context).colorScheme;
    final message = widget.details.exceptionAsString();

    return Material(
      color: cs.surface,
      child: RecoveryErrorLayout(
        children: [
          RecoveryErrorPanel(
            icon: EnjoyIcons.error,
            iconSize: 56,
            title: l10n.widgetErrorTitle,
            subtitle: l10n.widgetErrorSubtitle,
            message: message,
            busy: busy,
            onCopy: _onCopy,
          ),
        ],
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
