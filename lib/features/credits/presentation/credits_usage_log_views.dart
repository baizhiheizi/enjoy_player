/// The two ways of rendering a single usage log (wide table row and
/// narrow card) plus the small reusable chips shared between them.
library;

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_icon_tile.dart';
import 'package:enjoy_player/features/credits/domain/credits_usage_log.dart';
import 'package:enjoy_player/features/credits/presentation/credits_usage_format.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Aurora allowed / denied state pill.
const double _kCellGutter = 16;

class UsageTable extends StatelessWidget {
  const UsageTable({required this.logs, required this.localeName, super.key});

  final List<CreditsUsageLog> logs;
  final String localeName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final tf = DateFormat.Hm();
    final number = NumberFormat.decimalPattern(localeName);
    final cell = enjoyMonoStyle(context, size: 12.5, color: t.ink);
    final cellMuted = enjoyMonoStyle(context, size: 12.5, color: t.ink3);

    Widget headerCell(String label, {bool right = false}) => Padding(
      padding: EdgeInsets.only(left: right ? _kCellGutter : 0, bottom: 12),
      child: Align(
        alignment: right ? Alignment.centerRight : Alignment.centerLeft,
        child: EnjoyOverline(label),
      ),
    );

    Widget cellOf(Widget child, {bool right = false}) => Padding(
      padding: EdgeInsets.fromLTRB(right ? _kCellGutter : 0, 10, 0, 10),
      child: Align(
        alignment: right ? Alignment.centerRight : Alignment.centerLeft,
        child: child,
      ),
    );

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      defaultColumnWidth: const FlexColumnWidth(),
      columnWidths: const {
        3: FixedColumnWidth(90),
        4: FixedColumnWidth(90),
        5: FixedColumnWidth(92),
        6: FixedColumnWidth(100),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.line)),
          ),
          children: [
            headerCell(l10n.creditsUsageTableDate),
            headerCell(l10n.creditsUsageTableTime),
            headerCell(l10n.creditsUsageTableService),
            headerCell(l10n.creditsUsageTableTier),
            headerCell(l10n.creditsUsageTableRequired, right: true),
            headerCell(l10n.creditsUsageTableUsedAfter, right: true),
            headerCell(l10n.creditsUsageTableStatus, right: true),
          ],
        ),
        for (final log in logs)
          TableRow(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.line)),
            ),
            children: [
              cellOf(Text(log.date, style: cell)),
              cellOf(
                Text(
                  tf.format(
                    DateTime.fromMillisecondsSinceEpoch(
                      log.timestampMs,
                      isUtc: true,
                    ).toLocal(),
                  ),
                  style: cellMuted,
                ),
              ),
              cellOf(
                Text(
                  serviceTypeLabel(l10n, log.serviceType),
                  style: tt.labelLarge?.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: t.ink,
                  ),
                ),
              ),
              cellOf(Text(tierLabel(l10n, log.tier), style: cellMuted)),
              cellOf(
                Text(
                  number.format(log.creditsRequired),
                  style: cell,
                  textAlign: TextAlign.right,
                ),
                right: true,
              ),
              cellOf(
                Text(number.format(log.usedAfter), style: cellMuted),
                right: true,
              ),
              cellOf(
                _UsageBadge(
                  allowed: log.allowed,
                  label: log.allowed
                      ? l10n.creditsUsageAllowed
                      : l10n.creditsUsageDenied,
                ),
                right: true,
              ),
            ],
          ),
      ],
    );
  }
}

class UsageLogCard extends StatelessWidget {
  const UsageLogCard({required this.log, required this.localeName, super.key});

  final CreditsUsageLog log;
  final String localeName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final when = DateTime.fromMillisecondsSinceEpoch(
      log.timestampMs,
      isUtc: true,
    ).toLocal();
    final whenText = DateFormat.yMMMd(localeName).add_jm().format(when);
    final statusLabel = log.allowed
        ? l10n.creditsUsageAllowed
        : l10n.creditsUsageDenied;
    final numberStyle = enjoyMonoStyle(
      context,
      size: 15,
      weight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    );

    return EnjoyCard(
      padding: EdgeInsets.all(t.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EnjoyIconTile(icon: serviceTypeIcon(log.serviceType)),
              SizedBox(width: t.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      whenText,
                      style: enjoyMonoStyle(
                        context,
                        size: 14,
                        weight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: t.space4),
                    Text(
                      'UTC · ${log.date}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: t.ink3),
                    ),
                  ],
                ),
              ),
              SizedBox(width: t.space8),
              _UsageBadge(allowed: log.allowed, label: statusLabel),
            ],
          ),
          SizedBox(height: t.space12),
          Row(
            children: [
              Expanded(
                child: _UsageMetaPill(
                  label: serviceTypeLabel(l10n, log.serviceType),
                ),
              ),
              SizedBox(width: t.space8),
              Expanded(child: _UsageMetaPill(label: tierLabel(l10n, log.tier))),
            ],
          ),
          SizedBox(height: t.space12),
          Row(
            children: [
              for (final (label, value) in [
                (l10n.creditsUsageTableRequired, '${log.creditsRequired}'),
                (l10n.creditsUsageTableUsedBefore, '${log.usedBefore}'),
                (l10n.creditsUsageTableUsedAfter, '${log.usedAfter}'),
              ])
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: t.ink3),
                      ),
                      SizedBox(height: t.space4),
                      Text(value, style: numberStyle),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsageBadge extends StatelessWidget {
  const _UsageBadge({required this.allowed, required this.label});

  final bool allowed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: ShapeDecoration(
        color: allowed ? t.sunk : t.ink,
        shape: const StadiumBorder(),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: allowed ? t.ink2 : t.paper,
          ),
        ),
      ),
    );
  }
}

class _UsageMetaPill extends StatelessWidget {
  const _UsageMetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: t.space12, vertical: t.space8),
      decoration: ShapeDecoration(
        color: t.fill,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(t.radiusFull),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: enjoyMonoStyle(context, size: 13, color: cs.onSurfaceVariant),
      ),
    );
  }
}
