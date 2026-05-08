/// Echo segment resize controls (parity with web `EchoRegionControls`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_tooltip_label.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

enum EchoRegionBarPosition { top, bottom }

class EchoRegionControlsBar extends ConsumerWidget {
  const EchoRegionControlsBar({
    required this.position,
    required this.expandDisabled,
    required this.shrinkDisabled,
    required this.onExpand,
    required this.onShrink,
    this.dense = false,
    super.key,
  });

  final EchoRegionBarPosition position;
  final bool expandDisabled;
  final bool shrinkDisabled;
  final VoidCallback onExpand;
  final VoidCallback onShrink;

  /// Tighter vertical padding when nested inside a merged echo card.
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tok = EnjoyThemeTokens.of(context);

    final expandLabel =
        position == EchoRegionBarPosition.top
            ? l10n.expandEchoBackward
            : l10n.expandEchoForward;
    final shrinkLabel =
        position == EchoRegionBarPosition.top
            ? l10n.shrinkEchoBackward
            : l10n.shrinkEchoForward;

    final expandId =
        position == EchoRegionBarPosition.top
            ? 'player.expandEchoBackward'
            : 'player.expandEchoForward';
    final shrinkId =
        position == EchoRegionBarPosition.top
            ? 'player.shrinkEchoBackward'
            : 'player.shrinkEchoForward';
    final expandTip = hotkeyTooltipLabel(ref, expandId, expandLabel);
    final shrinkTip = hotkeyTooltipLabel(ref, shrinkId, shrinkLabel);

    final expandIcon =
        position == EchoRegionBarPosition.top
            ? Icons.expand_less
            : Icons.expand_more;

    final edgePadding =
        dense
            ? EdgeInsets.symmetric(vertical: tok.space4)
            : (position == EchoRegionBarPosition.top
                ? EdgeInsets.only(bottom: tok.space4)
                : EdgeInsets.only(top: tok.space4));

    return Padding(
      padding: edgePadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          SizedBox(width: tok.space8),
          Tooltip(
            message: expandTip,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: expandDisabled ? null : onExpand,
              icon: Icon(expandIcon, size: 20),
            ),
          ),
          Tooltip(
            message: shrinkTip,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: shrinkDisabled ? null : onShrink,
              icon: const Icon(Icons.remove, size: 20),
            ),
          ),
          SizedBox(width: tok.space8),
          Expanded(
            child: Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}
