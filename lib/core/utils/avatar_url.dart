/// Avatar URL helpers — Flutter raster decoders cannot load SVG responses.
library;

/// Returns a URL suitable for [Image.network] / [CachedNetworkImage].
///
/// Dicebear defaults to SVG (`…/svg?seed=…`); this rewrites those to PNG.
String? rasterAvatarUrl(String? url) {
  if (url == null || url.isEmpty) return null;

  final uri = Uri.tryParse(url);
  if (uri == null) return url;

  if (uri.host == 'api.dicebear.com' && uri.path.endsWith('/svg')) {
    final pngPath = '${uri.path.substring(0, uri.path.length - 3)}png';
    return uri.replace(path: pngPath).toString();
  }

  return url;
}
