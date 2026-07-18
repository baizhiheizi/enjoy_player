/// Deterministic UUID v5 helpers aligned with weapp
/// [apps/web/src/db/id-generator.ts].
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// RFC 4122 URL namespace (same as web `UUID_NAMESPACE`).
const String enjoyUuidNamespaceUrl = '6ba7b811-9dad-11d1-80b4-00c04fd430c8';

// ignore: prefer_const_constructors — Uuid() has no const constructor in uuid ^4.5
final Uuid _uuid = Uuid();

String enjoyVideoId({String provider = 'user', required String vid}) =>
    _uuid.v5(enjoyUuidNamespaceUrl, 'video:$provider:$vid');

String enjoyAudioId({String provider = 'user', required String aid}) =>
    _uuid.v5(enjoyUuidNamespaceUrl, 'audio:$provider:$aid');

/// Same as web `hashString` in [apps/web/src/db/id-generator.ts].
String enjoySha256HexOfString(String input) =>
    sha256.convert(utf8.encode(input)).toString();

/// Web `generateLocalAudioAid` — scoped `aid` so the same bytes + same user
/// always map to one remote row.
String enjoyLocalAudioAid({
  required String contentHashHex,
  required String userId,
}) => enjoySha256HexOfString('$contentHashHex:$userId');

/// Web `generateLocalVideoVid` — content-addressed (no userId salt).
///
/// [userId] is ignored; kept optional for call-site compatibility.
String enjoyLocalVideoVid({
  required String contentHashHex,
  String? userId,
}) => contentHashHex;

String enjoyTranscriptId({
  required String targetType,
  required String targetId,
  required String language,
  required String source,
}) => _uuid.v5(
  enjoyUuidNamespaceUrl,
  'transcript:$targetType:$targetId:$language:$source',
);

/// Web `generateVocabularyItemId`.
String enjoyVocabularyItemId({
  required String normalizedWord,
  required String language,
  required String targetLanguage,
}) => _uuid.v5(
  enjoyUuidNamespaceUrl,
  'vocabulary-item:$normalizedWord:$language:$targetLanguage',
);

/// Web `generateVocabularyContextId`.
///
/// [stableLocatorJson] must match web `JSON.stringify(locator, sortedKeys)`.
String enjoyVocabularyContextId({
  required String vocabularyItemId,
  required String sourceType, // Video|Audio|Ebook
  required String sourceId,
  required String text,
  required String stableLocatorJson,
}) => _uuid.v5(
  enjoyUuidNamespaceUrl,
  'vocabulary-context:$vocabularyItemId:$sourceType:$sourceId:'
  '${text.length > 100 ? text.substring(0, 100) : text}:$stableLocatorJson',
);
