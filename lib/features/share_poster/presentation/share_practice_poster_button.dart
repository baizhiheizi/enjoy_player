/// Player chrome entry for share-practice-poster when recordings exist.
library;

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/data/db/dexie_target_type_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/share_poster/presentation/practice_poster_preview_sheet.dart';
import 'package:enjoy_player/features/sync/application/recordings_for_target_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SharePracticePosterButton extends ConsumerWidget {
  const SharePracticePosterButton({
    super.key,
    required this.mediaId,
    this.iconColor,
    this.labeled = false,
  });

  final String mediaId;
  final Color? iconColor;

  /// Board-style labeled pill for the player top bar (icon + "Share").
  final bool labeled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sessionInfo = ref.watch(
      playerControllerProvider.select(
        (s) => s != null
            ? (mediaId: s.mediaId, dexieTargetType: s.dexieTargetType)
            : null,
      ),
    );
    final targetTypeAsync = ref.watch(dexieTargetTypeForMediaProvider(mediaId));

    final targetType = sessionInfo?.mediaId == mediaId
        ? sessionInfo!.dexieTargetType
        : targetTypeAsync.value;
    if (targetType == null) return const SizedBox.shrink();

    final recordingsAsync = ref.watch(
      recordingsForTargetProvider((targetType: targetType, targetId: mediaId)),
    );

    final hasRecordings = recordingsAsync.maybeWhen(
      data: (list) => list.isNotEmpty,
      orElse: () => false,
    );

    if (!hasRecordings) return const SizedBox.shrink();

    if (labeled) {
      final t = EnjoyThemeTokens.of(context);
      final tt = Theme.of(context).textTheme;
      return Tooltip(
        message: l10n.practicePosterShareTooltip,
        child: EnjoyPressable(
          onTap: () =>
              showPracticePosterPreviewSheet(context, ref, mediaId: mediaId),
          borderRadius: BorderRadius.circular(t.radiusControl),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(EnjoyIcons.share, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  l10n.practicePosterShareLabel,
                  style: tt.labelMedium?.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: t.ink2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return IconButton(
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(44, 44),
      ),
      tooltip: l10n.practicePosterShareTooltip,
      icon: Icon(EnjoyIcons.share, color: iconColor, size: 22),
      onPressed: () =>
          showPracticePosterPreviewSheet(context, ref, mediaId: mediaId),
    );
  }
}
