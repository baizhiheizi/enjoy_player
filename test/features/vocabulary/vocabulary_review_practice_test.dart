import 'package:enjoy_player/features/vocabulary/domain/vocabulary_review_practice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReviewPracticePhaseX', () {
    group('isClip', () {
      test('true for clipOpening', () {
        expect(ReviewPracticePhase.clipOpening.isClip, isTrue);
      });

      test('true for clipReady', () {
        expect(ReviewPracticePhase.clipReady.isClip, isTrue);
      });

      test('false for none', () {
        expect(ReviewPracticePhase.none.isClip, isFalse);
      });

      test('false for echo', () {
        expect(ReviewPracticePhase.echo.isClip, isFalse);
      });
    });

    group('overlayOpen', () {
      test('false for none', () {
        expect(ReviewPracticePhase.none.overlayOpen, isFalse);
      });

      test('true for clipOpening', () {
        expect(ReviewPracticePhase.clipOpening.overlayOpen, isTrue);
      });

      test('true for clipReady', () {
        expect(ReviewPracticePhase.clipReady.overlayOpen, isTrue);
      });

      test('true for echo', () {
        expect(ReviewPracticePhase.echo.overlayOpen, isTrue);
      });
    });

    group('claimsVideoSurface', () {
      test('true only for clipReady', () {
        expect(ReviewPracticePhase.clipReady.claimsVideoSurface, isTrue);
      });

      test('false for clipOpening', () {
        expect(ReviewPracticePhase.clipOpening.claimsVideoSurface, isFalse);
      });

      test('false for none', () {
        expect(ReviewPracticePhase.none.claimsVideoSurface, isFalse);
      });

      test('false for echo', () {
        expect(ReviewPracticePhase.echo.claimsVideoSurface, isFalse);
      });
    });

    group('asMode', () {
      test('none maps to ReviewPracticeMode.none', () {
        expect(ReviewPracticePhase.none.asMode, ReviewPracticeMode.none);
      });

      test('clipOpening maps to ReviewPracticeMode.clip', () {
        expect(ReviewPracticePhase.clipOpening.asMode, ReviewPracticeMode.clip);
      });

      test('clipReady maps to ReviewPracticeMode.clip', () {
        expect(ReviewPracticePhase.clipReady.asMode, ReviewPracticeMode.clip);
      });

      test('echo maps to ReviewPracticeMode.echo', () {
        expect(ReviewPracticePhase.echo.asMode, ReviewPracticeMode.echo);
      });
    });
  });

  group('ReviewPracticeModeX.toPhase', () {
    test('none maps to ReviewPracticePhase.none', () {
      expect(ReviewPracticeMode.none.toPhase(), ReviewPracticePhase.none);
    });

    test('clip maps to ReviewPracticePhase.clipReady', () {
      expect(ReviewPracticeMode.clip.toPhase(), ReviewPracticePhase.clipReady);
    });

    test('echo maps to ReviewPracticePhase.echo', () {
      expect(ReviewPracticeMode.echo.toPhase(), ReviewPracticePhase.echo);
    });
  });

  group('round-trip mode → phase → mode', () {
    test('none round-trips', () {
      expect(ReviewPracticeMode.none.toPhase().asMode, ReviewPracticeMode.none);
    });

    test('clip round-trips', () {
      expect(ReviewPracticeMode.clip.toPhase().asMode, ReviewPracticeMode.clip);
    });

    test('echo round-trips', () {
      expect(ReviewPracticeMode.echo.toPhase().asMode, ReviewPracticeMode.echo);
    });
  });
}
