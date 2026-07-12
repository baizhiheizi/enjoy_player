import 'package:freezed_annotation/freezed_annotation.dart';

part 'translation_result.freezed.dart';
part 'translation_result.g.dart';

@freezed
abstract class TranslationResult with _$TranslationResult {
  const factory TranslationResult({
    required String translatedText,
    String? sourceLanguage,
    required String targetLanguage,
  }) = _TranslationResult;

  const TranslationResult._();

  factory TranslationResult.fromJson(Map<String, dynamic> json) =>
      _$TranslationResultFromJson(json);

  Map<String, dynamic> toJson() =>
      _$TranslationResultToJson(this as _TranslationResult);
}

// ignore_for_file: type=lint
