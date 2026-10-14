/// The player's ⋯ More menu (Duet v30): the transcript actions and the
/// keyboard shortcuts cheatsheet, anchored under the top bar's More button.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_help_dialog.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_actions.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const double _menuWidth = 284;
const double _menuTop = 56;
const double _menuRight = 14;

/// Opens the More menu as a [PopupRoute] so a video surface parks under it.
/// The chosen action runs against [context] once the menu has closed.
Future<void> showPlayerMoreMenu(BuildContext context, String mediaId) async {
  final choice = await Navigator.of(
    context,
    rootNavigator: true,
  ).push(_PlayerMoreMenuRoute(mediaId: mediaId));
  if (choice == null || !context.mounted) return;
  await choice(context);
}

/// What a More-menu row does once the menu has closed.
typedef PlayerMenuChoice = Future<void> Function(BuildContext context);

class _PlayerMoreMenuRoute extends PopupRoute<PlayerMenuChoice> {
  _PlayerMoreMenuRoute({required this.mediaId});

  final String mediaId;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => 'More';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 140);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 100);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: _menuTop, right: _menuRight),
        child: PlayerMoreMenuPanel(
          mediaId: mediaId,
          onChoose: (choice) => Navigator.of(context).pop(choice),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, -0.02),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class PlayerMoreMenuPanel extends ConsumerWidget {
  const PlayerMoreMenuPanel({
    required this.mediaId,
    required this.onChoose,
    super.key,
  });

  final String mediaId;
  final ValueChanged<PlayerMenuChoice> onChoose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final actions = watchTranscriptActions(ref, l10n, mediaId);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.playerMore,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: _menuWidth,
          padding: const EdgeInsets.all(6),
          decoration: ShapeDecoration(
            color: t.raised,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: t.line),
            ),
            shadows: t.shadowFloat,
          ),
          child: FocusTraversalGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: EnjoyOverline(l10n.playerMoreTranscriptSection),
                ),
                for (final (i, action) in actions.indexed)
                  PlayerMenuRow(
                    key: action.key,
                    label: action.label,
                    autofocus: i == 0,
                    onTap: () => onChoose(action.run),
                  ),
                const _MenuDivider(),
                PlayerMenuRow(
                  key: const ValueKey('player-more-shortcuts'),
                  label: l10n.playerMoreKeyboardShortcuts,
                  trailing: const EnjoyKeycap(label: '?'),
                  onTap: () => onChoose(showHotkeysHelpDialog),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerMenuRow extends StatelessWidget {
  const PlayerMenuRow({
    required this.label,
    required this.onTap,
    this.trailing,
    this.autofocus = false,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return EnjoyPressable(
      onTap: onTap,
      autofocus: autofocus,
      borderRadius: BorderRadius.circular(10),
      pressedScale: 1,
      washColor: t.sunk,
      semanticsLabel: label,
      child: SizedBox(
        height: 40,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 14, color: t.ink),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: t.line,
    );
  }
}

/// Fire-and-forget [showPlayerMoreMenu] for tap handlers.
void openPlayerMoreMenu(BuildContext context, String mediaId) =>
    unawaited(showPlayerMoreMenu(context, mediaId));
