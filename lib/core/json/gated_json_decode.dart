/// JSON decode that leaves the UI isolate for large payloads.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Payloads longer than this many UTF-16 code units ([String.length], not
/// UTF-8 bytes) are decoded in a background isolate.
///
/// The unit is code units because a UTF-8 byte count would need
/// [utf8.encode] to copy the whole payload just for the check; CJK content
/// runs up to 3 UTF-8 bytes per code unit, so the inline path can see up to
/// 3x this size in bytes.
const int kGatedJsonDecodeChars = 8 * 1024;

/// Decodes [body] with [decode] (plain [jsonDecode] by default), hopping to a
/// background isolate via [compute] when the payload exceeds
/// [kGatedJsonDecodeChars]. Decoder exceptions propagate unchanged on both
/// paths.
Future<Object?> decodeJsonGated(
  String body, {
  Object? Function(String body)? decode,
}) {
  final decoder = decode ?? jsonDecode;
  if (body.length <= kGatedJsonDecodeChars) {
    return Future<Object?>.value(decoder(body));
  }
  return compute(decoder, body, debugLabel: 'gated-json-decode');
}
