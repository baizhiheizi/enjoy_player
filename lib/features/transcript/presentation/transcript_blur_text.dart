/// Hidden-text renderer for hide-text practice (Duet, ADR-0093).
///
/// When practice hides a line, the cue body renders as rounded `shape`
/// bars sized from the hidden words' text boxes instead of a Gaussian
/// blur (ADR-0093 decision 3 — cheaper to paint, same reveal rules).
/// When revealed, the real child renders unchanged. Semantics, lookup,
/// and selection on revealed lines are untouched.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

/// Measured word-bar widths keyed by (text, fontSize, weight); entries are
/// computed once per line layout and reused across hover rebuilds.
@visibleForTesting
final Map<String, List<double>> shapeWidthCache = <String, List<double>>{};

@visibleForTesting
List<double> shapeWidthsFor(String text, double fontSize, FontWeight weight) {
  final key = '$text|$fontSize|$weight';
  final cached = shapeWidthCache[key];
  if (cached != null) return cached;
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontSize: fontSize, fontWeight: weight),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final widths = <double>[];
  for (final word in text.split(RegExp(r'\s+'))) {
    if (word.isEmpty) continue;
    tp.text = TextSpan(
      text: word,
      style: TextStyle(fontSize: fontSize, fontWeight: weight),
    );
    tp.layout();
    widths.add(tp.width.clamp(fontSize * 0.5, fontSize * 6.0));
  }
  if (shapeWidthCache.length > 512) shapeWidthCache.clear();
  shapeWidthCache[key] = widths;
  return widths;
}

@visibleForTesting
class TranscriptBlurText extends StatelessWidget {
  const TranscriptBlurText({
    super.key,
    required this.revealed,
    required this.child,
    this.shapeWords,
    this.shapeFontSize,
    this.shapeColor,
    this.onShapesTap,
  });

  /// When `true` the child is rendered unchanged.
  final bool revealed;

  /// The text widget(s) to wrap. Layout-affecting wrappers MUST NOT be
  /// inserted above this point — see [data-model.md] § 2.
  final Widget child;

  /// The hidden line's words. When null (or when revealed) the shapes are
  /// skipped and the child renders (blurring is gone in Duet — the only
  /// hidden presentation is the shapes).
  final String? shapeWords;

  /// Font size the bars emulate.
  final double? shapeFontSize;

  final Color? shapeColor;

  /// Tap on the hidden shapes — same reveal rules as the blurred text it
  /// replaces (hold-to-peek on selectable cues).
  final VoidCallback? onShapesTap;

  @override
  Widget build(BuildContext context) {
    if (revealed) return child;
    final words = shapeWords;
    final fontSize = shapeFontSize;
    if (words == null || words.trim().isEmpty || fontSize == null) {
      return child;
    }
    final t = EnjoyThemeTokens.of(context);
    final widths = shapeWidthsFor(words, fontSize, FontWeight.w400);
    final bars = Wrap(
      spacing: fontSize * 0.3,
      runSpacing: 10,
      children: [
        for (final width in widths)
          Container(
            height: fontSize * 0.62,
            width: width,
            decoration: BoxDecoration(
              color: shapeColor ?? t.shape,
              borderRadius: BorderRadius.circular(fontSize * 0.2),
            ),
          ),
      ],
    );
    if (onShapesTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: bars,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onShapesTap,
        child: bars,
      ),
    );
  }
}
