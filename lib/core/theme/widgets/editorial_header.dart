/// Editorial page header — large title, optional supporting line, trailing
/// action — mirrors Apple Music / Apple Podcasts heading style.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../enjoy_tokens.dart';

class EditorialHeader extends StatelessWidget {
  const EditorialHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.titleAccessory,
    this.trailing,
    this.padding,
    this.compact = false,
  });

  final String title;
  final String? subtitle;

  /// Inline chip or control beside the title (same row).
  final Widget? titleAccessory;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  /// Tighter vertical rhythm for nested / secondary headers.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = math.max(
          t.space24,
          (constraints.maxWidth - t.contentMaxWidth) / 2,
        );
        final top = compact ? t.space16 : t.space24;
        final bottom = compact ? t.space12 : t.space16;

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
              constraints: BoxConstraints(maxWidth: t.contentMaxWidth),
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
