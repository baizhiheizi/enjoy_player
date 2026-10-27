import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';

/// Full script for follow-along listening. Short text sizes naturally; long
/// text scrolls inside a capped viewport so the preview player stays nearby.
class AudioStageScriptBlock extends StatefulWidget {
  const AudioStageScriptBlock({
    super.key,
    required this.sourceLang,
    required this.targetLang,
    required this.text,
    required this.theme,
  });

  /// Soft cap so very long scripts don't push actions off-screen.
  static const double maxScriptHeight = 240;
  static const double accentBarWidth = 3;

  final String sourceLang;
  final String targetLang;
  final String text;
  final ThemeData theme;

  @override
  State<AudioStageScriptBlock> createState() => _AudioStageScriptBlockState();
}

class _AudioStageScriptBlockState extends State<AudioStageScriptBlock> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final theme = widget.theme;
    final scheme = theme.colorScheme;
    final scriptStyle = theme.textTheme.bodyLarge?.copyWith(
      color: scheme.onSurface,
      height: 1.55,
    );

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: t.fill,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(t.radiusLg),
          side: BorderSide(color: t.line),
        ),
      ),
      child: ClipRSuperellipse(
        borderRadius: BorderRadius.circular(t.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: ColoredBox(
                color: t.brandInk,
                child: const SizedBox(
                  width: AudioStageScriptBlock.accentBarWidth,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                t.space16 + AudioStageScriptBlock.accentBarWidth,
                t.space12,
                t.space16,
                t.space12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.sourceLang}  →  ${widget.targetLang}',
                    style: enjoyMonoStyle(
                      context,
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: t.brandInk,
                    ),
                  ),
                  SizedBox(height: t.space8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: AudioStageScriptBlock.maxScriptHeight,
                    ),
                    child: Scrollbar(
                      controller: _scrollController,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        primary: false,
                        child: SelectableText(widget.text, style: scriptStyle),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
