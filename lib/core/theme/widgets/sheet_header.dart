/// Sheet title block: drag handle + padded title (+ optional subtitle).
library;

import 'package:material_ui/material_ui.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/sheet_drag_handle.dart';

/// Typography and inset variant for a [SheetHeader].
enum SheetHeaderStyle {
  /// Compact title — `titleMedium` at weight 600.
  medium,

  /// Full title — `titleLarge`.
  large,
}

/// Title block for a modal bottom sheet.
///
/// Owns the drag handle and the padded title so every sheet shares one title
/// rhythm. [subtitle] adds a muted line under the title.
class SheetHeader extends StatelessWidget {
  const SheetHeader({
    super.key,
    required this.title,
    this.style = SheetHeaderStyle.medium,
    this.subtitle,
  });

  final String title;
  final SheetHeaderStyle style;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final theme = Theme.of(context);
    final horizontal = switch (style) {
      SheetHeaderStyle.medium => t.space20,
      SheetHeaderStyle.large => t.space24,
    };
    final titleTop = switch (style) {
      SheetHeaderStyle.medium => t.space4,
      SheetHeaderStyle.large => 0.0,
    };
    final blockBottom = switch (style) {
      SheetHeaderStyle.medium => t.space12,
      SheetHeaderStyle.large => t.space8,
    };
    final titleBottom = subtitle == null ? blockBottom : t.space4;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PaddedSheetDragHandle(),
        Padding(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            titleTop,
            horizontal,
            titleBottom,
          ),
          child: Text(title, style: _titleStyle(theme)),
        ),
        if (subtitle != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              0,
              horizontal,
              blockBottom,
            ),
            child: Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  TextStyle? _titleStyle(ThemeData theme) => switch (style) {
    SheetHeaderStyle.medium => theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ),
    SheetHeaderStyle.large => theme.textTheme.titleLarge,
  };
}
