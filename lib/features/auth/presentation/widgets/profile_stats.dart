/// Profile practice-statistics section (loading / data / error) + responsive row.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/features/auth/application/profile_practice_stats_provider.dart';
import 'package:enjoy_player/features/library/application/learning_statistics_provider.dart';
import 'package:enjoy_player/features/library/domain/learning_statistics.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class ProfilePracticeSection extends ConsumerWidget {
  const ProfilePracticeSection({required this.stats, super.key});

  final AsyncValue<LearningStatistics> stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return stats.when(
      data: (data) => ProfileStatsRow(stats: data),
      loading: () => SizedBox(
        height: 100,
        child: Row(
          children: [
            Expanded(child: ProfileStatSkeleton(tokens: t)),
            SizedBox(width: t.space12),
            Expanded(child: ProfileStatSkeleton(tokens: t)),
            SizedBox(width: t.space12),
            Expanded(child: ProfileStatSkeleton(tokens: t)),
          ],
        ),
      ),
      error: (_, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: cs.errorContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(t.radiusLg),
          border: Border.all(color: cs.error.withValues(alpha: 0.25)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: t.space16,
            vertical: t.space12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.error,
                  style: tt.bodySmall?.copyWith(color: cs.onErrorContainer),
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.invalidate(profilePracticeStatsProvider);
                  ref.invalidate(learningStatisticsProvider);
                },
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileStatSkeleton extends StatelessWidget {
  const ProfileStatSkeleton({required this.tokens, super.key});

  final EnjoyThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return EnjoyCard(
      padding: EdgeInsets.all(tokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton.line(width: 48, height: 12),
          SizedBox(height: tokens.space12),
          Skeleton.line(width: 72, height: 22),
          SizedBox(height: tokens.space8),
          Skeleton.line(width: 56, height: 12),
        ],
      ),
    );
  }
}

class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({required this.stats, super.key});

  final LearningStatistics stats;

  static const _narrowBreakpoint = 360.0;
  static const _tileWidth = 132.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final tiles = [
      ProfileStatTile(
        periodLabel: l10n.profileStatTodayTitle,
        durationLabel: formatPracticeDurationMs(
          stats.today.recordingDurationMs,
        ),
        recordingsLabel: l10n.transcriptLineRecordingCount(
          stats.today.recordingCount,
        ),
        icon: Icons.wb_sunny_outlined,
        accentColor: cs.primary,
        textTheme: tt,
        tokens: t,
      ),
      ProfileStatTile(
        periodLabel: l10n.profileStatWeekTitle,
        durationLabel: formatPracticeDurationMs(stats.week.recordingDurationMs),
        recordingsLabel: l10n.transcriptLineRecordingCount(
          stats.week.recordingCount,
        ),
        icon: Icons.date_range_outlined,
        accentColor: cs.secondary,
        textTheme: tt,
        tokens: t,
      ),
      ProfileStatTile(
        periodLabel: l10n.profileStatMonthTitle,
        durationLabel: formatPracticeDurationMs(
          stats.month.recordingDurationMs,
        ),
        recordingsLabel: l10n.transcriptLineRecordingCount(
          stats.month.recordingCount,
        ),
        icon: Icons.calendar_month_outlined,
        accentColor: cs.tertiary,
        textTheme: tt,
        tokens: t,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _narrowBreakpoint) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) SizedBox(width: t.space12),
                  SizedBox(width: _tileWidth, child: tiles[i]),
                ],
              ],
            ),
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) SizedBox(width: t.space12),
                Expanded(child: tiles[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

class ProfileStatTile extends StatelessWidget {
  const ProfileStatTile({
    required this.periodLabel,
    required this.durationLabel,
    required this.recordingsLabel,
    required this.icon,
    required this.accentColor,
    required this.textTheme,
    required this.tokens,
    super.key,
  });

  final String periodLabel;
  final String durationLabel;
  final String recordingsLabel;
  final IconData icon;
  final Color accentColor;
  final TextTheme textTheme;
  final EnjoyThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return EnjoyCard(
      padding: EdgeInsets.all(tokens.space16),
      child: Semantics(
        container: true,
        label: '$periodLabel, $durationLabel, $recordingsLabel',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(tokens.radiusMd),
                  ),
                  child: Icon(icon, size: 18, color: accentColor),
                ),
                SizedBox(width: tokens.space8),
                Expanded(
                  child: Text(
                    periodLabel,
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.space12),
            Text(
              durationLabel,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: tokens.space4),
            Text(
              recordingsLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
