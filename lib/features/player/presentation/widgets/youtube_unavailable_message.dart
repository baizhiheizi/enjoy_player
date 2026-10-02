/// Maps a YouTube unavailability reason onto its localized message variant
/// (specs/047 data-model Entity 1/Entity 3).
library;

import 'package:enjoy_player/core/platform/linux_platform_availability.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

String youtubeUnavailableMessage(
  AppLocalizations l10n,
  YouTubeUnavailableReason? reason,
) => switch (reason) {
  YouTubeUnavailableReason.runtimeMissing =>
    l10n.youtubeUnavailableRuntimeMissing,
  YouTubeUnavailableReason.runtimeInitFailed =>
    l10n.youtubeUnavailableRuntimeInitFailed,
  YouTubeUnavailableReason.disabledByBuild =>
    l10n.youtubeUnavailableDisabledByBuild,
  null => l10n.youtubeUnavailableOnDevice,
};
