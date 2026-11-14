import 'dart:async';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/dictation/domain/dictation_band_words.dart';
import 'package:enjoy_player/features/dictation/domain/dictation_models.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_blur.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class DictationBand extends StatefulWidget {
  const DictationBand({
    super.key,
    required this.lines,
    required this.fallbackReferenceText,
    required this.regionStartMs,
    required this.regionDurationMs,
    required this.currentPlaybackMs,
    required this.diffResult,
    this.textStyle,
  });

  final List<TranscriptLine> lines;
  final String fallbackReferenceText;
  final int regionStartMs;
  final int regionDurationMs;
  final int currentPlaybackMs;
  final DictationDiffResult? diffResult;
  final TextStyle? textStyle;

  @override
  State<DictationBand> createState() => _DictationBandState();
}

class _DictationBandState extends State<DictationBand> {
  Timer? _peekTimer;

  @override
  void dispose() {
    _peekTimer?.cancel();
    super.dispose();
  }

  void _startPeek() {
    Haptics.impactMedium(context);
    _peekTimer?.cancel();
    setState(() {
      _peekTimer = Timer(const Duration(seconds: kTapRevealHoldSeconds), () {
        if (!mounted) return;
        setState(() => _peekTimer = null);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final diff = widget.diffResult;

    if (diff == null) {
      final bandWords = buildDictationBandWords(
        lines: widget.lines,
        fallbackReferenceText: widget.fallbackReferenceText,
        regionStartMs: widget.regionStartMs,
        regionDurationMs: widget.regionDurationMs,
      );
      final activeIndex = findActiveDictationWordIndex(
        words: bandWords,
        currentPlaybackMs: widget.currentPlaybackMs,
      );

      if (_peekTimer != null) {
        final peekStyle =
            widget.textStyle ??
            Theme.of(context).textTheme.titleMedium ??
            const TextStyle(fontSize: 18);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: _startPeek,
            child: Text.rich(
              TextSpan(
                children: [
                  for (var i = 0; i < bandWords.length; i++) ...[
                    if (i > 0) const TextSpan(text: ' '),
                    TextSpan(text: bandWords[i].text, style: peekStyle),
                  ],
                ],
              ),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: _startPeek,
          child: Wrap(
            spacing: 6,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < bandWords.length; i++)
                _buildMaskedWordBlock(
                  word: bandWords[i],
                  isActive: i == activeIndex,
                  isPast: activeIndex != null && i < activeIndex,
                  t: t,
                ),
            ],
          ),
        ),
      );
    }

    final effectiveStyle =
        widget.textStyle ??
        Theme.of(context).textTheme.titleMedium ??
        const TextStyle(fontSize: 18);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text.rich(
            TextSpan(
              children: [
                for (var i = 0; i < diff.tokens.length; i++) ...[
                  if (i > 0) const TextSpan(text: ' '),
                  _buildDiffSpan(diff.tokens[i], effectiveStyle, t),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildLegend(t, l10n),
      ],
    );
  }

  Widget _buildMaskedWordBlock({
    required DictationBandWord word,
    required bool isActive,
    required bool isPast,
    required EnjoyThemeTokens t,
  }) {
    Color bg;
    Border? border;

    if (isActive) {
      bg = t.originalSoft;
      border = Border.all(color: t.original, width: 1.5);
    } else if (isPast) {
      bg = t.originalSoft.withValues(alpha: 0.5);
    } else {
      bg = t.sunk;
    }

    return Container(
      width: word.blockWidth,
      height: 14,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: border,
      ),
    );
  }

  InlineSpan _buildDiffSpan(
    DictationDiffToken token,
    TextStyle baseStyle,
    EnjoyThemeTokens t,
  ) {
    switch (token.op) {
      case DictationWordDiffOp.correct:
        return TextSpan(
          text: token.word,
          style: baseStyle.copyWith(
            color: t.originalInk,
            fontWeight: FontWeight.w600,
          ),
        );
      case DictationWordDiffOp.missed:
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: t.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '[${token.word}]',
              style: baseStyle.copyWith(
                color: t.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      case DictationWordDiffOp.extra:
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: t.youSoft,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              token.word,
              style: baseStyle.copyWith(
                color: t.youInk,
                decoration: TextDecoration.lineThrough,
                decorationColor: t.youInk,
              ),
            ),
          ),
        );
    }
  }

  Widget _buildLegend(EnjoyThemeTokens t, AppLocalizations? l10n) {
    return Row(
      children: [
        _legendItem(
          color: t.originalInk,
          label: l10n?.playerDictationLegendCorrect ?? 'Correct',
        ),
        const SizedBox(width: 16),
        _legendItem(
          color: t.danger,
          label: l10n?.playerDictationLegendMissed ?? 'Missed',
          bracket: true,
        ),
        const SizedBox(width: 16),
        _legendItem(
          color: t.youInk,
          label: l10n?.playerDictationLegendExtra ?? 'Extra',
          lineThrough: true,
        ),
      ],
    );
  }

  Widget _legendItem({
    required Color color,
    required String label,
    bool bracket = false,
    bool lineThrough = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          bracket ? '[$label]' : label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
            decoration: lineThrough ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }
}
