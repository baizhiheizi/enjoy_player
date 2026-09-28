import 'package:enjoy_player/features/library/application/goal_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeGoalMinutes', () {
    test('null falls back to the 30-minute default', () {
      expect(normalizeGoalMinutes(null), 30);
    });

    test('passes through in-range goals unchanged', () {
      expect(normalizeGoalMinutes(1), 1);
      expect(normalizeGoalMinutes(45), 45);
      expect(normalizeGoalMinutes(kMaxGoalMinutes), 24 * 60);
    });

    test('clamps non-positive goals up to one minute', () {
      expect(normalizeGoalMinutes(0), 1);
      expect(normalizeGoalMinutes(-5), 1);
    });

    test('clamps goals above 24 hours down to 24*60', () {
      expect(normalizeGoalMinutes(24 * 60 + 1), 24 * 60);
      expect(normalizeGoalMinutes(100000), 24 * 60);
    });
  });

  group('goalCompletedMinutes', () {
    test('zero recording duration is zero minutes', () {
      expect(goalCompletedMinutes(0), 0);
    });

    test('sub-minute time is floored, never rounded up', () {
      expect(goalCompletedMinutes(59 * 1000), 0);
      expect(goalCompletedMinutes(60 * 1000 - 1), 0);
    });

    test('full minutes count', () {
      expect(goalCompletedMinutes(60 * 1000), 1);
      expect(goalCompletedMinutes(90 * 1000), 1);
      expect(goalCompletedMinutes(60 * 60 * 1000), 60);
    });
  });

  group('goalPercentFromMinutes', () {
    test('zero completed minutes is zero percent', () {
      expect(goalPercentFromMinutes(0, 30), 0);
    });

    test('exactly at goal is 100 percent', () {
      expect(goalPercentFromMinutes(30, 30), 100);
    });

    test('over-goal practice caps at 100 percent', () {
      expect(goalPercentFromMinutes(31, 30), 100);
      expect(goalPercentFromMinutes(60, 30), 100);
      expect(goalPercentFromMinutes(1440, 30), 100);
    });

    test('rounds to nearest percent, half away from zero', () {
      expect(goalPercentFromMinutes(15, 30), 50);
      // 23.33 -> 23, 26.67 -> 27.
      expect(goalPercentFromMinutes(7, 30), 23);
      expect(goalPercentFromMinutes(8, 30), 27);
      // 12.5 -> 13 (exact .5 rounds up).
      expect(goalPercentFromMinutes(1, 8), 13);
    });

    test('a minute of a huge goal still rounds to zero percent', () {
      expect(goalPercentFromMinutes(1, 24 * 60), 0);
    });

    test('defensive: non-positive goal yields zero, not a crash', () {
      expect(goalPercentFromMinutes(15, 0), 0);
      expect(goalPercentFromMinutes(15, -3), 0);
    });
  });

  group('goalPercentForLabel', () {
    test('floors raw milliseconds to minutes before converting', () {
      // 59,999 ms against a 1-minute goal is 0% (not 100%): the label, the
      // ring, and the "0 / 1 min" figure must move on whole-minute steps.
      expect(goalPercentForLabel(60 * 1000 - 1, 1), 0);
      expect(goalPercentForLabel(60 * 1000, 1), 100);
    });

    test('sub-minute remainder does not tip an in-progress label', () {
      // 29m59.999s of a 30-minute goal: 29/30 -> 97%, not 100%.
      expect(goalPercentForLabel(30 * 60 * 1000 - 1, 30), 97);
      expect(goalPercentForLabel(30 * 60 * 1000, 30), 100);
    });

    test('matches percent computed from floored minutes', () {
      const cases = [
        (0, 30),
        (59 * 1000, 30),
        (60 * 1000, 30),
        (17 * 60 * 1000, 30),
        (30 * 60 * 1000, 30),
        (45 * 60 * 1000, 30),
        (5 * 60 * 1000, 24 * 60),
        (60 * 60 * 1000, 24 * 60),
      ];
      for (final (ms, goal) in cases) {
        expect(
          goalPercentForLabel(ms, goal),
          goalPercentFromMinutes(goalCompletedMinutes(ms), goal),
          reason: 'ms=$ms goal=$goal',
        );
      }
    });
  });

  group('goalEncouragementTier', () {
    test('zero percent is startNow', () {
      expect(goalEncouragementTier(0), GoalEncouragementTier.startNow);
    });

    test('justStarted covers >0 up to 24', () {
      expect(goalEncouragementTier(1), GoalEncouragementTier.justStarted);
      expect(goalEncouragementTier(24), GoalEncouragementTier.justStarted);
    });

    test('goodStart starts at 25 inclusive', () {
      expect(goalEncouragementTier(25), GoalEncouragementTier.goodStart);
      expect(goalEncouragementTier(49), GoalEncouragementTier.goodStart);
    });

    test('halfway starts at 50 inclusive', () {
      expect(goalEncouragementTier(50), GoalEncouragementTier.halfway);
      expect(goalEncouragementTier(74), GoalEncouragementTier.halfway);
    });

    test('almostThere starts at 75 inclusive', () {
      expect(goalEncouragementTier(75), GoalEncouragementTier.almostThere);
      expect(goalEncouragementTier(99), GoalEncouragementTier.almostThere);
    });

    test('completed starts at 100 inclusive and stays for over-goal', () {
      expect(goalEncouragementTier(100), GoalEncouragementTier.completed);
      expect(goalEncouragementTier(150), GoalEncouragementTier.completed);
    });

    test('steps up exactly at each band boundary', () {
      const steps = [
        (24, GoalEncouragementTier.justStarted),
        (25, GoalEncouragementTier.goodStart),
        (49, GoalEncouragementTier.goodStart),
        (50, GoalEncouragementTier.halfway),
        (74, GoalEncouragementTier.halfway),
        (75, GoalEncouragementTier.almostThere),
        (99, GoalEncouragementTier.almostThere),
        (100, GoalEncouragementTier.completed),
      ];
      for (final (percentage, tier) in steps) {
        expect(goalEncouragementTier(percentage), tier);
      }
    });
  });

  group('computeGoalProgress', () {
    test('null goal uses the 30-minute default', () {
      final progress = computeGoalProgress(
        recordingDurationMs: 0,
        goalMinutes: null,
      );
      expect(progress.goalMinutes, 30);
      expect(progress.completedMinutes, 0);
      expect(progress.percent, 0);
      expect(progress.encouragement, GoalEncouragementTier.startNow);
      expect(progress.isComplete, isFalse);
    });

    test('exactly at goal reports complete', () {
      final progress = computeGoalProgress(
        recordingDurationMs: 30 * 60 * 1000,
        goalMinutes: 30,
      );
      expect(progress.completedMinutes, 30);
      expect(progress.percent, 100);
      expect(progress.isComplete, isTrue);
      expect(progress.encouragement, GoalEncouragementTier.completed);
    });

    test('over-goal caps percent at 100 but keeps raw completed minutes', () {
      final progress = computeGoalProgress(
        recordingDurationMs: 45 * 60 * 1000,
        goalMinutes: 30,
      );
      expect(progress.completedMinutes, 45);
      expect(progress.percent, 100);
      expect(progress.isComplete, isTrue);
    });

    test('clamps the goal before computing', () {
      expect(
        computeGoalProgress(
          recordingDurationMs: 0,
          goalMinutes: 5000,
        ).goalMinutes,
        24 * 60,
      );
      expect(
        computeGoalProgress(recordingDurationMs: 0, goalMinutes: 0).goalMinutes,
        1,
      );
    });

    test('sub-minute recording shows zero progress', () {
      final progress = computeGoalProgress(
        recordingDurationMs: 60 * 1000 - 1,
        goalMinutes: 1,
      );
      expect(progress.completedMinutes, 0);
      expect(progress.percent, 0);
      expect(progress.encouragement, GoalEncouragementTier.startNow);
    });

    test('minute count and percent can disagree at rounding boundaries', () {
      // 1 completed minute of a 24h goal renders "1 / 1440 min" but 0%.
      final progress = computeGoalProgress(
        recordingDurationMs: 60 * 1000,
        goalMinutes: 24 * 60,
      );
      expect(progress.completedMinutes, 1);
      expect(progress.percent, 0);
      expect(progress.encouragement, GoalEncouragementTier.startNow);
    });

    test('carries the raw duration it was computed from', () {
      const ms = 17 * 60 * 1000 + 12345;
      final progress = computeGoalProgress(
        recordingDurationMs: ms,
        goalMinutes: 20,
      );
      expect(progress.recordingDurationMs, ms);
      expect(progress.completedMinutes, 17);
      expect(progress.percent, 85);
      expect(progress.encouragement, GoalEncouragementTier.almostThere);
    });
  });
}
