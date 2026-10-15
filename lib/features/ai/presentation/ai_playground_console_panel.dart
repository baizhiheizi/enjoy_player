/// Output console for the AI playground (entry value type + empty/loaded views).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const double _consoleViewportHeight = 320;

class PlaygroundConsoleEntry {
  const PlaygroundConsoleEntry(this.text, {required this.isError});

  final String text;
  final bool isError;
}

class PlaygroundConsolePanel extends StatelessWidget {
  const PlaygroundConsolePanel({required this.entries, super.key});

  final List<PlaygroundConsoleEntry> entries;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    if (entries.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: t.space16),
        child: Column(
          children: [
            const EnjoyIconOrb(icon: EnjoyIcons.code, size: 56),
            SizedBox(height: t.space16),
            Text(
              AppLocalizations.of(context)!.aiPlaygroundOutput,
              textAlign: TextAlign.center,
              style: enjoyDisplayStyle(context, size: 20, color: cs.onSurface),
            ),
            SizedBox(height: t.space8),
            Text('—', style: enjoyMonoStyle(context, size: 13, color: t.ink3)),
          ],
        ),
      );
    }

    return SizedBox(
      height: _consoleViewportHeight,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[entries.length - 1 - index];
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : t.space16),
            child: SelectableText(
              entry.text,
              style: enjoyMonoStyle(
                context,
                size: 12.5,
                color: entry.isError ? cs.error : cs.onSurface,
              ),
            ),
          );
        },
      ),
    );
  }
}
