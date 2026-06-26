/// PKCE helpers for OAuth web fallback (RFC 7636).
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PkcePair {
  const PkcePair({required this.verifier, required this.challenge});

  final String verifier;
  final String challenge;
}

const _pkceCharset =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

/// Generates a PKCE verifier/challenge pair (S256).
PkcePair generatePkcePair({Random? random}) {
  final rng = random ?? Random.secure();
  final verifier = List.generate(
    64,
    (_) => _pkceCharset[rng.nextInt(_pkceCharset.length)],
  ).join();
  final digest = sha256.convert(utf8.encode(verifier));
  final challenge = base64Url.encode(digest.bytes).replaceAll('=', '');
  return PkcePair(verifier: verifier, challenge: challenge);
}

/// Random `state` for CSRF protection on authorize redirect.
String generateOAuthState({Random? random}) {
  final rng = random ?? Random.secure();
  return List.generate(
    32,
    (_) => _pkceCharset[rng.nextInt(_pkceCharset.length)],
  ).join();
}
