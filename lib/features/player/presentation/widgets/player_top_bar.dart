/// Duet player top bar (ADR-0093, canvas v30) — collapse + title/meta, the
/// centered mode switch, then Share, the Subtitles chip and ⋯ More.
library;

import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/presentation/language_labels.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
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
import 'player_more_menu.dart';
import 'player_top_bar_chip.dart';
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

    final phone = MediaQuery.sizeOf(context).width < t.breakpointCompact;
    return Container(
      height: phone ? null : t.playerTopBarHeight,
      decoration: BoxDecoration(
        color: t.paper,
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      padding: EdgeInsets.fromLTRB(phone ? 6 : 10, 0, phone ? 8 : 14, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < t.breakpointCompact) {
            return _PhoneTopBar(
              mediaId: mediaId,
              chrome: chrome,
              echoActive: echo.active,
              echoEnabled: hasLines,
            );
          }
          final showShare = constraints.maxWidth >= 1100;
          final showSubtitleLabel = constraints.maxWidth >= 980;
          return Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      tooltip: collapseTooltip,
                      icon: const Icon(EnjoyIcons.chevronDown, size: 20),
                      color: t.ink2,
                      onPressed: () =>
                          unawaited(collapseExpandedPlayer(ref, context)),
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
                            _metaLine(context, ref, chrome),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.labelSmall?.copyWith(
                              fontSize: 12.5,
                              color: t.ink3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (showShare)
                      _ShareAction(
                        mediaId: mediaId,
                        echoActive: echo.active,
                        labeled: true,
                      ),
                    if (showShare) const SizedBox(width: 4),
                    _SubtitlesAction(
                      mediaId: mediaId,
                      showLabel: showSubtitleLabel,
                    ),
                    const SizedBox(width: 4),
                    _MoreAction(mediaId: mediaId),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _metaLine(
    BuildContext context,
    WidgetRef ref,
    PlaybackChrome? chrome,
  ) {
    if (chrome == null) return '';
    final l10n = AppLocalizations.of(context)!;
    final kind = chrome.mediaType == 'video'
        ? l10n.miniPlayerMediaVideo
        : l10n.miniPlayerMediaAudio;
    final duration = formatDurationHmsSeconds(chrome.durationSeconds);
    final language = languageEndonymLabel(chrome.language);
    final native = languageEndonymLabel(
      ref.read(appPreferencesCtrlProvider).valueOrNull?.effectiveNativeLanguage,
    );
    return [
      kind,
      duration,
      if (language != null) language,
      if (native != null && native != language) native,
    ].join(' · ');
  }
}

bool echoModeShortcutVisible() => isDesktop;

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
      required Color selectedFg,
      required VoidCallback onTap,
      Widget? trailing,
      String? tooltip,
    }) {
      final fg = selected ? selectedFg : (enabled ? t.ink2 : t.ink3);
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
            padding: const EdgeInsets.only(left: 12, right: 12),
            decoration: ShapeDecoration(
              color: selected ? t.raised : Colors.transparent,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              shadows: selected ? t.shadowLift : const [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: fg),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: tt.labelMedium?.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: fg,
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
            selectedFg: t.originalInk,
            onTap: onListen,
          ),
          const SizedBox(width: 2),
          OnboardingTarget(
            tipId: OnboardingTipId.playerEcho,
            onTargetAction: echoTipAction,
            child: option(
              label: l10n.playerEchoShort,
              icon: EnjoyIcons.mic,
              selected: echoActive,
              enabled: echoEnabled || echoActive,
              selectedFg: t.youInk,
              onTap: onEcho,
              tooltip: l10n.hotkeysDescToggleEchoMode,
              trailing: echoModeShortcutVisible()
                  ? const EnjoyKeycap(label: 'E')
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtitlesAction extends ConsumerStatefulWidget {
  const _SubtitlesAction({required this.mediaId, required this.showLabel});

  final String mediaId;
  final bool showLabel;

  @override
  ConsumerState<_SubtitlesAction> createState() => _SubtitlesActionState();
}

class _SubtitlesActionState extends ConsumerState<_SubtitlesAction> {
  bool _open = false;

  Future<void> _toggle() async {
    setState(() => _open = true);
    await showSubtitleTrackPicker(context, ref, widget.mediaId);
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PlayerTopBarChip(
      key: const ValueKey('player-top-bar-subtitles'),
      icon: EnjoyIcons.subtitles,
      label: l10n.subtitles,
      tooltip: l10n.subtitlesPanelTitle,
      showLabel: widget.showLabel,
      open: _open,
      onTap: _open ? null : () => unawaited(_toggle()),
    );
  }
}

class _MoreAction extends StatelessWidget {
  const _MoreAction({required this.mediaId});

  final String mediaId;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      key: const ValueKey('player-top-bar-more'),
      tooltip: l10n.playerMore,
      icon: const Icon(EnjoyIcons.more, size: 20),
      color: t.ink2,
      style: IconButton.styleFrom(
        fixedSize: const Size(40, 40),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(t.radiusControl),
        ),
      ),
      onPressed: () => openPlayerMoreMenu(context, mediaId),
    );
  }
}

class _ShareAction extends StatelessWidget {
  const _ShareAction({
    required this.mediaId,
    required this.echoActive,
    this.labeled = false,
  });

  final String mediaId;
  final bool echoActive;
  final bool labeled;

  @override
  Widget build(BuildContext context) {
    if (!echoActive) return const SizedBox.shrink();
    final t = EnjoyThemeTokens.of(context);
    return IconTheme(
      data: IconThemeData(size: 18, color: t.ink2),
      child: SharePracticePosterButton(mediaId: mediaId, labeled: labeled),
    );
  }
}

/// Phone top bar (the `Phone` board): row 1 = chevron · Listen / Echo ·
/// Share · CC; row 2 = title with the `Line n of m` caption.
class _PhoneTopBar extends ConsumerWidget {
  const _PhoneTopBar({
    required this.mediaId,
    required this.chrome,
    required this.echoActive,
    required this.echoEnabled,
  });

  final String mediaId;
  final PlaybackChrome? chrome;
  final bool echoActive;
  final bool echoEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l10n.hotkeysDescToggleExpand,
              icon: const Icon(EnjoyIcons.chevronDown, size: 20),
              color: t.ink2,
              onPressed: () => unawaited(collapseExpandedPlayer(ref, context)),
            ),
            const Spacer(),
            _ModeSegmented(
              echoActive: echoActive,
              echoEnabled: echoEnabled,
              onListen: () {
                if (!echoActive) return;
                unawaited(ref.read(playerInteractionsProvider).toggleEcho());
              },
              onEcho: () {
                if (echoActive) return;
                Haptics.selection(context);
                unawaited(ref.read(playerInteractionsProvider).toggleEcho());
              },
              echoTipAction: echoActive || echoEnabled
                  ? () {
                      Haptics.selection(context);
                      unawaited(
                        ref.read(playerInteractionsProvider).toggleEcho(),
                      );
                    }
                  : null,
            ),
            const Spacer(),
            _ShareAction(mediaId: mediaId, echoActive: echoActive),
            _SubtitlesAction(mediaId: mediaId, showLabel: false),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  chrome?.mediaTitle ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.labelLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: t.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
