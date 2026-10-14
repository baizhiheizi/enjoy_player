/// The player's side margin (ADR-0093, canvas v30 D6.12): docked beside the
/// content at `breakpointMarginDrawer` and wider — pushing the transcript and
/// the video aside — or a right-edge drawer route below that.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_margin_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Present under the expanded player body; [docked] says whether margin
/// panels go into the layout (true) or a drawer route (false).
class PlayerMarginScope extends InheritedWidget {
  const PlayerMarginScope({
    required this.docked,
    required super.child,
    super.key,
  });

  final bool docked;

  static PlayerMarginScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PlayerMarginScope>();

  @override
  bool updateShouldNotify(PlayerMarginScope oldWidget) =>
      docked != oldWidget.docked;
}

/// Opens [entry] in the docked margin when [context] sits in a docked player
/// body, otherwise as a drawer route.
Future<void> openPlayerMargin(
  BuildContext context,
  PlayerMarginEntry entry,
) async {
  if (PlayerMarginScope.maybeOf(context)?.docked ?? false) {
    ProviderScope.containerOf(
      context,
      listen: false,
    ).read(playerMarginProvider.notifier).show(entry);
    return;
  }
  await Navigator.of(
    context,
    rootNavigator: true,
  ).push(PlayerMarginRoute(entry: entry));
}

/// Lays [child] out beside the docked margin when wide enough, and provides
/// [PlayerMarginScope] either way.
class PlayerMarginLayout extends ConsumerStatefulWidget {
  const PlayerMarginLayout({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<PlayerMarginLayout> createState() => _PlayerMarginLayoutState();
}

class _PlayerMarginLayoutState extends ConsumerState<PlayerMarginLayout> {
  /// The docked state the last frame was built in; the close below runs only
  /// on the wide -> narrow flip, never on every resize rebuild.
  bool? _lastDocked;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    ref.listen(playerControllerProvider.select((s) => s?.mediaId), (
      prev,
      next,
    ) {
      if (prev != next) ref.read(playerMarginProvider.notifier).close();
    });
    ref.listen(echoModeProvider, (prev, next) {
      final current = ref.read(playerMarginProvider);
      if (!next.active && (current?.echoOnly ?? false)) {
        ref.read(playerMarginProvider.notifier).close();
      }
    });
    return LayoutBuilder(
      builder: (context, constraints) {
        final docked = constraints.maxWidth >= t.breakpointMarginDrawer;
        final entry = ref.watch(playerMarginProvider);
        if (_lastDocked != null && _lastDocked != docked && !docked) {
          // Crossing under the breakpoint while a panel is docked: close it
          // after the frame (providers cannot be mutated during build).
          // Idempotent (`close` no-ops when empty) and flip-guarded, so
          // resize rebuilds never re-trigger it. Reopening as a drawer is a
          // user action; shrinking alone does not pop a route.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) ref.read(playerMarginProvider.notifier).close();
          });
        }
        _lastDocked = docked;
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        return PlayerMarginScope(
          docked: docked,
          child: docked
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: widget.child),
                    AnimatedContainer(
                      duration: reduceMotion ? Duration.zero : t.motionMargin,
                      curve: Curves.easeOutCubic,
                      width: entry == null ? 0 : t.marginWidth,
                      child: entry == null
                          ? null
                          : ClipRect(
                              child: OverflowBox(
                                alignment: Alignment.centerLeft,
                                minWidth: t.marginWidth,
                                maxWidth: t.marginWidth,
                                child: _DockedMargin(entry: entry),
                              ),
                            ),
                    ),
                  ],
                )
              : widget.child,
        );
      },
    );
  }
}

class _DockedMargin extends ConsumerWidget {
  const _DockedMargin({required this.entry});

  final PlayerMarginEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: entry.label,
      child: DecoratedBox(
        key: const ValueKey('player-margin-docked'),
        decoration: BoxDecoration(
          color: t.paper,
          border: Border(left: BorderSide(color: t.line)),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: KeyedSubtree(
            key: ValueKey(entry.id),
            child: entry.builder(
              context,
              () => ref.read(playerMarginProvider.notifier).close(),
            ),
          ),
        ),
      ),
    );
  }
}

/// The right-edge margin drawer under `breakpointMarginDrawer`: a
/// `marginWidth` paper panel with a float shadow, sliding in over
/// `motionMargin`. A [PopupRoute], so a video surface parks under it.
class PlayerMarginRoute extends PopupRoute<void> {
  PlayerMarginRoute({required this.entry});

  final PlayerMarginEntry entry;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => entry.label;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 220);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 180);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final t = EnjoyThemeTokens.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: t.marginWidth,
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          label: entry.label,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: t.paper,
              border: Border(left: BorderSide(color: t.line)),
              boxShadow: t.shadowFloat,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: MediaQuery.removePadding(
                context: context,
                removeLeft: true,
                child: entry.builder(
                  context,
                  () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ),
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
    final slide = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
    return SlideTransition(
      position: slide,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }
}

/// The margin's header: an overline on the left, Close (`Esc`) on the right.
class PlayerMarginHeader extends StatelessWidget {
  const PlayerMarginHeader({
    required this.title,
    required this.onClose,
    this.youVoice = false,
    super.key,
  });

  final String title;
  final VoidCallback onClose;

  /// Overline in `youInk` (takes, assessment) instead of `ink3` (lookup).
  final bool youVoice;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final close = MaterialLocalizations.of(context).closeButtonLabel;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 11 * 0.08,
                color: youVoice ? t.youInk : t.ink3,
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('player-margin-close'),
            tooltip: l10n.playerMarginCloseTooltip(close),
            icon: Icon(EnjoyIcons.close, size: 20, color: t.ink2),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
