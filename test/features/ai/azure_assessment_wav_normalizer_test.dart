import 'package:enjoy_player/features/ai/data/azure_assessment_wav_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('normalizeWavForAzureAssessment', () {
    test('returns false for empty input path', () async {
      expect(
        await normalizeWavForAzureAssessment(
          inputPath: '   ',
          outputWavPath: '/tmp/out.wav',
        ),
        isFalse,
      );
    });

    test('returns false when input file does not exist', () async {
      expect(
        await normalizeWavForAzureAssessment(
          inputPath: '/nonexistent/azure_input.wav',
          outputWavPath: '/tmp/azure_out.wav',
        ),
        isFalse,
      );
    });
  });

  group('tryCreateNormalizedAzureAssessmentWav', () {
    test('returns null when normalization fails', () async {
      final result = await tryCreateNormalizedAzureAssessmentWav(
        '/nonexistent/recording.wav',
      );
      expect(result, isNull);
    });
  });
}
