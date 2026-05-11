import 'package:freezed_annotation/freezed_annotation.dart';

part 'translation_result.freezed.dart';

@freezed
abstract class TranslationResult with _$TranslationResult {
  const factory TranslationResult({
    required String translatedText,
    String? sourceLanguage,
    required String targetLanguage,
  }) = _TranslationResult;
}
