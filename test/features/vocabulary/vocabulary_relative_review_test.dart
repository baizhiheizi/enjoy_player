import 'package:enjoy_player/features/vocabulary/domain/vocabulary_relative_review.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2024, 6, 15, 14, 30);
  final todayMorning = DateTime(2024, 6, 15, 1, 0);
  final yesterday = DateTime(2024, 6, 14, 23, 0);
  final tomorrow = DateTime(2024, 6, 16, 0, 0);
  final inThreeDays = DateTime(2024, 6, 18, 9, 0);

  group('relativeNextReviewLabel', () {
    test('overdue when nextReviewAt is before today', () {
      expect(
        relativeNextReviewLabel(nextReviewAt: yesterday, now: today),
        isA<RelativeNextReviewOverdue>(),
      );
    });

    test('today when same local calendar day', () {
      expect(
        relativeNextReviewLabel(nextReviewAt: todayMorning, now: today),
        isA<RelativeNextReviewToday>(),
      );
      expect(
        relativeNextReviewLabel(nextReviewAt: today, now: todayMorning),
        isA<RelativeNextReviewToday>(),
      );
    });

    test('tomorrow when next local day', () {
      expect(
        relativeNextReviewLabel(nextReviewAt: tomorrow, now: today),
        isA<RelativeNextReviewTomorrow>(),
      );
    });

    test('inDays for two or more days ahead', () {
      expect(
        relativeNextReviewLabel(nextReviewAt: inThreeDays, now: today),
        const RelativeNextReviewInDays(3),
      );
      expect(
        relativeNextReviewLabel(
          nextReviewAt: DateTime(2024, 6, 17),
          now: today,
        ),
        const RelativeNextReviewInDays(2),
      );
    });

    test('uses local date of UTC timestamps', () {
      final nowLocal = DateTime(2024, 6, 15, 12);
      final nextUtc = DateTime.utc(2024, 6, 16, 0, 0);
      final label = relativeNextReviewLabel(
        nextReviewAt: nextUtc,
        now: nowLocal,
      );
      final expectedDays = DateTime(
        nextUtc.toLocal().year,
        nextUtc.toLocal().month,
        nextUtc.toLocal().day,
      ).difference(DateTime(2024, 6, 15)).inDays;

      if (expectedDays < 0) {
        expect(label, isA<RelativeNextReviewOverdue>());
      } else if (expectedDays == 0) {
        expect(label, isA<RelativeNextReviewToday>());
      } else if (expectedDays == 1) {
        expect(label, isA<RelativeNextReviewTomorrow>());
      } else {
        expect(label, RelativeNextReviewInDays(expectedDays));
      }
    });
  });
}
