/// Section card, run-button label, and picked-file chip for the AI playground.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';

class PlaygroundSection extends StatelessWidget {
  const PlaygroundSection({
    required this.title,
    required this.providerLabel,
    required this.children,
    super.key,
  });

  final String title;
  final String providerLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: t.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EnjoySectionHeader(title: title, caption: providerLabel),
          SizedBox(height: t.space12),
          EnjoyCard(
            padding: EdgeInsets.all(t.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class PlaygroundRunLabel extends StatelessWidget {
  const PlaygroundRunLabel({
    required this.busy,
    required this.label,
    super.key,
  });

  final bool busy;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!busy) return Text(label);
    return LoadingIcon(
      size: 18,
      color: Theme.of(context).colorScheme.onPrimary,
    );
  }
}

class PlaygroundPickedFileChip extends StatelessWidget {
  const PlaygroundPickedFileChip({
    required this.name,
    required this.byteCount,
    super.key,
  });

  final String name;
  final int byteCount;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: t.fill,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(t.radiusSm),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: t.space12,
          vertical: t.space8,
        ),
        child: Row(
          children: [
            Icon(EnjoyIcons.waveform, size: 16, color: cs.onSurfaceVariant),
            SizedBox(width: t.space8),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: enjoyMonoStyle(context, size: 12.5),
              ),
            ),
            SizedBox(width: t.space8),
            Text(
              '$byteCount B',
              style: enjoyMonoStyle(
                context,
                size: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
