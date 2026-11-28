/// Shared base-URL trailing-slash normalization.
library;

/// Strips every trailing `/` from [url] so multi-slash input converges.
String trimTrailingSlashes(String url) {
  var s = url;
  while (s.endsWith('/')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}
