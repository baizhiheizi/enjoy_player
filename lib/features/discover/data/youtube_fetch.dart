/// Shared HTTP settings for YouTube public endpoints (RSS + channel pages).
library;

import 'package:http/http.dart' as http;

abstract final class YoutubeFetch {
  /// Desktop Chrome UA — YouTube RSS and HTML often reject default `Dart/` clients.
  static const userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

  static const _rssHeaders = {
    'User-Agent': userAgent,
    'Accept': 'application/atom+xml, application/xml, text/xml, */*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  static const _htmlHeaders = {
    'User-Agent': userAgent,
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  static Future<http.Response> getRss(http.Client client, Uri uri) {
    return client.get(uri, headers: _rssHeaders);
  }

  static Future<http.Response> getHtml(http.Client client, Uri uri) {
    return client.get(uri, headers: _htmlHeaders);
  }
}
