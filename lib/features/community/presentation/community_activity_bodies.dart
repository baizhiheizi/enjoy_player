/// Summary body for the `CommunityActivityCard`.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
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
            Expanded(child: EnjoyOverline(l10n.communityActivity)),
            if (data.users.isNotEmpty)
              OverlappingAvatarStack(
                users: data.users,
                totalCount: data.count,
                maxShown: kMaxAvatarsSummary,
                cs: cs,
              ),
          ],
        ),
        SizedBox(height: t.space4),
        if (hasToday) ...[
          Wrap(
            spacing: t.space24,
            runSpacing: t.space4,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              if (data.recordingsCountToday != null)
                InlineMetric(
                  icon: EnjoyIcons.mic,
                  value: NumberFormat.decimalPattern(
                    locale,
                  ).format(data.recordingsCountToday),
                  label: l10n.homeRecordingsToday,
                  cs: cs,
                  tabular: tabular,
                ),
              if (data.recordingsDurationToday != null)
                InlineMetric(
                  icon: EnjoyIcons.clock,
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
            SizedBox(height: t.space4),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: t.scoreGood,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: t.scoreGood.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: t.space8 - 2),
                Flexible(
                  child: Text(
                    '${data.count} ${l10n.homeActiveLearners}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: subStyle?.copyWith(fontFeatures: tabular),
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
