/// Primary and secondary transcript text content with blur and markup styling.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/transcript/transcript_lens_metrics.dart';
import 'package:enjoy_player/data/subtitle/current_transcript_word.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_blur_text.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_line_selection_toolbar.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_markup.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_word_ipa_layer.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class TranscriptTileText extends StatelessWidget {
  const TranscriptTileText({
    required this.line,
    required this.primaryPlain,
    required this.secondaryText,
    required this.lineFg,
    required this.isActive,
    required this.selectable,
    required this.useAligned,
    required this.isRevealed,
    required this.loopActive,
    required this.inLens,
    required this.lensDistance,
    this.loopFontSize,
    this.karaokeRange,
    this.karaokeFill,
    this.karaokeWordIndex,
    this.wavyWordIndexes,
    this.onIpaTap,
    this.onRevealHoldOnly,
    this.onLookupRequested,
    this.onRetranslateSecondary,
    super.key,
  });

  final TranscriptLine line;
  final String primaryPlain;
  final String? secondaryText;
  final Color lineFg;
  final bool isActive;
  final bool selectable;
  final bool useAligned;
  final bool isRevealed;
  final bool loopActive;
  final bool inLens;
  final int lensDistance;
  final double? loopFontSize;
  final WordTextRange? karaokeRange;
  final Color? karaokeFill;
  final int? karaokeWordIndex;
  final Set<int>? wavyWordIndexes;
  final ValueChanged<int>? onIpaTap;
  final VoidCallback? onRevealHoldOnly;
  final ValueChanged<String>? onLookupRequested;
  final VoidCallback? onRetranslateSecondary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tok = EnjoyThemeTokens.of(context);
    final typography = TranscriptTypographyTokens.of(context);
    final metrics = TranscriptLensMetrics.of(context);

    final bodyFontSize = loopActive
        ? loopFontSize!
        : inLens
        ? metrics.contextFontSize(lensDistance)
        : metrics.lineFontSize(active: isActive);
    final emphasized = (loopActive || isActive) && !inLens;
    final baseBody = typography.bodyStyle.copyWith(
      height: loopActive
          ? metrics.loopLineHeight
          : inLens
          ? metrics.contextLineHeight
          : metrics.plainLineHeight,
      fontSize: bodyFontSize,
      fontWeight: emphasized ? FontWeight.w500 : FontWeight.w400,
      letterSpacing: loopActive
          ? bodyFontSize * metrics.loopLetterSpacingEm
          : emphasized
          ? bodyFontSize * metrics.listenLetterSpacingEm
          : null,
    );
    final secondaryTypographyStyle = typography.secondaryStyle.copyWith(
      height: loopActive
          ? metrics.loopSecondaryLineHeight
          : metrics.secondaryLineHeight,
      fontSize: loopActive
          ? metrics.loopSecondaryFontSize
          : metrics.secondaryFontSize(active: isActive),
    );

    Widget primaryWidget;
    if (useAligned && isRevealed) {
      final ipaStyle = transcriptIpaTextStyle(
        baseBody,
        tok.ink3,
        fontSize: loopActive
            ? metrics.loopIpaFontSize
            : metrics.listenIpaFontSize,
      );
      final alignedBody = loopActive
          ? baseBody
          : baseBody.copyWith(height: metrics.alignedLineHeight);
      primaryWidget = TranscriptAlignedWords(
        words: line.timeline!,
        wordStyle: alignedBody,
        wavyWordIndexes: wavyWordIndexes,
        ipaStyle: ipaStyle,
        defaultColor: lineFg,
        emphasize: isActive,
        activeWordIndex: karaokeWordIndex,
        activeUnderlineColor: tok.original,
        runSpacing: loopActive
            ? metrics.loopAlignedRowGap
            : metrics.alignedRowGap,
        onIpaTap: onIpaTap,
        selectableWordBuilder: selectable
            ? (context, text, style) => TranscriptSelectableRichText(
                span: TextSpan(text: text, style: style),
                onTap: onRevealHoldOnly,
                onLookupRequested: onLookupRequested,
              )
            : null,
      );
    } else {
      final primarySpan = transcriptMarkupToTextSpan(
        line.text,
        baseBody,
        defaultColor: lineFg,
        emphasize: false,
        highlightRange: karaokeRange,
        highlightFill: karaokeFill,
        highlightUnderline: true,
      );
      primaryWidget = selectable
          ? TranscriptSelectableRichText(
              span: primarySpan,
              onTap: onRevealHoldOnly,
              onLookupRequested: onLookupRequested,
            )
          : Text.rich(primarySpan);
    }

    final blurredPrimary = TranscriptBlurText(
      revealed: isRevealed,
      shapeWords: primaryPlain,
      shapeFontSize: baseBody.fontSize,
      onShapesTap: selectable ? onRevealHoldOnly : null,
      onShapesLongPress: selectable ? onRevealHoldOnly : null,
      child: primaryWidget,
    );

    Widget? secondaryWidget;
    if (secondaryText != null) {
      final secondarySpan = transcriptMarkupToTextSpan(
        secondaryText!,
        secondaryTypographyStyle,
        defaultColor: scheme.onSurfaceVariant,
        emphasize: false,
      );
      final retranslate = onRetranslateSecondary;
      final retranslateLabel =
          AppLocalizations.of(context)?.subtitlesAutoTranslateRetranslateLine ??
          'Re-translate this line';
      final span = retranslate == null
          ? secondarySpan
          : TextSpan(
              children: [
                secondarySpan,
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Semantics(
                    label: retranslateLabel,
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: retranslate,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6, right: 2),
                        child: Icon(
                          EnjoyIcons.refresh,
                          size: 15,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
      secondaryWidget = selectable
          ? TranscriptSelectableRichText(
              span: span,
              onTap: onRevealHoldOnly,
              onLookupRequested: onLookupRequested,
            )
          : Text.rich(span);
    }

    final blurredSecondary = secondaryWidget == null
        ? null
        : TranscriptBlurText(
            revealed: isRevealed,
            shapeWords: secondaryText,
            shapeFontSize: secondaryTypographyStyle.fontSize,
            onShapesLongPress: selectable ? onRevealHoldOnly : null,
            child: secondaryWidget,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        blurredPrimary,
        if (blurredSecondary != null) ...[
          SizedBox(
            height: loopActive
                ? metrics.loopSecondaryTopGap
                : metrics.secondaryTopGap,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: blurredSecondary)],
          ),
        ],
      ],
    );
  }
}
