import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

/// Root JSON from [SpeechServiceResponse_JsonResult] (Azure Speech SDK).
@JsonSerializable()
final class AzurePronunciationAssessmentResult {
  const AzurePronunciationAssessmentResult({
    required this.recognitionStatus,
    required this.offset,
    required this.duration,
    required this.displayText,
    required this.nBest,
  });

  @JsonKey(name: 'RecognitionStatus')
  final String recognitionStatus;

  @JsonKey(name: 'Offset')
  final int offset;

  @JsonKey(name: 'Duration')
  final int duration;

  @JsonKey(name: 'DisplayText')
  final String displayText;

  @JsonKey(name: 'NBest')
  final List<AzureNBestResult> nBest;

  factory AzurePronunciationAssessmentResult.fromJson(
    Map<String, dynamic> json,
  ) => _$AzurePronunciationAssessmentResultFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AzurePronunciationAssessmentResultToJson(this);

  /// Convenience: first hypothesis scores (null if [nBest] empty).
  AzurePronunciationAssessmentScores? get primaryScores =>
      nBest.isEmpty ? null : nBest.first.pronunciationAssessment;
}

@JsonSerializable()
final class AzureNBestResult {
  const AzureNBestResult({
    required this.confidence,
    required this.lexical,
    required this.itn,
    required this.maskedItn,
    required this.display,
    required this.pronunciationAssessment,
    required this.words,
  });

  @JsonKey(name: 'Confidence')
  final double confidence;

  @JsonKey(name: 'Lexical')
  final String lexical;

  @JsonKey(name: 'ITN')
  final String itn;

  @JsonKey(name: 'MaskedITN')
  final String maskedItn;

  @JsonKey(name: 'Display')
  final String display;

  @JsonKey(name: 'PronunciationAssessment')
  final AzurePronunciationAssessmentScores pronunciationAssessment;

  @JsonKey(name: 'Words')
  final List<AzureWordAssessment> words;

  factory AzureNBestResult.fromJson(Map<String, dynamic> json) =>
      _$AzureNBestResultFromJson(json);

  Map<String, dynamic> toJson() => _$AzureNBestResultToJson(this);
}

@JsonSerializable()
final class AzurePronunciationAssessmentScores {
  const AzurePronunciationAssessmentScores({
    required this.accuracyScore,
    required this.fluencyScore,
    required this.completenessScore,
    required this.pronScore,
    this.prosodyScore,
  });

  @JsonKey(name: 'AccuracyScore')
  final double accuracyScore;

  @JsonKey(name: 'FluencyScore')
  final double fluencyScore;

  @JsonKey(name: 'CompletenessScore')
  final double completenessScore;

  @JsonKey(name: 'PronScore')
  final double pronScore;

  @JsonKey(name: 'ProsodyScore')
  final double? prosodyScore;

  factory AzurePronunciationAssessmentScores.fromJson(
    Map<String, dynamic> json,
  ) => _$AzurePronunciationAssessmentScoresFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AzurePronunciationAssessmentScoresToJson(this);
}

@JsonSerializable()
final class AzureWordAssessment {
  const AzureWordAssessment({
    required this.word,
    required this.offset,
    required this.duration,
    required this.pronunciationAssessment,
    this.syllables,
    this.phonemes,
  });

  @JsonKey(name: 'Word')
  final String word;

  @JsonKey(name: 'Offset')
  final int offset;

  @JsonKey(name: 'Duration')
  final int duration;

  @JsonKey(name: 'PronunciationAssessment')
  final AzureWordPronunciationAssessment pronunciationAssessment;

  @JsonKey(name: 'Syllables')
  final List<AzureSyllableAssessment>? syllables;

  @JsonKey(name: 'Phonemes')
  final List<AzurePhonemeAssessment>? phonemes;

  factory AzureWordAssessment.fromJson(Map<String, dynamic> json) =>
      _$AzureWordAssessmentFromJson(json);

  Map<String, dynamic> toJson() => _$AzureWordAssessmentToJson(this);
}

@JsonSerializable()
final class AzureWordPronunciationAssessment {
  const AzureWordPronunciationAssessment({
    required this.accuracyScore,
    required this.errorType,
  });

  @JsonKey(name: 'AccuracyScore')
  final double accuracyScore;

  @JsonKey(name: 'ErrorType')
  final String errorType;

  factory AzureWordPronunciationAssessment.fromJson(
    Map<String, dynamic> json,
  ) => _$AzureWordPronunciationAssessmentFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AzureWordPronunciationAssessmentToJson(this);
}

@JsonSerializable()
final class AzureSyllableAssessment {
  const AzureSyllableAssessment({
    required this.syllable,
    required this.offset,
    required this.duration,
    required this.pronunciationAssessment,
    this.phonemes,
  });

  @JsonKey(name: 'Syllable')
  final String syllable;

  @JsonKey(name: 'Offset')
  final int offset;

  @JsonKey(name: 'Duration')
  final int duration;

  @JsonKey(name: 'PronunciationAssessment')
  final AzureSyllablePronunciationAssessment pronunciationAssessment;

  @JsonKey(name: 'Phonemes')
  final List<AzurePhonemeAssessment>? phonemes;

  factory AzureSyllableAssessment.fromJson(Map<String, dynamic> json) =>
      _$AzureSyllableAssessmentFromJson(json);

  Map<String, dynamic> toJson() => _$AzureSyllableAssessmentToJson(this);
}

@JsonSerializable()
final class AzureSyllablePronunciationAssessment {
  const AzureSyllablePronunciationAssessment({required this.accuracyScore});

  @JsonKey(name: 'AccuracyScore')
  final double accuracyScore;

  factory AzureSyllablePronunciationAssessment.fromJson(
    Map<String, dynamic> json,
  ) => _$AzureSyllablePronunciationAssessmentFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AzureSyllablePronunciationAssessmentToJson(this);
}

@JsonSerializable()
final class AzurePhonemeAssessment {
  const AzurePhonemeAssessment({
    required this.phoneme,
    required this.offset,
    required this.duration,
    required this.pronunciationAssessment,
  });

  @JsonKey(name: 'Phoneme')
  final String phoneme;

  @JsonKey(name: 'Offset')
  final int offset;

  @JsonKey(name: 'Duration')
  final int duration;

  @JsonKey(name: 'PronunciationAssessment')
  final AzurePhonemePronunciationAssessment pronunciationAssessment;

  factory AzurePhonemeAssessment.fromJson(Map<String, dynamic> json) =>
      _$AzurePhonemeAssessmentFromJson(json);

  Map<String, dynamic> toJson() => _$AzurePhonemeAssessmentToJson(this);
}

@JsonSerializable()
final class AzurePhonemePronunciationAssessment {
  const AzurePhonemePronunciationAssessment({
    required this.accuracyScore,
    this.nBestPhonemes,
  });

  @JsonKey(name: 'AccuracyScore')
  final double accuracyScore;

  @JsonKey(name: 'NBestPhonemes')
  final List<AzureNBestPhoneme>? nBestPhonemes;

  factory AzurePhonemePronunciationAssessment.fromJson(
    Map<String, dynamic> json,
  ) => _$AzurePhonemePronunciationAssessmentFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AzurePhonemePronunciationAssessmentToJson(this);
}

@JsonSerializable()
final class AzureNBestPhoneme {
  const AzureNBestPhoneme({required this.phoneme, required this.score});

  @JsonKey(name: 'Phoneme')
  final String phoneme;

  @JsonKey(name: 'Score')
  final double score;

  factory AzureNBestPhoneme.fromJson(Map<String, dynamic> json) =>
      _$AzureNBestPhonemeFromJson(json);

  Map<String, dynamic> toJson() => _$AzureNBestPhonemeToJson(this);
}
