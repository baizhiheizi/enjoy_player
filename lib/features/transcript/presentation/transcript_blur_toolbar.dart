/// Panel-level toolbar widget hosting the "Blur practice" toggle.
///
/// Renders a single right-aligned icon button (`EnjoyTappableIcon`)
/// that flips the global blur toggle via
/// `TranscriptBlurPreferencesCtrl.setEnabled`. Disabled with a
/// "no transcript lines" tooltip when [hasLines] is false.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/enjoy_tappable.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_preferences_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class TranscriptBlurToolbar extends ConsumerWidget {
  const TranscriptBlurToolbar({
    required this.mediaId,
    required this.hasLines,
    super.key,
  });

  /// Currently unused but kept on the widget API so future per-media
  /// state (e.g. media-scoped overrides) can be wired in without
  /// changing the call site.
  // ignore: unused_element_parameter
  final String mediaId;

  /// When `false` the toggle is rendered but disabled with the
  /// "no transcript lines to practice with" tooltip.
  final bool hasLines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = EnjoyThemeTokens.of(context);
    final prefsAsync = ref.watch(transcriptBlurPreferencesCtrlProvider);
    final prefs = prefsAsync.valueOrNull;
    final enabled = prefs?.enabled ?? false;
    final disabled = !hasLines;

    final tooltip = !hasLines && l10n != null
        ? l10n.transcriptBlurEmptyTooltip
        : (l10n?.transcriptBlurToggleTooltip ?? 'Blur practice');

    final semanticLabel = l10n != null
        ? (enabled
              ? l10n.transcriptBlurSemanticsOn
              : l10n.transcriptBlurSemanticsOff)
        : (enabled ? 'Blur practice on' : 'Blur practice off');

    return Padding(
      padding: EdgeInsets.only(
        right: t.space8,
        top: t.space4,
        bottom: t.space4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          EnjoyTappableIcon(
            tooltip: tooltip,
            semanticLabel: semanticLabel,
            onPressed: disabled
                ? null
                : () => ref
                      .read(transcriptBlurPreferencesCtrlProvider.notifier)
                      .setEnabled(!enabled),
            icon: enabled
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ],
      ),
    );
  }
}
