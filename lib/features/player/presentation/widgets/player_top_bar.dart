/// Duet player top bar (ADR-0091) — collapse + title/meta, the centered
/// Listen/Echo segmented control, and share/subtitles actions.
library;

import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/presentation/language_labels.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_collapse.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_tooltip_label.dart';
import 'package:enjoy_player/features/onboarding/domain/onboarding_tip_id.dart';
import 'package:enjoy_player/features/onboarding/presentation/onboarding_target.dart';
import 'package:enjoy_player/features/share_poster/presentation/share_practice_poster_button.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/presentation/subtitle_track_picker_sheet.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class PlayerTopBar extends ConsumerWidget {
  const PlayerTopBar({required this.mediaId, super.key});

  final String mediaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final chrome = ref.watch(playerControllerProvider.select(playbackChromeOf));
    final echo = ref.watch(echoModeProvider);
    final hasLines =
        ref.watch(transcriptHasLinesForMediaProvider(mediaId)).value ?? false;
    final collapseTooltip = hotkeyTooltipLabel(
      ref,
      'player.toggleExpand',
      l10n.hotkeysDescToggleExpand,
    );

    return Container(
      height: t.playerTopBarHeight,
      decoration: BoxDecoration(
        color: t.paper,
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: collapseTooltip,
            icon: const Icon(EnjoyIcons.chevronDown, size: 20),
            color: t.ink2,
            onPressed: () => unawaited(collapseExpandedPlayer(ref, context)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chrome?.mediaTitle ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.labelLarge?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: t.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _metaLine(context, chrome),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.labelSmall?.copyWith(fontSize: 12.5, color: t.ink3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _ModeSegmented(
            echoActive: echo.active,
            echoEnabled: hasLines,
            onListen: () {
              if (!echo.active) return;
              unawaited(ref.read(playerInteractionsProvider).toggleEcho());
            },
            onEcho: () {
              if (echo.active) return;
              Haptics.selection(context);
              unawaited(ref.read(playerInteractionsProvider).toggleEcho());
            },
            echoTipAction: echo.active || hasLines
                ? () {
                    Haptics.selection(context);
                    unawaited(
                      ref.read(playerInteractionsProvider).toggleEcho(),
                    );
                  }
                : null,
          ),
          const SizedBox(width: 16),
          _ShareAction(mediaId: mediaId, echoActive: echo.active),
          const SizedBox(width: 4),
          IconButton(
            tooltip: l10n.subtitles,
            icon: const Icon(EnjoyIcons.subtitles, size: 20),
            color: t.ink2,
            onPressed: () =>
                unawaited(showSubtitleTrackPicker(context, ref, mediaId)),
          ),
        ],
      ),
    );
  }

  String _metaLine(BuildContext context, PlaybackChrome? chrome) {
    if (chrome == null) return '';
    final l10n = AppLocalizations.of(context)!;
    final kind = chrome.mediaType == 'video'
        ? l10n.miniPlayerMediaVideo
        : l10n.miniPlayerMediaAudio;
    final duration = formatDurationHmsSeconds(chrome.durationSeconds);
    final language = _languageLabel(context, chrome.language);
    return [kind, duration, if (language != null) language].join(' · ');
  }

  String? _languageLabel(BuildContext context, String? tag) {
    if (tag == null || tag.isEmpty) return null;
    final getter = localizedLanguageLabelGetters[tag];
    final l10n = AppLocalizations.of(context)!;
    return getter != null ? getter(l10n) : tag;
  }
}

class _ModeSegmented extends StatelessWidget {
  const _ModeSegmented({
    required this.echoActive,
    required this.echoEnabled,
    required this.onListen,
    required this.onEcho,
    this.echoTipAction,
  });

  final bool echoActive;
  final bool echoEnabled;
  final VoidCallback onListen;
  final VoidCallback onEcho;

  /// Onboarding anchor for the Echo tip (echo affordance lives here now).
  final VoidCallback? echoTipAction;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;

    Widget option({
      required String label,
      required IconData icon,
      required bool selected,
      required bool enabled,
      required VoidCallback onTap,
      Widget? trailing,
      String? tooltip,
    }) {
      return Tooltip(
        message: tooltip ?? label,
        child: EnjoyPressable(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          pressedScale: 0.97,
          child: AnimatedContainer(
            duration: t.motionFast,
            curve: Curves.easeOutCubic,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: ShapeDecoration(
              color: selected ? t.paper : Colors.transparent,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              shadows: selected ? t.shadowLift : const [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: selected ? t.ink : (enabled ? t.ink2 : t.ink3),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: tt.labelMedium?.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? t.ink : (enabled ? t.ink2 : t.ink3),
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: ShapeDecoration(
        color: t.sunk,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(13),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          option(
            label: l10n.playerListenModeTitle,
            icon: EnjoyIcons.headphones,
            selected: !echoActive,
            enabled: true,
            onTap: onListen,
          ),
          const SizedBox(width: 2),
          OnboardingTarget(
            tipId: OnboardingTipId.playerEcho,
            onTargetAction: echoTipAction,
            child: option(
              label: l10n.echoMode,
              icon: EnjoyIcons.mic,
              selected: echoActive,
              enabled: echoEnabled || echoActive,
              onTap: onEcho,
              tooltip: l10n.hotkeysDescToggleEchoMode,
              trailing: const EnjoyKeycap(label: 'E'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareAction extends StatelessWidget {
  const _ShareAction({required this.mediaId, required this.echoActive});

  final String mediaId;
  final bool echoActive;

  @override
  Widget build(BuildContext context) {
    if (!echoActive) return const SizedBox.shrink();
    final t = EnjoyThemeTokens.of(context);
    return IconTheme(
      data: IconThemeData(size: 20, color: t.ink2),
      child: SharePracticePosterButton(mediaId: mediaId),
    );
  }
}
