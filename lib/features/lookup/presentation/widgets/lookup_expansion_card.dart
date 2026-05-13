/// Expandable tonal card for lookup sheet sections (lazy body until first expand).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class LookupExpansionCard extends StatefulWidget {
  const LookupExpansionCard({
    required this.title,
    required this.initiallyExpanded,
    required this.bodyBuilder,
    this.leading,
    super.key,
  });

  final String title;
  final bool initiallyExpanded;
  final Widget? leading;

  /// Built only after the section is expanded for the first time.
  final Widget Function(BuildContext context) bodyBuilder;

  @override
  State<LookupExpansionCard> createState() => _LookupExpansionCardState();
}

class _LookupExpansionCardState extends State<LookupExpansionCard> {
  late bool _expanded = widget.initiallyExpanded;
  late bool _shouldLoad = widget.initiallyExpanded;

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) _shouldLoad = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radiusMd),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Semantics(
            expanded: _expanded,
            button: true,
            label: widget.title,
            child: InkWell(
              onTap: _toggle,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  t.space12,
                  t.space8,
                  t.space8,
                  t.space8,
                ),
                child: Row(
                  children: [
                    if (widget.leading != null) ...[
                      IconTheme(
                        data: IconThemeData(
                          color: scheme.primary.withValues(alpha: 0.85),
                          size: 18,
                        ),
                        child: widget.leading!,
                      ),
                      SizedBox(width: t.space8),
                    ],
                    Expanded(
                      child: Text(
                        widget.title,
                        style: tt.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: t.motionFast,
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: scheme.onSurfaceVariant,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Body ──────────────────────────────────────────────────────
          AnimatedSize(
            duration: t.motionStandard,
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Divider(
                        height: 1,
                        color: scheme.outlineVariant.withValues(alpha: 0.18),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          t.space12,
                          t.space12,
                          t.space12,
                          t.space12,
                        ),
                        child: AnimatedSwitcher(
                          duration: t.motionFast,
                          layoutBuilder: (current, previous) => Stack(
                            alignment: AlignmentDirectional.topStart,
                            children: [...previous, ?current],
                          ),
                          child: _shouldLoad
                              ? KeyedSubtree(
                                  key: const ValueKey<String>('body'),
                                  child: widget.bodyBuilder(context),
                                )
                              : KeyedSubtree(
                                  key: const ValueKey<String>('hint'),
                                  child: Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(
                                      l10n.lookupTapToExpand,
                                      style: tt.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
