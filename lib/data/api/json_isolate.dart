/// JSON decode + camelCase conversion for use in a background isolate.
library;

import 'dart:convert';

import 'package:enjoy_player/data/api/case_conversion.dart';

Object? decodeJsonToCamel(String body) {
  final decoded = jsonDecode(body);
  return convertKeysToCamel(decoded);
}
