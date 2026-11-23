/// Media card artwork thumbnail with file / network / cover fallbacks.
library;

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/utils/local_thumbnail.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:material_ui/material_ui.dart';

import '../../generative_media_cover.dart';

/// Thumbnail with file / network / cover-seed fallback chain.
class MediaCardThumbnail extends StatelessWidget {
  const MediaCardThumbnail({
    super.key,
    required this.file,
    this.networkUrl,
    required this.coverSeed,
    required this.isVideo,
    required this.cs,
    this.width,
  });

  /// Known layout width; skips measuring (keeps the thumbnail usable under
  /// intrinsic sizing such as [IntrinsicHeight]).
  final double? width;

  final File? file;
  final String? networkUrl;
  final String? coverSeed;
  final bool isVideo;
  final ColorScheme cs;

  static const _coverFit = BoxFit.cover;

  static const _unconstrainedDecodeWidth = 600;

  Widget _networkImage(String url, int decodeWidth) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: _coverFit,
      memCacheWidth: decodeWidth,
      placeholder: (context, _) => _loading(),
      errorWidget: (context, attemptedUrl, _) {
        final mqFallback = youtubeMqFallbackForCardUrl(attemptedUrl);
        if (mqFallback != null && mqFallback != attemptedUrl) {
          return _networkImage(mqFallback, decodeWidth);
        }
        return _fallback();
      },
    );
  }

  Widget _loading() {
    if (coverSeed != null && coverSeed!.isNotEmpty) {
      return GenerativeMediaCover(seed: coverSeed!, isVideo: isVideo);
    }
    return ColoredBox(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: cs.onSurfaceVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final knownWidth = width;
    if (knownWidth != null) {
      return _image(thumbnailCacheWidthFor(knownWidth));
    }
    return LayoutBuilder(
      builder: (context, constraints) => _image(
        constraints.hasBoundedWidth
            ? thumbnailCacheWidthFor(constraints.maxWidth)
            : _unconstrainedDecodeWidth,
      ),
    );
  }

  Widget _image(int decodeWidth) {
    if (file != null) {
      return Image.file(
        file!,
        fit: _coverFit,
        cacheWidth: decodeWidth,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return _loading();
        },
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    final url = networkUrl;
    if (url != null && url.isNotEmpty) {
      return _networkImage(url, decodeWidth);
    }
    return _fallback();
  }

  Widget _fallback() {
    if (coverSeed != null && coverSeed!.isNotEmpty) {
      return GenerativeMediaCover(seed: coverSeed!, isVideo: isVideo);
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return ColoredBox(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(
          isVideo ? EnjoyIcons.video : EnjoyIcons.audio,
          size: 28,
          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
