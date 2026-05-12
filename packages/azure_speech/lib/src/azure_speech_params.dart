import 'package:meta/meta.dart';

/// Parameters for a single pronunciation assessment call (token-based auth).
@immutable
final class AzurePronunciationAssessmentParams {
  const AzurePronunciationAssessmentParams({
    required this.audioPath,
    required this.referenceText,
    required this.language,
    required this.token,
    required this.region,
    this.phonemeAlphabet = AzurePhonemeAlphabet.ipa,
    this.granularity = AzurePronunciationGranularity.phoneme,
    this.enableProsody = true,
    this.enableMiscue = true,
    this.nbestPhonemeCount = 1,
  });

  final String audioPath;
  final String referenceText;
  final String language;
  final String token;
  final String region;
  final AzurePhonemeAlphabet phonemeAlphabet;
  final AzurePronunciationGranularity granularity;
  final bool enableProsody;
  final bool enableMiscue;
  final int nbestPhonemeCount;

  Map<String, Object?> toMap() => <String, Object?>{
    'audioPath': audioPath,
    'referenceText': referenceText,
    'language': language,
    'token': token,
    'region': region,
    'phonemeAlphabet': switch (phonemeAlphabet) {
      AzurePhonemeAlphabet.ipa => 'IPA',
      AzurePhonemeAlphabet.sapi => 'SAPI',
    },
    'granularity': switch (granularity) {
      AzurePronunciationGranularity.phoneme => 'Phoneme',
      AzurePronunciationGranularity.word => 'Word',
      AzurePronunciationGranularity.fullText => 'FullText',
    },
    'enableProsody': enableProsody,
    'enableMiscue': enableMiscue,
    'nbestPhonemeCount': nbestPhonemeCount,
  };
}

enum AzurePhonemeAlphabet { ipa, sapi }

enum AzurePronunciationGranularity { phoneme, word, fullText }
