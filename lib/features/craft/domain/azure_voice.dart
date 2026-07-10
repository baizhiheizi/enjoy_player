/// Azure Neural voice catalog + filter helper.
library;

import 'package:flutter/foundation.dart';

/// One Azure Neural TTS voice.
@immutable
class AzureVoice {
  const AzureVoice({
    required this.id,
    required this.label,
    required this.gender,
    required this.locale,
    required this.baseLang,
  });

  /// Full Azure voice id, e.g. `'en-US-JennyNeural'`.
  final String id;

  /// Display label, e.g. `'Jenny (US, Female)'`.
  final String label;

  /// `'male'` or `'female'`.
  final String gender;

  /// Locale tag, e.g. `'en-US'`.
  final String locale;

  /// Base language code, e.g. `'en'`.
  final String baseLang;
}

/// Static catalog of Azure Neural voices, ported from
/// `packages/ai/src/utils/azure/azure-voices.ts` in the Enjoy web app.
///
/// Filtered at runtime by [voicesForLanguage].
const List<AzureVoice> kAzureVoices = [
  // English (US)
  AzureVoice(
    id: 'en-US-JennyNeural',
    label: 'Jenny (US, Female)',
    gender: 'female',
    locale: 'en-US',
    baseLang: 'en',
  ),
  AzureVoice(
    id: 'en-US-GuyNeural',
    label: 'Guy (US, Male)',
    gender: 'male',
    locale: 'en-US',
    baseLang: 'en',
  ),
  AzureVoice(
    id: 'en-US-AriaNeural',
    label: 'Aria (US, Female)',
    gender: 'female',
    locale: 'en-US',
    baseLang: 'en',
  ),
  AzureVoice(
    id: 'en-US-DavisNeural',
    label: 'Davis (US, Male)',
    gender: 'male',
    locale: 'en-US',
    baseLang: 'en',
  ),
  // English (UK)
  AzureVoice(
    id: 'en-GB-SoniaNeural',
    label: 'Sonia (UK, Female)',
    gender: 'female',
    locale: 'en-GB',
    baseLang: 'en',
  ),
  AzureVoice(
    id: 'en-GB-RyanNeural',
    label: 'Ryan (UK, Male)',
    gender: 'male',
    locale: 'en-GB',
    baseLang: 'en',
  ),
  // Chinese (Simplified)
  AzureVoice(
    id: 'zh-CN-XiaoxiaoNeural',
    label: 'Xiaoxiao (CN, Female)',
    gender: 'female',
    locale: 'zh-CN',
    baseLang: 'zh',
  ),
  AzureVoice(
    id: 'zh-CN-YunxiNeural',
    label: 'Yunxi (CN, Male)',
    gender: 'male',
    locale: 'zh-CN',
    baseLang: 'zh',
  ),
  AzureVoice(
    id: 'zh-CN-XiaoyiNeural',
    label: 'Xiaoyi (CN, Female)',
    gender: 'female',
    locale: 'zh-CN',
    baseLang: 'zh',
  ),
  AzureVoice(
    id: 'zh-CN-YunjianNeural',
    label: 'Yunjian (CN, Male)',
    gender: 'male',
    locale: 'zh-CN',
    baseLang: 'zh',
  ),
  // Japanese
  AzureVoice(
    id: 'ja-JP-NanamiNeural',
    label: 'Nanami (JP, Female)',
    gender: 'female',
    locale: 'ja-JP',
    baseLang: 'ja',
  ),
  AzureVoice(
    id: 'ja-JP-KeitaNeural',
    label: 'Keita (JP, Male)',
    gender: 'male',
    locale: 'ja-JP',
    baseLang: 'ja',
  ),
  AzureVoice(
    id: 'ja-JP-AoiNeural',
    label: 'Aoi (JP, Female)',
    gender: 'female',
    locale: 'ja-JP',
    baseLang: 'ja',
  ),
  // Korean
  AzureVoice(
    id: 'ko-KR-SunHiNeural',
    label: 'Sun-Hi (KR, Female)',
    gender: 'female',
    locale: 'ko-KR',
    baseLang: 'ko',
  ),
  AzureVoice(
    id: 'ko-KR-InJoonNeural',
    label: 'In-Joon (KR, Male)',
    gender: 'male',
    locale: 'ko-KR',
    baseLang: 'ko',
  ),
  // Spanish (Spain)
  AzureVoice(
    id: 'es-ES-ElviraNeural',
    label: 'Elvira (ES, Female)',
    gender: 'female',
    locale: 'es-ES',
    baseLang: 'es',
  ),
  AzureVoice(
    id: 'es-ES-AlvaroNeural',
    label: 'Álvaro (ES, Male)',
    gender: 'male',
    locale: 'es-ES',
    baseLang: 'es',
  ),
  // Spanish (Mexico)
  AzureVoice(
    id: 'es-MX-DaliaNeural',
    label: 'Dalia (MX, Female)',
    gender: 'female',
    locale: 'es-MX',
    baseLang: 'es',
  ),
  AzureVoice(
    id: 'es-MX-JorgeNeural',
    label: 'Jorge (MX, Male)',
    gender: 'male',
    locale: 'es-MX',
    baseLang: 'es',
  ),
  // French (France)
  AzureVoice(
    id: 'fr-FR-DeniseNeural',
    label: 'Denise (FR, Female)',
    gender: 'female',
    locale: 'fr-FR',
    baseLang: 'fr',
  ),
  AzureVoice(
    id: 'fr-FR-HenriNeural',
    label: 'Henri (FR, Male)',
    gender: 'male',
    locale: 'fr-FR',
    baseLang: 'fr',
  ),
  // German
  AzureVoice(
    id: 'de-DE-KatjaNeural',
    label: 'Katja (DE, Female)',
    gender: 'female',
    locale: 'de-DE',
    baseLang: 'de',
  ),
  AzureVoice(
    id: 'de-DE-ConradNeural',
    label: 'Conrad (DE, Male)',
    gender: 'male',
    locale: 'de-DE',
    baseLang: 'de',
  ),
  // Italian
  AzureVoice(
    id: 'it-IT-ElsaNeural',
    label: 'Elsa (IT, Female)',
    gender: 'female',
    locale: 'it-IT',
    baseLang: 'it',
  ),
  AzureVoice(
    id: 'it-IT-DiegoNeural',
    label: 'Diego (IT, Male)',
    gender: 'male',
    locale: 'it-IT',
    baseLang: 'it',
  ),
  // Portuguese (Brazil)
  AzureVoice(
    id: 'pt-BR-FranciscaNeural',
    label: 'Francisca (BR, Female)',
    gender: 'female',
    locale: 'pt-BR',
    baseLang: 'pt',
  ),
  AzureVoice(
    id: 'pt-BR-AntonioNeural',
    label: 'Antonio (BR, Male)',
    gender: 'male',
    locale: 'pt-BR',
    baseLang: 'pt',
  ),
  // Russian
  AzureVoice(
    id: 'ru-RU-SvetlanaNeural',
    label: 'Svetlana (RU, Female)',
    gender: 'female',
    locale: 'ru-RU',
    baseLang: 'ru',
  ),
  AzureVoice(
    id: 'ru-RU-DmitryNeural',
    label: 'Dmitry (RU, Male)',
    gender: 'male',
    locale: 'ru-RU',
    baseLang: 'ru',
  ),
];

/// Returns voices whose [AzureVoice.baseLang] matches the given base code.
List<AzureVoice> voicesForLanguage(String baseLang) {
  final lower = baseLang.toLowerCase();
  return kAzureVoices.where((v) => v.baseLang == lower).toList();
}

/// Returns the default voice for a language (first female voice, or first voice).
AzureVoice? defaultVoiceForLanguage(String baseLang) {
  final voices = voicesForLanguage(baseLang);
  if (voices.isEmpty) return null;
  return voices.firstWhere(
    (v) => v.gender == 'female',
    orElse: () => voices.first,
  );
}
