/// Editorial page header — large title, optional supporting line, trailing
/// action — mirrors Apple Music / Apple Podcasts heading style.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

/// How [EditorialHeader] applies horizontal insets on wide panes.
enum EditorialHeaderWidthMode {
  /// Match browse bodies: [pageGutterOf] only (full-bleed title row).
  gutter,

  /// Center within [columnMaxWidth] (hub / form), with at least page gutter.
  column,
}

class EditorialHeader extends StatelessWidget {
  const EditorialHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.titleAccessory,
    this.trailing,
    this.padding,
    this.compact = false,
    this.widthMode = EditorialHeaderWidthMode.gutter,
    this.columnMaxWidth,
  });

  final String title;
  final String? subtitle;

  /// Inline chip or control beside the title (same row).
  final Widget? titleAccessory;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  /// Tighter vertical rhythm for nested / secondary headers.
  final bool compact;

  /// Browse screens use [gutter]; hub screens use [column].
  final EditorialHeaderWidthMode widthMode;

  /// Cap when [widthMode] is [EditorialHeaderWidthMode.column].
  /// Defaults to [EnjoyThemeTokens.hubMaxWidth] when null.
  final double? columnMaxWidth;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final paneWidth = constraints.maxWidth;
        final gutter = pageGutterOf(context, paneWidth);
        final top = compact ? t.space16 : t.space24;
        final bottom = compact ? t.space12 : t.space16;

        final double horizontal;
        final double? titleMaxWidth;
        switch (widthMode) {
          case EditorialHeaderWidthMode.gutter:
            horizontal = gutter;
            titleMaxWidth = null;
          case EditorialHeaderWidthMode.column:
            final cap = columnMaxWidth ?? t.hubMaxWidth;
            horizontal = (paneWidth - cap) / 2 > gutter
                ? (paneWidth - cap) / 2
                : gutter;
            titleMaxWidth = cap;
        }

        final titleStyle = compact
            ? tt.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: t.heroTitleLetterSpacing * 0.75,
              )
            : tt.displaySmall;

        return Padding(
          padding:
              padding ??
              EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: titleMaxWidth ?? double.infinity,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (subtitle != null) ...[
                          Text(
                            subtitle!.toUpperCase(),
                            style: tt.labelSmall?.copyWith(
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                          ),
                          SizedBox(height: t.space4),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: titleStyle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (titleAccessory != null) ...[
                              SizedBox(width: t.space8),
                              titleAccessory!,
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    SizedBox(width: t.space16),
                    Padding(
                      padding: EdgeInsets.only(bottom: compact ? 0 : 2),
                      child: trailing!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
