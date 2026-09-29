/// JSON decode that leaves the UI isolate for large payloads.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Payloads longer than this are decoded in a background isolate.
const int kGatedJsonDecodeBytes = 8 * 1024;

/// Decodes [body] with [decode] (plain [jsonDecode] by default), hopping to a
/// background isolate via [compute] when the payload exceeds
/// [kGatedJsonDecodeBytes]. Decoder exceptions propagate unchanged on both
/// paths.
Future<Object?> decodeJsonGated(
  String body, {
  Object? Function(String body)? decode,
}) {
  final decoder = decode ?? jsonDecode;
  if (body.length <= kGatedJsonDecodeBytes) {
    return Future<Object?>.value(decoder(body));
  }
  return compute(decoder, body, debugLabel: 'gated-json-decode');
}
