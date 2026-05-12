// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AzurePronunciationAssessmentResult _$AzurePronunciationAssessmentResultFromJson(
  Map<String, dynamic> json,
) => AzurePronunciationAssessmentResult(
  recognitionStatus: json['RecognitionStatus'] as String,
  offset: (json['Offset'] as num).toInt(),
  duration: (json['Duration'] as num).toInt(),
  displayText: json['DisplayText'] as String,
  nBest:
      (json['NBest'] as List<dynamic>)
          .map((e) => AzureNBestResult.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$AzurePronunciationAssessmentResultToJson(
  AzurePronunciationAssessmentResult instance,
) => <String, dynamic>{
  'RecognitionStatus': instance.recognitionStatus,
  'Offset': instance.offset,
  'Duration': instance.duration,
  'DisplayText': instance.displayText,
  'NBest': instance.nBest,
};

AzureNBestResult _$AzureNBestResultFromJson(Map<String, dynamic> json) =>
    AzureNBestResult(
      confidence: (json['Confidence'] as num).toDouble(),
      lexical: json['Lexical'] as String,
      itn: json['ITN'] as String,
      maskedItn: json['MaskedITN'] as String,
      display: json['Display'] as String,
      pronunciationAssessment: AzurePronunciationAssessmentScores.fromJson(
        json['PronunciationAssessment'] as Map<String, dynamic>,
      ),
      words:
          (json['Words'] as List<dynamic>)
              .map(
                (e) => AzureWordAssessment.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );

Map<String, dynamic> _$AzureNBestResultToJson(AzureNBestResult instance) =>
    <String, dynamic>{
      'Confidence': instance.confidence,
      'Lexical': instance.lexical,
      'ITN': instance.itn,
      'MaskedITN': instance.maskedItn,
      'Display': instance.display,
      'PronunciationAssessment': instance.pronunciationAssessment,
      'Words': instance.words,
    };

AzurePronunciationAssessmentScores _$AzurePronunciationAssessmentScoresFromJson(
  Map<String, dynamic> json,
) => AzurePronunciationAssessmentScores(
  accuracyScore: (json['AccuracyScore'] as num).toDouble(),
  fluencyScore: (json['FluencyScore'] as num).toDouble(),
  completenessScore: (json['CompletenessScore'] as num).toDouble(),
  pronScore: (json['PronScore'] as num).toDouble(),
  prosodyScore: (json['ProsodyScore'] as num?)?.toDouble(),
);

Map<String, dynamic> _$AzurePronunciationAssessmentScoresToJson(
  AzurePronunciationAssessmentScores instance,
) => <String, dynamic>{
  'AccuracyScore': instance.accuracyScore,
  'FluencyScore': instance.fluencyScore,
  'CompletenessScore': instance.completenessScore,
  'PronScore': instance.pronScore,
  'ProsodyScore': instance.prosodyScore,
};

AzureWordAssessment _$AzureWordAssessmentFromJson(
  Map<String, dynamic> json,
) => AzureWordAssessment(
  word: json['Word'] as String,
  offset: (json['Offset'] as num).toInt(),
  duration: (json['Duration'] as num).toInt(),
  pronunciationAssessment: AzureWordPronunciationAssessment.fromJson(
    json['PronunciationAssessment'] as Map<String, dynamic>,
  ),
  syllables:
      (json['Syllables'] as List<dynamic>?)
          ?.map(
            (e) => AzureSyllableAssessment.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
  phonemes:
      (json['Phonemes'] as List<dynamic>?)
          ?.map(
            (e) => AzurePhonemeAssessment.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
);

Map<String, dynamic> _$AzureWordAssessmentToJson(
  AzureWordAssessment instance,
) => <String, dynamic>{
  'Word': instance.word,
  'Offset': instance.offset,
  'Duration': instance.duration,
  'PronunciationAssessment': instance.pronunciationAssessment,
  'Syllables': instance.syllables,
  'Phonemes': instance.phonemes,
};

AzureWordPronunciationAssessment _$AzureWordPronunciationAssessmentFromJson(
  Map<String, dynamic> json,
) => AzureWordPronunciationAssessment(
  accuracyScore: (json['AccuracyScore'] as num).toDouble(),
  errorType: json['ErrorType'] as String,
);

Map<String, dynamic> _$AzureWordPronunciationAssessmentToJson(
  AzureWordPronunciationAssessment instance,
) => <String, dynamic>{
  'AccuracyScore': instance.accuracyScore,
  'ErrorType': instance.errorType,
};

AzureSyllableAssessment _$AzureSyllableAssessmentFromJson(
  Map<String, dynamic> json,
) => AzureSyllableAssessment(
  syllable: json['Syllable'] as String,
  offset: (json['Offset'] as num).toInt(),
  duration: (json['Duration'] as num).toInt(),
  pronunciationAssessment: AzureSyllablePronunciationAssessment.fromJson(
    json['PronunciationAssessment'] as Map<String, dynamic>,
  ),
  phonemes:
      (json['Phonemes'] as List<dynamic>?)
          ?.map(
            (e) => AzurePhonemeAssessment.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
);

Map<String, dynamic> _$AzureSyllableAssessmentToJson(
  AzureSyllableAssessment instance,
) => <String, dynamic>{
  'Syllable': instance.syllable,
  'Offset': instance.offset,
  'Duration': instance.duration,
  'PronunciationAssessment': instance.pronunciationAssessment,
  'Phonemes': instance.phonemes,
};

AzureSyllablePronunciationAssessment
_$AzureSyllablePronunciationAssessmentFromJson(Map<String, dynamic> json) =>
    AzureSyllablePronunciationAssessment(
      accuracyScore: (json['AccuracyScore'] as num).toDouble(),
    );

Map<String, dynamic> _$AzureSyllablePronunciationAssessmentToJson(
  AzureSyllablePronunciationAssessment instance,
) => <String, dynamic>{'AccuracyScore': instance.accuracyScore};

AzurePhonemeAssessment _$AzurePhonemeAssessmentFromJson(
  Map<String, dynamic> json,
) => AzurePhonemeAssessment(
  phoneme: json['Phoneme'] as String,
  offset: (json['Offset'] as num).toInt(),
  duration: (json['Duration'] as num).toInt(),
  pronunciationAssessment: AzurePhonemePronunciationAssessment.fromJson(
    json['PronunciationAssessment'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$AzurePhonemeAssessmentToJson(
  AzurePhonemeAssessment instance,
) => <String, dynamic>{
  'Phoneme': instance.phoneme,
  'Offset': instance.offset,
  'Duration': instance.duration,
  'PronunciationAssessment': instance.pronunciationAssessment,
};

AzurePhonemePronunciationAssessment
_$AzurePhonemePronunciationAssessmentFromJson(Map<String, dynamic> json) =>
    AzurePhonemePronunciationAssessment(
      accuracyScore: (json['AccuracyScore'] as num).toDouble(),
      nBestPhonemes:
          (json['NBestPhonemes'] as List<dynamic>?)
              ?.map(
                (e) => AzureNBestPhoneme.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );

Map<String, dynamic> _$AzurePhonemePronunciationAssessmentToJson(
  AzurePhonemePronunciationAssessment instance,
) => <String, dynamic>{
  'AccuracyScore': instance.accuracyScore,
  'NBestPhonemes': instance.nBestPhonemes,
};

AzureNBestPhoneme _$AzureNBestPhonemeFromJson(Map<String, dynamic> json) =>
    AzureNBestPhoneme(
      phoneme: json['Phoneme'] as String,
      score: (json['Score'] as num).toDouble(),
    );

Map<String, dynamic> _$AzureNBestPhonemeToJson(AzureNBestPhoneme instance) =>
    <String, dynamic>{'Phoneme': instance.phoneme, 'Score': instance.score};
