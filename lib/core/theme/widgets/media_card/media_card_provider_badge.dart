/// Provider badge label for [MediaCardRow] and [MediaCardTile].
library;

import 'package:enjoy_player/core/utils/youtube_video_identity.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Localized source label for [provider], or `null` when the card shows none.
String? resolveMediaCardProviderBadge(AppLocalizations l10n, String provider) {
  return switch (provider) {
    kProviderYoutube => l10n.youtubeBadge,
    'craft' => l10n.libraryProviderCraftBadge,
    _ => null,
  };
}
