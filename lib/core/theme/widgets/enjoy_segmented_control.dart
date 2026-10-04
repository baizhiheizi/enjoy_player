/// Duet segmented controls.
///
/// [EnjoySegmentedControl] is the primary control: a recessed track with a
/// lifted thumb that glides between equal-width segments (the iOS / macOS
/// idiom, rendered identically on every platform).
/// [enjoySegmentedButtonStyle] keeps legacy [SegmentedButton] call sites on
/// the same visual language.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

/// Shared styling for legacy [SegmentedButton] call sites.
ButtonStyle enjoySegmentedButtonStyle(BuildContext context) {
  final t = EnjoyThemeTokens.of(context);
  final tt = Theme.of(context).textTheme;

  return SegmentedButton.styleFrom(
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    backgroundColor: t.sunk,
    foregroundColor: t.ink2,
    selectedForegroundColor: t.ink,
    selectedBackgroundColor: t.raised,
    side: BorderSide(color: t.line),
    splashFactory: NoSplash.splashFactory,
    shape: RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(t.radiusControl),
    ),
    textStyle: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600),
  );
}

/// Recessed track color shared by segmented controls and segmented [TabBar]s.
Color enjoySegmentTrackColor(BuildContext context) =>
    EnjoyThemeTokens.of(context).sunk;

/// Lifted thumb decoration shared by segmented controls and segmented
/// [TabBar] indicators.
ShapeDecoration enjoySegmentThumbDecoration(
  BuildContext context, {
  double radius = 9,
}) {
  final t = EnjoyThemeTokens.of(context);
  return ShapeDecoration(
    color: t.raised,
    shape: RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(radius),
    ),
    shadows: t.shadowCard,
  );
}

/// One option of an [EnjoySegmentedControl].
class EnjoySegment<T> {
  const EnjoySegment({
    required this.value,
    required this.label,
    this.icon,
    this.tooltip,
  });

  final T value;
  final String label;
  final IconData? icon;
  final String? tooltip;
}

class EnjoySegmentedControl<T> extends StatelessWidget {
  const EnjoySegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.expand = false,
    this.compact = false,
  });

  final List<EnjoySegment<T>> segments;
  final T value;
  final ValueChanged<T>? onChanged;

  /// Fill the parent's width (otherwise sized to the widest segment × n).
  final bool expand;

  /// 30px track instead of 36px.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final n = segments.length;
    final index = segments.indexWhere((s) => s.value == value).clamp(0, n - 1);
    final height = compact ? 30.0 : t.segmentHeight;
    final radius = compact ? t.radiusSm : t.radiusControl;
    final instant = MediaQuery.disableAnimationsOf(context);

    final thumb = DecoratedBox(
      decoration: enjoySegmentThumbDecoration(
        context,
        radius: compact ? radius - 2 : t.radiusSegmentThumb,
      ),
    );

    final row = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        for (var i = 0; i < n; i++)
          Expanded(
            child: _SegmentButton(
              segment: segments[i],
              selected: i == index,
              compact: compact,
              radius: radius - 2,
              textStyle: tt.labelMedium?.copyWith(
                fontSize: compact ? 12.5 : 13.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.05,
                color: i == index ? t.ink : t.ink2,
              ),
              onTap: onChanged == null || i == index
                  ? null
                  : () => onChanged!(segments[i].value),
            ),
          ),
      ],
    );

    final track = Container(
      height: height,
      padding: const EdgeInsets.all(2),
      decoration: ShapeDecoration(
        color: enjoySegmentTrackColor(context),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: instant ? Duration.zero : t.motionMedium,
              curve: EnjoyThemeTokens.emphasized,
              alignment: Alignment(n == 1 ? 0 : -1 + 2 * index / (n - 1), 0),
              child: FractionallySizedBox(
                widthFactor: 1 / n,
                heightFactor: 1,
                child: thumb,
              ),
            ),
          ),
          row,
        ],
      ),
    );

    return expand ? track : IntrinsicWidth(child: track);
  }
}

class _SegmentButton<T> extends StatelessWidget {
  const _SegmentButton({
    required this.segment,
    required this.selected,
    required this.compact,
    required this.radius,
    required this.textStyle,
    required this.onTap,
  });

  final EnjoySegment<T> segment;
  final bool selected;
  final bool compact;
  final double radius;
  final TextStyle? textStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    Widget content = Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (segment.icon != null) ...[
            Icon(
              segment.icon,
              size: compact ? 14 : 15,
              color: selected ? t.ink : textStyle?.color,
            ),
            if (segment.label.isNotEmpty) const SizedBox(width: 6),
          ],
          if (segment.label.isNotEmpty)
            Flexible(
              child: Text(
                segment.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
        ],
      ),
    );
    if (segment.tooltip != null) {
      content = Tooltip(message: segment.tooltip, child: content);
    }
    return EnjoyPressable(
      onTap: onTap,
      selected: selected,
      semanticsLabel: segment.label.isEmpty ? segment.tooltip : null,
      borderRadius: BorderRadius.circular(radius),
      showHoverWash: !selected,
      pressedScale: 0.97,
      mouseCursor: selected ? SystemMouseCursors.basic : null,
      child: SizedBox.expand(child: Center(child: content)),
    );
  }
}
