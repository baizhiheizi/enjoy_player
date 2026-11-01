/// Recording-mode controls row for the Duet player dock (ADR-0093).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_dock_primitives.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/transport_volume_button.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Cancel pill (with the desktop `Esc` keycap) and the stop button.
class DockRecordingControls extends StatelessWidget {
  const DockRecordingControls({
    super.key,
    required this.mediaId,
    required this.phone,
    required this.showLineMeta,
    required this.playbackRate,
    required this.onSpeed,
    required this.onCancel,
    required this.onStop,
  });

  final String mediaId;
  final bool phone;
  final bool showLineMeta;
  final double playbackRate;
  final VoidCallback onSpeed;
  final VoidCallback onCancel;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final stopSize = phone ? 48.0 : 62.0;
    final group = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 40),
        Container(
          padding: EdgeInsets.all(phone ? 4 : 5),
          decoration: ShapeDecoration(
            color: t.sunk,
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: l10n.asrLongMediaConfirmCancel,
                child: EnjoyPressable(
                  onTap: onCancel,
                  borderRadius: BorderRadius.circular(t.radiusFull),
                  pressedScale: 0.96,
                  child: Container(
                    width: isDesktop ? 150 : null,
                    height: phone ? 48 : 52,
                    padding: const EdgeInsets.only(left: 8, right: 12),
                    decoration: ShapeDecoration(
                      color: t.paper,
                      shape: const StadiumBorder(),
                      shadows: t.shadowLift,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: t.sunk,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            EnjoyIcons.close,
                            size: 14,
                            color: t.ink2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            l10n.asrLongMediaConfirmCancel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: t.ink2,
                                ),
                          ),
                        ),
                        if (isDesktop) ...[
                          const SizedBox(width: 6),
                          const EnjoyKeycap(label: 'Esc'),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: l10n.shadowRecordingStop,
                child: Semantics(
                  label: l10n.shadowRecordingStop,
                  button: true,
                  child: EnjoyPressable(
                    onTap: onStop,
                    borderRadius: BorderRadius.circular(stopSize / 2),
                    pressedScale: 0.94,
                    child: SizedBox(
                      width: stopSize,
                      height: stopSize,
                      child: Center(
                        child: DockRecordRing(
                          diskSize: stopSize - (phone ? 4 : 12),
                          dotShape: DockRecordDotShape.stopSquare,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
    if (phone) {
      return Center(child: group);
    }
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: DockReadout(
                    mediaId: mediaId,
                    recording: true,
                    showHint: showLineMeta,
                  ),
                ),
              ],
            ),
          ),
          group,
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DockSpeedButton(rate: playbackRate, onOpen: onSpeed),
                const SizedBox(width: 6),
                const TransportVolumeButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
