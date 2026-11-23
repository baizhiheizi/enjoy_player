/// Circular channel avatar with generative fallback (Discover UI).
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import 'package:enjoy_player/core/theme/generative_media_cover.dart';

class DiscoverChannelAvatar extends StatelessWidget {
  const DiscoverChannelAvatar({
    required this.displayName,
    required this.seed,
    required this.size,
    this.url,
    super.key,
  });

  final String? url;
  final String displayName;
  final String seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final accent = generativeAccentForSeed(seed);
    final initial = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : '?';

    Widget fallback() {
      return ColoredBox(
        color: accent.withValues(alpha: 0.22),
        child: Center(
          child: Text(
            initial,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.38,
            ),
          ),
        ),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                memCacheWidth: (size * 3).round(),
                errorWidget: (_, _, _) => fallback(),
                placeholder: (_, _) => fallback(),
              )
            : fallback(),
      ),
    );
  }
}
