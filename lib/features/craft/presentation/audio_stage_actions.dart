import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';

class AudioStageActions extends StatelessWidget {
  const AudioStageActions({
    super.key,
    required this.practiceLabel,
    required this.sayAnotherLabel,
    required this.onPractice,
    required this.onSayAnother,
  });

  final String practiceLabel;
  final String sayAnotherLabel;
  final VoidCallback onPractice;
  final VoidCallback onSayAnother;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnjoyButton.brand(
          onPressed: onPractice,
          icon: EnjoyIcons.libraryAdded,
          expand: true,
          child: Text(practiceLabel),
        ),
        SizedBox(height: t.space8),
        EnjoyButton.secondary(
          onPressed: onSayAnother,
          icon: EnjoyIcons.mic,
          expand: true,
          child: Text(sayAnotherLabel),
        ),
      ],
    );
  }
}

class AudioStageUnsavedPreviewHint extends StatelessWidget {
  const AudioStageUnsavedPreviewHint({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: t.fill,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(t.radiusMd),
          side: BorderSide(color: t.line),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: t.space12,
          vertical: t.space8,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(EnjoyIcons.info, size: 18, color: t.brandInk),
            SizedBox(width: t.space8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
