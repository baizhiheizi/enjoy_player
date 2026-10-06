/// Summary body for the `CommunityActivityCard`.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/features/community/domain/active_user.dart';
import 'package:enjoy_player/features/community/presentation/community_activity_avatars.dart';
import 'package:enjoy_player/features/community/presentation/community_activity_metrics.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Internal building block for `CommunityActivityCard`; not public API.
class SummaryBody extends StatelessWidget {
  const SummaryBody({
    super.key,
    required this.data,
    required this.t,
    required this.cs,
  });

  final ActiveUsersResponse data;
  final EnjoyThemeTokens t;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasToday =
        data.recordingsCountToday != null ||
        data.recordingsDurationToday != null;
    final subStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);
    final tabular = const [FontFeature.tabularFigures()];
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: EnjoyOverline(l10n.communityToday)),
            if (data.users.isNotEmpty)
              OverlappingAvatarStack(
                users: data.users,
                totalCount: data.count,
                maxShown: kMaxAvatarsSummary,
                cs: cs,
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (hasToday) ...[
          Wrap(
            spacing: t.space24,
            runSpacing: t.space8,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              if (data.recordingsCountToday != null)
                InlineMetric(
                  value: NumberFormat.decimalPattern(
                    locale,
                  ).format(data.recordingsCountToday),
                  label: l10n.homeRecordingsToday,
                  cs: cs,
                  tabular: tabular,
                ),
              if (data.recordingsDurationToday != null)
                InlineMetric(
                  value: formatPracticeDurationMs(
                    data.recordingsDurationToday!,
                  ),
                  label: l10n.homePracticeTime,
                  cs: cs,
                  tabular: tabular,
                ),
            ],
          ),
          if (data.count > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: t.original,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    l10n.homePeopleLearning(data.count),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: subStyle?.copyWith(
                      fontSize: 12.5,
                      color: t.ink2,
                      fontFeatures: tabular,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ] else if (data.users.isEmpty)
          Text(
            l10n.homeNoActiveUsers,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: subStyle,
          )
        else
          Text(
            l10n.homePeopleLearning(data.count),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: subStyle,
          ),
      ],
    );
  }
}
