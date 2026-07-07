/// Today's practice goal (signed-in home dashboard): ring card (wide) or
/// compact progress bar (mobile strip).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/library/application/learning_statistics_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Presentation mode for [TodaysGoalCard].
enum TodaysGoalCardVariant {
  /// Circular progress ring + details (tablet / desktop).
  card,

  /// Linear progress + compact copy (mobile insight strip).
  bar,
}

int _completedMinutes(int recordingDurationMs) =>
    recordingDurationMs ~/ (60 * 1000);

int _progressPercentFromMinutes(int completedMinutes, int goalMinutes) {
  if (goalMinutes <= 0) return 0;
  return math.min(100, ((completedMinutes / goalMinutes) * 100).round());
}

/// Progress 0..1 using raw ms so sub-minute practice still shows on the bar.
double _progressFractionMs(int recordingDurationMs, int goalMinutes) {
  if (goalMinutes <= 0) return 0;
  final goalMs = goalMinutes * 60 * 1000;
  return math.min(1, recordingDurationMs / goalMs);
}

int _progressPercentForLabel(int recordingDurationMs, int goalMinutes) {
  return _progressPercentFromMinutes(
    _completedMinutes(recordingDurationMs),
    goalMinutes,
  );
}

String _encouragement(AppLocalizations l10n, int percentage) {
  if (percentage >= 100) return l10n.homeGoalCompleted;
  if (percentage >= 75) return l10n.homeGoalAlmostThere;
  if (percentage >= 50) return l10n.homeGoalHalfway;
  if (percentage >= 25) return l10n.homeGoalGoodStart;
  if (percentage > 0) return l10n.homeGoalJustStarted;
  return l10n.homeGoalStartNow;
}

/// Circular ring matching web SVG dash-offset semantics.
class _GoalRingPainter extends CustomPainter {
  _GoalRingPainter({
    required this.percentage,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final int percentage;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final sweep = 2 * math.pi * (percentage.clamp(0, 100) / 100);
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _GoalRingPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
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

  static const double _ringSizeCard = 116;
  static const double _ringSizeBar = 52;
  static const double _strokeWidthCard = 8;
  static const double _strokeWidthBar = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(learningStatisticsProvider);
    final authAsync = ref.watch(authCtrlProvider);

    final goalMinutes = authAsync.maybeWhen(
      data: (auth) => auth is AuthSignedIn
          ? (auth.profile.goal ?? 30).clamp(1, 24 * 60)
          : 30,
      orElse: () => 30,
    );

    return statsAsync.when(
      skipLoadingOnReload: true,
      data: (stats) {
        if (stats == null) return const SizedBox.shrink();

        final completedMin = _completedMinutes(stats.today.recordingDurationMs);
        final pctLabel = _progressPercentForLabel(
          stats.today.recordingDurationMs,
          goalMinutes,
        );
        final encouragement = _encouragement(l10n, pctLabel);
        final done = pctLabel >= 100;
        final progressColor = done ? cs.tertiary : cs.primary;
        final msgColor = done ? cs.tertiary : cs.onSurfaceVariant;

        final child = variant == TodaysGoalCardVariant.card
            ? _buildCardVariant(
                context,
                t,
                cs,
                l10n,
                stats.today.recordingDurationMs,
                completedMin,
                goalMinutes,
                pctLabel,
                encouragement,
                progressColor,
                msgColor,
              )
            : _buildBarVariant(
                context,
                t,
                cs,
                l10n,
                stats.today.recordingDurationMs,
                completedMin,
                goalMinutes,
                pctLabel,
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
              '${l10n.homeTodaysGoal}, $pctLabel%, $completedMin of $goalMinutes ${l10n.homeMinutes}',
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
    final padded = Padding(padding: EdgeInsets.all(t.space16), child: child);
    final semanticsChild = Semantics(label: semanticsLabel, child: padded);
    if (containedInParentCard) {
      return semanticsChild;
    }
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: semanticsChild,
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.track_changes_rounded, size: 20, color: cs.primary),
            SizedBox(width: t.space8),
            Expanded(
              child: Text(
                l10n.homeTodaysGoal,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        SizedBox(height: t.space12),
        Center(
          child: SizedBox(
            width: _ringSizeCard,
            height: _ringSizeCard,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(_ringSizeCard, _ringSizeCard),
                  painter: _GoalRingPainter(
                    percentage: pct,
                    trackColor: cs.surfaceContainerHighest,
                    progressColor: progressColor,
                    strokeWidth: _strokeWidthCard,
                  ),
                ),
                Text(
                  '$pct%',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: t.space12),
        Text(
          '$completedMin / $goalMinutes ${l10n.homeMinutes}',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: t.space4),
        Text(
          '${formatPracticeDurationMs(recordingDurationMs)} ${l10n.homeCompleted}',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        SizedBox(height: t.space8),
        Text(
          encouragement,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
    final frac = _progressFractionMs(recordingDurationMs, goalMinutes);
    final radius = BorderRadius.circular(t.radiusSm);
    final durationText = formatPracticeDurationMs(recordingDurationMs);
    final tabular = const [FontFeature.tabularFigures()];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _ringSizeBar,
              height: _ringSizeBar,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(_ringSizeBar, _ringSizeBar),
                    painter: _GoalRingPainter(
                      percentage: pct,
                      trackColor: cs.surfaceContainerHighest,
                      progressColor: progressColor,
                      strokeWidth: _strokeWidthBar,
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFeatures: tabular,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: t.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.track_changes_rounded,
                        size: 16,
                        color: cs.primary,
                      ),
                      SizedBox(width: t.space4),
                      Expanded(
                        child: Text(
                          l10n.homeTodaysGoal,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: t.space4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text:
                              '$completedMin / $goalMinutes ${l10n.homeMinutes}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontFeatures: tabular,
                              ),
                        ),
                        TextSpan(
                          text: ' · $durationText',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: t.space12),
        ClipRRect(
          borderRadius: radius,
          child: LinearProgressIndicator(
            value: frac.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: cs.surfaceContainerHighest,
            color: progressColor,
          ),
        ),
        SizedBox(height: t.space8),
        Text(
          encouragement,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: msgColor,
            fontWeight: FontWeight.w500,
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
    final base = cs.surfaceContainerHighest.withValues(alpha: 0.6);
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
          SizedBox(height: t.space8),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          SizedBox(height: t.space4),
          Container(
            height: 12,
            width: 160,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.track_changes_rounded, size: 20, color: cs.primary),
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
          Icon(Icons.error_outline, color: cs.error, size: 20),
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
        Icon(Icons.error_outline, color: cs.error, size: 22),
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
