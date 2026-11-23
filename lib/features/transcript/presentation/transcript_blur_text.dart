/// Hidden-text renderer for hide-text practice (Duet, ADR-0093).
///
/// When practice hides a line, the cue body renders as rounded `shape`
/// bars sized from the hidden words' text boxes instead of a Gaussian
/// blur (ADR-0093 decision 3 — cheaper to paint, same reveal rules).
/// When revealed, the real child renders unchanged. Semantics, lookup,
/// and selection on revealed lines are untouched.
library;

import 'package:material_ui/material_ui.dart';

import 'package:enjoy_player/core/cache/lru_store.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/utils/text_normalization.dart';

/// Measured word-bar widths keyed by (text, fontSize, weight); entries are
/// computed once per line layout and reused across hover rebuilds.
@visibleForTesting
final L1Store<String, List<double>> shapeWidthCache =
    L1Store<String, List<double>>(capacity: 512);

@visibleForTesting
List<double> shapeWidthsFor(String text, double fontSize, FontWeight weight) {
  final key = '$text|$fontSize|$weight';
  final cached = shapeWidthCache.peek(key);
  if (cached != null) return cached;
  final style = TextStyle(fontSize: fontSize, fontWeight: weight);
  final tp = TextPainter(textDirection: TextDirection.ltr);
  final widths = <double>[];
  try {
    for (final word in text.split(whitespaceRunRegExp)) {
      if (word.isEmpty) continue;
      tp.text = TextSpan(text: word, style: style);
      tp.layout();
      widths.add(tp.width.clamp(fontSize * 0.5, fontSize * 6.0));
    }
  } finally {
    tp.dispose();
  }
  shapeWidthCache.put(key, widths);
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
    this.onShapesLongPress,
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

  /// Long-press on the hidden shapes — starts the same reveal hold as
  /// [onShapesTap] without any seek (the touch peek gesture).
  final VoidCallback? onShapesLongPress;

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
    if (onShapesTap == null && onShapesLongPress == null) {
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
        onLongPress: onShapesLongPress,
        child: bars,
      ),
    );
  }
}
