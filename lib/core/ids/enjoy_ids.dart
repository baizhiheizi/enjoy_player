/// Deterministic UUID v5 helpers aligned with weapp
/// [apps/web/src/db/id-generator.ts].
library;

import 'package:uuid/uuid.dart';

/// RFC 4122 URL namespace (same as web `UUID_NAMESPACE`).
const String enjoyUuidNamespaceUrl = '6ba7b811-9dad-11d1-80b4-00c04fd430c8';

// ignore: prefer_const_constructors — Uuid() has no const constructor in uuid ^4.5
final Uuid _uuid = Uuid();

String enjoyVideoId({String provider = 'user', required String vid}) =>
    _uuid.v5(enjoyUuidNamespaceUrl, 'video:$provider:$vid');

String enjoyAudioId({String provider = 'user', required String aid}) =>
    _uuid.v5(enjoyUuidNamespaceUrl, 'audio:$provider:$aid');

String enjoyTranscriptId({
  required String targetType,
  required String targetId,
  required String language,
  required String source,
}) =>
    _uuid.v5(
      enjoyUuidNamespaceUrl,
      'transcript:$targetType:$targetId:$language:$source',
    );
