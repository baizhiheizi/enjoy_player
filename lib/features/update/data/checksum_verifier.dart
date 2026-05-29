/// SHA-256 verification for downloaded update artifacts.
library;

import 'dart:io';

import 'package:crypto/crypto.dart';

/// Returns true when [file] digest matches [expectedSha256Hex] (case-insensitive).
Future<bool> verifyFileSha256({
  required File file,
  required String expectedSha256Hex,
}) async {
  final expected = expectedSha256Hex.trim().toLowerCase();
  if (expected.isEmpty) return true;
  final digest = await sha256.bind(file.openRead()).first;
  return digest.toString() == expected;
}

/// Parses a manifest hex string; returns null when missing/invalid.
String? normalizeSha256Hex(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final hex = raw.trim().toLowerCase();
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(hex)) return null;
  return hex;
}

/// Convenience for tests.
String sha256HexOfBytes(List<int> bytes) =>
    sha256.convert(bytes).toString();
