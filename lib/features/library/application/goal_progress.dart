/// Pure today's-goal computation for the Home "Today's Goal" card
/// (`todays_goal_card.dart`): completed minutes, progress percentage, and
/// encouragement band.
///
/// No Flutter / l10n imports here — the card maps
/// [GoalEncouragementTier] to localized copy and paints the result.
library;

import 'dart:math' as math;

/// Practice goal (minutes) used when the profile has none
/// (`UserProfile.goal == null`) or the auth state is not signed in.
const int kDefaultGoalMinutes = 30;

/// Smallest usable daily goal: one minute.
const int kMinGoalMinutes = 1;

/// Largest usable daily goal: 24 hours of practice in a day.
const int kMaxGoalMinutes = 24 * 60;

/// Encouragement copy band for a goal percentage; the card maps each tier to
/// its localized `homeGoal*` string.
enum GoalEncouragementTier {
  /// 0% — nothing recorded yet.
  startNow,

  /// >0% and <25%.
  justStarted,

  /// >=25% and <50%.
  goodStart,

  /// >=50% and <75%.
  halfway,

  /// >=75% and <100%.
  almostThere,

  /// >=100%.
  completed,
}

/// Resolves a raw profile goal into a usable minute target: `null` becomes
/// [kDefaultGoalMinutes], and the value is clamped to
/// [kMinGoalMinutes]–[kMaxGoalMinutes] (a non-positive or >24h goal must not
/// reach the percentage math).
int normalizeGoalMinutes(int? goalMinutes) {
  final goal = goalMinutes ?? kDefaultGoalMinutes;
  if (goal < kMinGoalMinutes) return kMinGoalMinutes;
  if (goal > kMaxGoalMinutes) return kMaxGoalMinutes;
  return goal;
}

/// Whole practice minutes completed today. Sub-minute time is floored, never
/// rounded up: 59,999 ms counts as 0 minutes.
int goalCompletedMinutes(int recordingDurationMs) =>
    recordingDurationMs ~/ (60 * 1000);

/// Percentage of the goal completed, from raw recording milliseconds: floors
/// to whole minutes *first*, then converts.
///
/// Rounded half away from zero and capped at 100 (over-goal practice never
/// renders above 100%). This ordering is deliberate web parity. The web
/// client derives its ring's SVG `stroke-dashoffset` from the same
/// floored-minute percentage, and the figure line renders
/// `completedMinutes / goalMinutes` — the ring, the percent figure, and the
/// "n / goal min" line must all move together on whole-minute boundaries, so
/// a 59,999 ms recording against a 1-minute goal shows 0%, not 100%.
///
/// [goalMinutes] must be [normalizeGoalMinutes] output — a non-positive
/// value is a precondition violation and trips an assert in debug builds.
int goalPercent(int recordingDurationMs, int goalMinutes) {
  assert(goalMinutes > 0, 'goalMinutes must be normalizeGoalMinutes output');
  return math.min(
    100,
    ((goalCompletedMinutes(recordingDurationMs) / goalMinutes) * 100).round(),
  );
}

/// Encouragement band for [percentage]. Boundaries: 0 is [startNow];
/// >0 starts [justStarted]; then 25 / 50 / 75 / 100 step up inclusively.
GoalEncouragementTier goalEncouragementTier(int percentage) {
  if (percentage >= 100) return GoalEncouragementTier.completed;
  if (percentage >= 75) return GoalEncouragementTier.almostThere;
  if (percentage >= 50) return GoalEncouragementTier.halfway;
  if (percentage >= 25) return GoalEncouragementTier.goodStart;
  if (percentage > 0) return GoalEncouragementTier.justStarted;
  return GoalEncouragementTier.startNow;
}

/// Immutable snapshot of today's goal progress for presentation.
class GoalProgress {
  const GoalProgress({
    required this.recordingDurationMs,
    required this.goalMinutes,
    required this.completedMinutes,
    required this.percent,
  });

  /// Raw recording duration (ms) the snapshot was computed from.
  final int recordingDurationMs;

  /// Normalized goal target in minutes (defaulted + clamped).
  final int goalMinutes;

  /// [goalCompletedMinutes] of [recordingDurationMs].
  final int completedMinutes;

  /// [goalPercent] — the single percentage rendered by the ring, label,
  /// and semantics string.
  final int percent;

  /// Whether the goal is reached ([percent] >= 100).
  bool get isComplete => percent >= 100;

  /// Encouragement band for [percent].
  GoalEncouragementTier get encouragement => goalEncouragementTier(percent);
}

/// Computes the card's full progress snapshot.
///
/// [goalMinutes] is the raw profile value (`UserProfile.goal`); `null` (no
/// goal, or auth not resolved) falls back to [kDefaultGoalMinutes] and the
/// result is clamped via [normalizeGoalMinutes].
GoalProgress computeGoalProgress({
  required int recordingDurationMs,
  int? goalMinutes,
}) {
  final goal = normalizeGoalMinutes(goalMinutes);
  return GoalProgress(
    recordingDurationMs: recordingDurationMs,
    goalMinutes: goal,
    completedMinutes: goalCompletedMinutes(recordingDurationMs),
    percent: goalPercent(recordingDurationMs, goal),
  );
}
