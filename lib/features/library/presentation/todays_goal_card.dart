/// Today's practice goal on Home: an 88px logo-gradient ring holding the
/// minutes practiced, with the encouragement and the remaining minutes
/// beside it (the `Home` board).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_progress_ring.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/library/application/goal_progress.dart';
import 'package:enjoy_player/features/library/application/learning_statistics_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const double _kRingSize = 88;
const double _kRingStroke = 8;
const EdgeInsets _kCardPadding = EdgeInsets.symmetric(
  horizontal: 22,
  vertical: 20,
);

String _encouragementText(AppLocalizations l10n, GoalEncouragementTier tier) =>
    switch (tier) {
      GoalEncouragementTier.completed => l10n.homeGoalCompleted,
      GoalEncouragementTier.almostThere => l10n.homeGoalAlmostThere,
      GoalEncouragementTier.halfway => l10n.homeGoalHalfway,
      GoalEncouragementTier.goodStart => l10n.homeGoalGoodStart,
      GoalEncouragementTier.justStarted => l10n.homeGoalJustStarted,
      GoalEncouragementTier.startNow => l10n.homeGoalStartNow,
    };

class TodaysGoalCard extends ConsumerWidget {
  const TodaysGoalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(learningStatisticsProvider);
    final profileGoal = ref.watch(
      authCtrlProvider.select(
        (a) => a.whenOrNull(
          data: (auth) => auth is AuthSignedIn ? auth.profile.goal : null,
        ),
      ),
    );

    return statsAsync.when(
      skipLoadingOnReload: true,
      data: (stats) {
        if (stats == null) return const SizedBox.shrink();
        final progress = computeGoalProgress(
          recordingDurationMs: stats.today.recordingDurationMs,
          goalMinutes: profileGoal,
        );
        return _GoalCardChrome(
          semanticsLabel:
              '${l10n.homeTodaysGoal}, ${progress.percent}%, ${progress.completedMinutes} of ${progress.goalMinutes} ${l10n.homeMinutes}',
          child: _GoalBody(progress: progress),
        );
      },
      loading: () => _GoalCardChrome(
        semanticsLabel: l10n.homeTodaysGoal,
        child: const _GoalLoadingBody(),
      ),
      error: (e, _) => _GoalCardChrome(
        semanticsLabel: l10n.homeTodaysGoal,
        child: _GoalErrorBody(
          onRetry: () => ref.invalidate(learningStatisticsProvider),
        ),
      ),
    );
  }
}

class _GoalCardChrome extends StatelessWidget {
  const _GoalCardChrome({required this.semanticsLabel, required this.child});

  final String semanticsLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return EnjoyCard(
      child: Semantics(
        label: semanticsLabel,
        child: Padding(padding: _kCardPadding, child: child),
      ),
    );
  }
}

class _GoalBody extends StatelessWidget {
  const _GoalBody({required this.progress});

  final GoalProgress progress;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final remaining = (progress.goalMinutes - progress.completedMinutes).clamp(
      0,
      progress.goalMinutes,
    );
    final summary = progress.isComplete
        ? l10n.homeGoalProgressDone(
            progress.completedMinutes,
            progress.goalMinutes,
          )
        : l10n.homeGoalProgressRemaining(
            progress.completedMinutes,
            progress.goalMinutes,
            remaining,
          );

    return Row(
      children: [
        SizedBox(
          width: _kRingSize,
          height: _kRingSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size.square(_kRingSize),
                painter: EnjoyProgressRingPainter(
                  progress: progress.percent / 100,
                  trackColor: t.sunk,
                  gradientColors: [t.logoStart, t.logoEnd],
                  strokeWidth: _kRingStroke,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${progress.completedMinutes}',
                    style:
                        enjoyDisplayStyle(
                          context,
                          size: 27,
                          color: t.ink,
                          height: 1,
                        ).copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.homeGoalOfMinutes(progress.goalMinutes),
                    style: tt.bodySmall?.copyWith(
                      fontSize: 11.5,
                      color: t.ink3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              EnjoyOverline(l10n.homeTodaysGoal),
              const SizedBox(height: 9),
              Text(
                _encouragementText(l10n, progress.encouragement),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tt.titleMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: t.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(
                  fontSize: 13,
                  color: t.ink3,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalLoadingBody extends StatelessWidget {
  const _GoalLoadingBody();

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: t.sunk,
        borderRadius: BorderRadius.circular(4),
      ),
    );
    return Row(
      children: [
        Container(
          width: _kRingSize,
          height: _kRingSize,
          decoration: BoxDecoration(color: t.sunk, shape: BoxShape.circle),
        ),
        const SizedBox(width: 18),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [bar(90, 11), const SizedBox(height: 10), bar(160, 15)],
        ),
      ],
    );
  }
}

class _GoalErrorBody extends StatelessWidget {
  const _GoalErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(EnjoyIcons.error, color: cs.error, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            l10n.errorNetwork,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        TextButton(onPressed: onRetry, child: Text(l10n.retry)),
      ],
    );
  }
}
