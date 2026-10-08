/// Editorial page header — large Literata title, optional overline,
/// trailing actions. The signature voice of Duet page chrome (ADR-0093).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

/// How [EditorialHeader] applies horizontal insets on wide panes.
enum EditorialHeaderWidthMode {
  /// [pageGutterOf] only (full-bleed title row).
  gutter,

  /// The browse column: gutter plus half the width beyond
  /// [EnjoyThemeTokens.pageMaxBrowse] (matches [EnjoyPageMetrics]).
  browse,

  /// Center within [columnMaxWidth] (hub / form), with at least page gutter.
  column,
}

class EditorialHeader extends StatelessWidget {
  const EditorialHeader({
    super.key,
    required this.title,
    this.overline,
    this.subtitle,
    this.titleAccessory,
    this.trailing,
    this.padding,
    this.compact = false,
    this.widthMode = EditorialHeaderWidthMode.gutter,
    this.columnMaxWidth,
  });

  final String title;

  /// Small eyebrow above the title (rendered letter-spaced, uppercase).
  final String? overline;

  /// Muted descriptive line under the title.
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
    final tt = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final paneWidth = constraints.maxWidth;
        final narrow = paneWidth < t.breakpointCompact;
        final gutter = pageGutterOf(context, paneWidth);
        final top = compact ? t.space16 : (narrow ? t.space20 : 44.0);
        final bottom = compact ? t.space12 : t.space20;

        final double horizontal;
        final double? titleMaxWidth;
        switch (widthMode) {
          case EditorialHeaderWidthMode.gutter:
            horizontal = gutter;
            titleMaxWidth = null;
          case EditorialHeaderWidthMode.browse:
            horizontal = EnjoyPageMetrics.of(
              context,
              kind: EnjoyPageKind.browse,
              paneWidth: paneWidth,
            ).horizontalInset;
            titleMaxWidth = null;
          case EditorialHeaderWidthMode.column:
            final cap = columnMaxWidth ?? t.hubMaxWidth;
            horizontal = (paneWidth - cap) / 2 > gutter
                ? (paneWidth - cap) / 2
                : gutter;
            titleMaxWidth = cap;
        }

        final titleStyle = compact
            ? tt.headlineMedium
            : tt.displaySmall?.copyWith(
                fontSize: narrow ? 32 : 42,
                letterSpacing: narrow ? -0.64 : -0.84,
              );

        final stackTrailing =
            narrow && titleAccessory != null && trailing != null;

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
                        if (overline != null) ...[
                          EnjoyOverline(overline!),
                          SizedBox(height: t.space12),
                        ],
                        Wrap(
                          spacing: t.space12,
                          runSpacing: t.space8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              title,
                              style: titleStyle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            ?titleAccessory,
                          ],
                        ),
                        if (stackTrailing) ...[
                          SizedBox(height: t.space16),
                          trailing!,
                        ],
                        if (subtitle != null) ...[
                          SizedBox(height: t.space4),
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodyMedium?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null && !stackTrailing) ...[
                    SizedBox(width: t.space16),
                    trailing!,
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

/// Letter-spaced uppercase overline (eyebrow) label.
class EnjoyOverline extends StatelessWidget {
  const EnjoyOverline(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        letterSpacing: 0.88,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color ?? t.ink3,
      ),
    );
  }
}

/// In-page section heading: title, optional count / caption, trailing action.
class EnjoySectionHeader extends StatelessWidget {
  const EnjoySectionHeader({
    super.key,
    required this.title,
    this.caption,
    this.trailing,
    this.padding = EdgeInsets.zero,
  });

  final String title;

  /// Muted inline caption after the title (e.g. an item count).
  final String? caption;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.displaySmall?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.24,
                      height: 1.2,
                    ),
                  ),
                ),
                if (caption != null) ...[
                  SizedBox(width: t.space8),
                  Text(
                    caption!,
                    style: tt.bodySmall?.copyWith(
                      color: t.ink3,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
