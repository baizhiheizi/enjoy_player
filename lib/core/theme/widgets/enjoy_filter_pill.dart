/// Paper filter pill: the shared chrome for the toolbar filter controls.
///
/// The credits usage filters and the vocabulary board's status / language
/// menus were hand-rolled copies of the same pill — a paper plate with a
/// line border at radius 11, a label, and a chevron. Duplicated chrome
/// drifts, so both render this primitive (ADR-0018).
///
/// The Duet boards draw the same pill twice: `Credits.dc.html`'s `.e-field`
/// (38px tall) and `Vocabulary.dc.html`'s `.e-chip` (36px tall). Both are
/// 13.5px labels at radius 11 on paper with a line border, so the height is
/// the only difference and [EnjoyFilterPill.height] carries it.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';

/// The Duet paper-plate radius of a filter pill.
const double kEnjoyFilterPillRadius = 11;

/// The Duet paper-plate height of a filter pill (`Credits.dc.html`'s
/// `.e-field`; the vocabulary board's `.e-chip` is 36px).
const double kEnjoyFilterPillHeight = 38;

/// The Duet filter-pill label size, shared by both boards.
const double kEnjoyFilterPillLabelSize = 13.5;

/// A tappable paper pill: a label and an optional mono value.
class EnjoyFilterPill extends StatelessWidget {
  const EnjoyFilterPill({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
    this.height = kEnjoyFilterPillHeight,
  });

  /// The field name ("Start date").
  final String label;

  /// The picked value, shown in mono after the label.
  final String? value;

  final VoidCallback onTap;

  final double height;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    return EnjoyPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kEnjoyFilterPillRadius),
      child: _PillChrome(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: tt.labelMedium?.copyWith(
                fontSize: kEnjoyFilterPillLabelSize,
                color: t.ink3,
              ),
            ),
            if (value != null && value!.isNotEmpty) ...[
              const SizedBox(width: 10),
              Text(
                value!,
                style: enjoyMonoStyle(context, size: 13, color: t.ink),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A paper pill that opens a menu of filter choices.
class EnjoyFilterMenu<T> extends StatelessWidget {
  const EnjoyFilterMenu({
    super.key,
    required this.label,
    required this.value,
    required this.entries,
    required this.onChanged,
    this.formatLabel,
    this.height = kEnjoyFilterPillHeight,
  });

  /// The filter name ("Service", "Status").
  final String label;

  /// The current selection; matches one of [entries].
  final T value;

  /// The selectable choices, in display order.
  final List<(T, String)> entries;

  final ValueChanged<T> onChanged;

  /// Formats the pill's text. Defaults to `label` and the current entry
  /// separated by two spaces.
  final String Function(String label, String current)? formatLabel;

  final double height;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final current = entries
        .firstWhere((e) => e.$1 == value, orElse: () => entries.first)
        .$2;
    final text = formatLabel?.call(label, current) ?? '$label  $current';
    return MenuAnchor(
      menuChildren: [
        for (final entry in entries)
          MenuItemButton(
            onPressed: () => onChanged(entry.$1),
            child: Text(entry.$2),
          ),
      ],
      builder: (context, controller, _) => EnjoyPressable(
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        borderRadius: BorderRadius.circular(kEnjoyFilterPillRadius),
        child: _PillChrome(
          height: height,
          padding: const EdgeInsets.only(left: 12, right: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: tt.labelMedium?.copyWith(
                  fontSize: kEnjoyFilterPillLabelSize,
                  fontWeight: FontWeight.w600,
                  color: t.ink2,
                ),
              ),
              const SizedBox(width: 6),
              Icon(EnjoyIcons.chevronDown, size: 14, color: t.ink3),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillChrome extends StatelessWidget {
  const _PillChrome({
    required this.height,
    required this.padding,
    required this.child,
  });

  final double height;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Container(
      height: height,
      padding: padding,
      decoration: ShapeDecoration(
        color: t.paper,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(kEnjoyFilterPillRadius),
          side: BorderSide(color: t.line),
        ),
      ),
      child: child,
    );
  }
}
