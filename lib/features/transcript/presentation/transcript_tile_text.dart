/// Primary and secondary transcript text content with blur and markup styling.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/transcript/transcript_lens_metrics.dart';
import 'package:enjoy_player/data/subtitle/current_transcript_word.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/application/transcript_playback_highlight_provider.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_blur_text.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_line_selection_toolbar.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_markup.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_word_ipa_layer.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class TranscriptTileText extends StatelessWidget {
  const TranscriptTileText({
    required this.line,
    required this.mediaId,
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
    this.wavyWordIndexes,
    this.onIpaTap,
    this.onRevealHoldOnly,
    this.onLookupRequested,
    this.onRetranslateSecondary,
    super.key,
  });

  final TranscriptLine line;
  final String mediaId;
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
      final runSpacing = loopActive
          ? metrics.loopAlignedRowGap
          : metrics.alignedRowGap;
      primaryWidget = isActive
          ? _ActiveAlignedWordsLeaf(
              mediaId: mediaId,
              words: line.timeline!,
              wordStyle: alignedBody,
              ipaStyle: ipaStyle,
              defaultColor: lineFg,
              activeUnderlineColor: tok.original,
              wavyWordIndexes: wavyWordIndexes,
              runSpacing: runSpacing,
              onIpaTap: onIpaTap,
              selectable: selectable,
              onTap: onRevealHoldOnly,
              onLookupRequested: onLookupRequested,
            )
          : TranscriptAlignedWords(
              words: line.timeline!,
              wordStyle: alignedBody,
              wavyWordIndexes: wavyWordIndexes,
              ipaStyle: ipaStyle,
              defaultColor: lineFg,
              emphasize: isActive,
              activeUnderlineColor: tok.original,
              runSpacing: runSpacing,
              onIpaTap: onIpaTap,
              selectable: selectable,
              onTap: onRevealHoldOnly,
              onLookupRequested: onLookupRequested,
            );
    } else if (isActive) {
      primaryWidget = _ActivePlainKaraokeTextLeaf(
        mediaId: mediaId,
        line: line,
        primaryPlain: primaryPlain,
        baseBody: baseBody,
        lineFg: lineFg,
        karaokeFillColor: tok.original,
        selectable: selectable,
        onRevealHoldOnly: onRevealHoldOnly,
        onLookupRequested: onLookupRequested,
      );
    } else {
      final primarySpan = transcriptMarkupToTextSpan(
        line.text,
        baseBody,
        defaultColor: lineFg,
        emphasize: false,
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
            onShapesTap: selectable ? onRevealHoldOnly : null,
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

class _ActivePlainKaraokeTextLeaf extends ConsumerWidget {
  const _ActivePlainKaraokeTextLeaf({
    required this.mediaId,
    required this.line,
    required this.primaryPlain,
    required this.baseBody,
    required this.lineFg,
    required this.karaokeFillColor,
    required this.selectable,
    required this.onRevealHoldOnly,
    required this.onLookupRequested,
  });

  final String mediaId;
  final TranscriptLine line;
  final String primaryPlain;
  final TextStyle baseBody;
  final Color lineFg;
  final Color karaokeFillColor;
  final bool selectable;
  final VoidCallback? onRevealHoldOnly;
  final ValueChanged<String>? onLookupRequested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordIndex = ref.watch(
      transcriptPlaybackHighlightProvider(mediaId).select((h) => h.wordIndex),
    );
    final karaokeRange = wordIndex == null
        ? null
        : wordHighlightRange(primaryPlain, line.timeline, wordIndex);
    final primarySpan = transcriptMarkupToTextSpan(
      line.text,
      baseBody,
      defaultColor: lineFg,
      emphasize: false,
      highlightRange: karaokeRange,
      highlightFill: karaokeRange == null ? null : karaokeFillColor,
      highlightUnderline: true,
    );
    return selectable
        ? TranscriptSelectableRichText(
            span: primarySpan,
            onTap: onRevealHoldOnly,
            onLookupRequested: onLookupRequested,
          )
        : Text.rich(primarySpan);
  }
}

class _ActiveAlignedWordsLeaf extends ConsumerStatefulWidget {
  const _ActiveAlignedWordsLeaf({
    required this.mediaId,
    required this.words,
    required this.wordStyle,
    required this.ipaStyle,
    required this.defaultColor,
    required this.activeUnderlineColor,
    required this.wavyWordIndexes,
    required this.runSpacing,
    required this.onIpaTap,
    required this.selectable,
    required this.onTap,
    required this.onLookupRequested,
  });

  final String mediaId;
  final List<TranscriptWord> words;
  final TextStyle wordStyle;
  final TextStyle ipaStyle;
  final Color defaultColor;
  final Color activeUnderlineColor;
  final Set<int>? wavyWordIndexes;
  final double runSpacing;
  final ValueChanged<int>? onIpaTap;
  final bool selectable;
  final VoidCallback? onTap;
  final ValueChanged<String>? onLookupRequested;

  @override
  ConsumerState<_ActiveAlignedWordsLeaf> createState() =>
      _ActiveAlignedWordsLeafState();
}

class _ActiveAlignedWordsLeafState
    extends ConsumerState<_ActiveAlignedWordsLeaf> {
  late final ValueNotifier<int?> _activeWord = ValueNotifier<int?>(
    ref.read(transcriptPlaybackHighlightProvider(widget.mediaId)).wordIndex,
  );

  @override
  void didUpdateWidget(_ActiveAlignedWordsLeaf oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaId != widget.mediaId) {
      _activeWord.value = ref
          .read(transcriptPlaybackHighlightProvider(widget.mediaId))
          .wordIndex;
    }
  }

  @override
  void dispose() {
    _activeWord.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(
      transcriptPlaybackHighlightProvider(
        widget.mediaId,
      ).select((h) => h.wordIndex),
      (_, next) => _activeWord.value = next,
    );
    return TranscriptAlignedWords(
      words: widget.words,
      wordStyle: widget.wordStyle,
      ipaStyle: widget.ipaStyle,
      defaultColor: widget.defaultColor,
      emphasize: true,
      activeWordIndexListenable: _activeWord,
      activeUnderlineColor: widget.activeUnderlineColor,
      wavyWordIndexes: widget.wavyWordIndexes,
      runSpacing: widget.runSpacing,
      onIpaTap: widget.onIpaTap,
      selectable: widget.selectable,
      onTap: widget.onTap,
      onLookupRequested: widget.onLookupRequested,
    );
  }
}
