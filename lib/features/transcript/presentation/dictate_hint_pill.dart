/// The pill over the transcript while the Dictate lens hides the text.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class DictateHintPill extends StatelessWidget {
  const DictateHintPill({super.key});

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: ShapeDecoration(
        color: t.raised,
        shape: const StadiumBorder(),
        shadows: t.shadowLift,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(EnjoyIcons.eyeOff, size: 15, color: t.ink2),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isDesktop
                  ? l10n.playerDictateHintHover
                  : l10n.playerDictateHintHold,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: t.ink2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
