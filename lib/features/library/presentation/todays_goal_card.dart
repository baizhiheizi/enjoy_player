/// Today's practice goal (signed-in home dashboard): ring card (wide) or
/// compact progress bar (mobile strip).
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_progress_ring.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/library/application/goal_progress.dart';
import 'package:enjoy_player/features/library/application/learning_statistics_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Presentation mode for [TodaysGoalCard].
enum TodaysGoalCardVariant {
  /// Circular progress ring + details (tablet / desktop).
  card,

  /// Linear progress + compact copy (mobile insight strip).
  bar,
}

String _encouragementText(AppLocalizations l10n, GoalEncouragementTier tier) {
  switch (tier) {
    case GoalEncouragementTier.completed:
      return l10n.homeGoalCompleted;
    case GoalEncouragementTier.almostThere:
      return l10n.homeGoalAlmostThere;
    case GoalEncouragementTier.halfway:
      return l10n.homeGoalHalfway;
    case GoalEncouragementTier.goodStart:
      return l10n.homeGoalGoodStart;
    case GoalEncouragementTier.justStarted:
      return l10n.homeGoalJustStarted;
    case GoalEncouragementTier.startNow:
      return l10n.homeGoalStartNow;
  }
}

class TodaysGoalCard extends ConsumerWidget {
  const TodaysGoalCard({
    super.key,
    this.variant = TodaysGoalCardVariant.card,
    this.containedInParentCard = false,
  });

  final TodaysGoalCardVariant variant;
  final bool containedInParentCard;

  static const double _ringSizeCard = 112;
  static const double _ringSizeBar = 62;
  static const double _strokeWidthCard = 8;
  static const double _strokeWidthBar = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
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
        final encouragement = _encouragementText(l10n, progress.encouragement);
        final done = progress.isComplete;
        final progressColor = done ? t.ink : cs.primary;
        final msgColor = done ? t.ink : cs.onSurfaceVariant;

        final child = variant == TodaysGoalCardVariant.card
            ? _buildCardVariant(
                context,
                t,
                cs,
                l10n,
                progress.recordingDurationMs,
                progress.completedMinutes,
                progress.goalMinutes,
                progress.percent,
                encouragement,
                progressColor,
                msgColor,
              )
            : _buildBarVariant(
                context,
                t,
                cs,
                l10n,
                progress.recordingDurationMs,
                progress.completedMinutes,
                progress.goalMinutes,
                progress.percent,
                encouragement,
                progressColor,
                msgColor,
              );

        return _wrapCard(
          context: context,
          containedInParentCard: containedInParentCard,
          t: t,
          child: child,
          semanticsLabel:
              '${l10n.homeTodaysGoal}, ${progress.percent}%, ${progress.completedMinutes} of ${progress.goalMinutes} ${l10n.homeMinutes}',
        );
      },
      loading: () => _wrapCard(
        context: context,
        containedInParentCard: containedInParentCard,
        t: t,
        child: _TodaysGoalLoadingBody(t: t, cs: cs, variant: variant),
        semanticsLabel: l10n.homeTodaysGoal,
      ),
      error: (e, _) => _wrapCard(
        context: context,
        containedInParentCard: containedInParentCard,
        t: t,
        child: _TodaysGoalErrorBody(
          t: t,
          cs: cs,
          variant: variant,
          onRetry: () => ref.invalidate(learningStatisticsProvider),
        ),
        semanticsLabel: l10n.homeTodaysGoal,
      ),
    );
  }

  Widget _wrapCard({
    required BuildContext context,
    required bool containedInParentCard,
    required EnjoyThemeTokens t,
    required Widget child,
    required String semanticsLabel,
  }) {
    final padded = Padding(
      padding: EdgeInsets.all(t.space16 + 2),
      child: child,
    );
    final semanticsChild = Semantics(label: semanticsLabel, child: padded);
    if (containedInParentCard) {
      return semanticsChild;
    }
    return EnjoyCard(child: semanticsChild);
  }

  Widget _ring(
    BuildContext context,
    EnjoyThemeTokens t,
    int pct,
    double size,
    double stroke,
    Color progressColor, {
    required TextStyle? labelStyle,
  }) {
    final done = pct >= 100;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: EnjoyProgressRingPainter(
              progress: pct / 100,
              trackColor: t.fill,
              gradientColors: done
                  ? [progressColor, progressColor]
                  : [t.logoStart, t.logoEnd],
              strokeWidth: stroke,
            ),
          ),
          if (done)
            Icon(EnjoyIcons.check, size: size * 0.36, color: progressColor)
          else
            Text('$pct%', style: labelStyle),
        ],
      ),
    );
  }

  Widget _figureLine(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
    int completedMin,
    int goalMinutes, {
    required double size,
  }) {
    final tt = Theme.of(context).textTheme;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$completedMin',
            style: enjoyDisplayStyle(context, size: size, color: cs.onSurface),
          ),
          TextSpan(
            text: ' / $goalMinutes ${l10n.homeMinutes}',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCardVariant(
    BuildContext context,
    EnjoyThemeTokens t,
    ColorScheme cs,
    AppLocalizations l10n,
    int recordingDurationMs,
    int completedMin,
    int goalMinutes,
    int pct,
    String encouragement,
    Color progressColor,
    Color msgColor,
  ) {
    final tt = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnjoyOverline(l10n.homeTodaysGoal),
        SizedBox(height: t.space16),
        Center(
          child: _ring(
            context,
            t,
            pct,
            _ringSizeCard,
            _strokeWidthCard,
            progressColor,
            labelStyle: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        SizedBox(height: t.space16),
        Center(
          child: _figureLine(
            context,
            cs,
            l10n,
            completedMin,
            goalMinutes,
            size: 34,
          ),
        ),
        SizedBox(height: t.space4),
        Text(
          '${formatPracticeDurationMs(recordingDurationMs)} ${l10n.homeCompleted}',
          textAlign: TextAlign.center,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        SizedBox(height: t.space8),
        Text(
          encouragement,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: tt.bodySmall?.copyWith(
            color: msgColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBarVariant(
    BuildContext context,
    EnjoyThemeTokens t,
    ColorScheme cs,
    AppLocalizations l10n,
    int recordingDurationMs,
    int completedMin,
    int goalMinutes,
    int pct,
    String encouragement,
    Color progressColor,
    Color msgColor,
  ) {
    final tt = Theme.of(context).textTheme;
    final durationText = formatPracticeDurationMs(recordingDurationMs);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ring(
          context,
          t,
          pct,
          _ringSizeBar,
          _strokeWidthBar,
          progressColor,
          labelStyle: tt.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        SizedBox(width: t.space16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              EnjoyOverline(l10n.homeTodaysGoal),
              const SizedBox(height: 2),
              _figureLine(
                context,
                cs,
                l10n,
                completedMin,
                goalMinutes,
                size: 30,
              ),
              Text(
                '$durationText · $encouragement',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(color: msgColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodaysGoalLoadingBody extends StatelessWidget {
  const _TodaysGoalLoadingBody({
    required this.t,
    required this.cs,
    required this.variant,
  });

  final EnjoyThemeTokens t;
  final ColorScheme cs;
  final TodaysGoalCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final base = t.fill;
    if (variant == TodaysGoalCardVariant.bar) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: TodaysGoalCard._ringSizeBar,
                height: TodaysGoalCard._ringSizeBar,
                decoration: BoxDecoration(color: base, shape: BoxShape.circle),
              ),
              SizedBox(width: t.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 100,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: t.space4),
                    Container(
                      height: 14,
                      width: 140,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(EnjoyIcons.target, size: 20, color: cs.primary),
            SizedBox(width: t.space8),
            Container(
              height: 22,
              width: 140,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        SizedBox(height: t.space16),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: base, shape: BoxShape.circle),
          ),
        ),
        SizedBox(height: t.space16),
        Center(
          child: Container(
            height: 24,
            width: 160,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        SizedBox(height: t.space8),
        Center(
          child: Container(
            height: 14,
            width: 120,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}

class _TodaysGoalErrorBody extends StatelessWidget {
  const _TodaysGoalErrorBody({
    required this.t,
    required this.cs,
    required this.variant,
    required this.onRetry,
  });

  final EnjoyThemeTokens t;
  final ColorScheme cs;
  final TodaysGoalCardVariant variant;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (variant == TodaysGoalCardVariant.bar) {
      return Row(
        children: [
          Icon(EnjoyIcons.error, color: cs.error, size: 20),
          SizedBox(width: t.space8),
          Expanded(
            child: Text(
              l10n.errorNetwork,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: t.space8),
              minimumSize: const Size(48, 40),
            ),
            child: Text(l10n.retry),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(EnjoyIcons.error, color: cs.error, size: 22),
        SizedBox(width: t.space12),
        Expanded(
          child: Text(
            l10n.errorNetwork,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        TextButton(onPressed: onRetry, child: Text(l10n.retry)),
      ],
    );
  }
}
