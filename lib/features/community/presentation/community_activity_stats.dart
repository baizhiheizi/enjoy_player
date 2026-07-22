/// Today-stats and simple-count body sections for the community activity card.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/features/community/domain/active_user.dart';
import 'package:enjoy_player/features/community/presentation/community_activity_avatars.dart';
import 'package:enjoy_player/features/community/presentation/community_activity_metrics.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Internal building block for `CommunityActivityCard`; not public API.
class TodayStatsBody extends StatelessWidget {
  const TodayStatsBody({
    super.key,
    required this.data,
    required this.denseAvatars,
    this.compactValues = false,
  });

  final ActiveUsersResponse data;
  final bool denseAvatars;
  final bool compactValues;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final small = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 16, color: cs.primary),
            SizedBox(width: t.space8),
            Text(l10n.communityToday.toUpperCase(), style: small),
          ],
        ),
        SizedBox(height: t.space8),
        Row(
          children: [
            if (data.recordingsCountToday != null) ...[
              Expanded(
                child: StatBlock(
                  icon: Icons.mic,
                  valueText: '${data.recordingsCountToday}',
                  label: l10n.homeRecordingsToday,
                  compactValue: compactValues,
                ),
              ),
            ],
            if (data.recordingsDurationToday != null) ...[
              if (data.recordingsCountToday != null) SizedBox(width: t.space12),
              Expanded(
                child: StatBlock(
                  icon: Icons.schedule,
                  valueText: formatPracticeDurationMs(
                    data.recordingsDurationToday!,
                  ),
                  label: l10n.homePracticeTime,
                  compactValue: compactValues,
                ),
              ),
            ],
          ],
        ),
        if (data.users.isNotEmpty) ...[
          SizedBox(height: t.space12),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.35)),
          SizedBox(height: t.space8),
          ActiveLearnersRow(
            data: data,
            dense: denseAvatars,
            maxAvatars: kMaxAvatarsCard,
          ),
        ],
      ],
    );
  }
}

/// Internal building block for `CommunityActivityCard`; not public API.
class SimpleCountBody extends StatelessWidget {
  const SimpleCountBody({
    super.key,
    required this.data,
    required this.denseAvatars,
    this.compactHeadline = false,
    this.maxAvatars = kMaxAvatarsCard,
  });

  final ActiveUsersResponse data;
  final bool denseAvatars;
  final bool compactHeadline;
  final int maxAvatars;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    if (data.users.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '0',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: t.space8),
          Text(
            l10n.homeNoActiveUsers,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      );
    }

    final countStyle = compactHeadline
        ? Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${data.count}', style: countStyle),
        SizedBox(height: t.space4),
        Text(
          l10n.homePeopleLearning(data.count),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        SizedBox(height: t.space12),
        AvatarWrap(
          users: data.users,
          totalCount: data.count,
          dense: denseAvatars,
          maxShown: maxAvatars,
        ),
      ],
    );
  }
}

/// Internal building block for `CommunityActivityCard`; not public API.
class ActiveLearnersRow extends StatelessWidget {
  const ActiveLearnersRow({
    super.key,
    required this.data,
    required this.dense,
    this.maxAvatars = kMaxAvatarsCard,
  });

  final ActiveUsersResponse data;
  final bool dense;
  final int maxAvatars;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.homeActiveLearners,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (data.count > 0)
              Text(
                '${data.count}',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
          ],
        ),
        SizedBox(height: t.space8),
        AvatarWrap(
          users: data.users,
          totalCount: data.count,
          dense: dense,
          maxShown: maxAvatars,
        ),
      ],
    );
  }
}
