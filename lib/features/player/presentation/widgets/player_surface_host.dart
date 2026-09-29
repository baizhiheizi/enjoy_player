/// Permanent shell host for the active engine video / WebView surface.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/player/player_surface_overlay_coordinator.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:enjoy_player/features/player/application/player_engine_rev.dart';
import 'package:enjoy_player/features/player/application/player_surface_registry.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_stage_resolver.dart';

/// Owns the single video stage for the current engine.
///
/// Follows [playerSurfaceRegistryProvider] when a target is attached; otherwise
/// parks YouTube off-screen so WebView2 is not torn down. Never reparents the
/// underlying [InAppWebView] / media_kit [Video] between routes.
///
/// Parks itself for transient overlays (dialog / sheet / snackbar — ADR-0066)
/// by watching the overlay coordinator here, in the only widget that cares.
/// Watching it from the shell used to rebuild RootShell — nav, sidebar and both
/// scaffolds — on every token change (issue #663).
///
/// Set [forcePark] only when a shell route that owns its own platform view
/// (e.g. `/youtube/login`) is on top of a still-mounted player page; otherwise
/// this host stays above the shell [Stack] and covers that UI.
class PlayerSurfaceHost extends ConsumerWidget {
  const PlayerSurfaceHost({
    super.key,
    this.forcePark = false,
    this.stageBuilder = buildPlayerVideoStage,
  });

  /// When true, ignore any registry attachment and park off-screen.
  final bool forcePark;

  /// Engine → stage mapping. Defaults to the production resolver; tests inject
  /// a stub so the geometry / keying contract below stays observable without a
  /// native surface.
  final PlayerStageBuilder stageBuilder;

  /// Fallback park size when no target has ever reported geometry.
  ///
  /// YouTube treats a <360 px player as its mobile breakpoint and flushes ABR
  /// at it, so a shrink to these dimensions is the play-then-pause stimulus —
  /// they are only the last-resort park, never the steady-state one.
  static const double _parkWidth = 320;
  static const double _parkHeight = 180;

  /// Extra horizontal clearance (in addition to the full surface width) when
  /// translating a parked surface off-screen, so an anti-aliased edge or
  /// drop shadow cannot bleed back into the viewport.
  static const double _parkClearancePx = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(playerEngineRevProvider);
    final parkForOverlay = ref.watch(playerSurfaceShouldParkForOverlayProvider);
    final registry = ref.watch(playerSurfaceRegistryProvider);
    final attachment = (forcePark || parkForOverlay) ? null : registry;

    final engine = ref
        .read(playerControllerProvider.notifier)
        .engineIdentity
        .resolveOrNull();
    if (engine == null) {
      return const SizedBox.shrink();
    }

    return _EngineSurface(
      key: ObjectKey(engine),
      engine: engine,
      stageBuilder: stageBuilder,
      attachment: attachment,
      overlayParkSize: registry?.size,
      parkWidth: _parkWidth,
      parkHeight: _parkHeight,
      parkClearancePx: _parkClearancePx,
    );
  }
}

class _EngineSurface extends StatefulWidget {
  const _EngineSurface({
    super.key,
    required this.engine,
    required this.stageBuilder,
    required this.attachment,
    required this.overlayParkSize,
    required this.parkWidth,
    required this.parkHeight,
    required this.parkClearancePx,
  });

  final PlayerEngine engine;
  final PlayerStageBuilder stageBuilder;
  final PlayerSurfaceAttachment? attachment;

  /// Live target size from the registry, even while [PlayerSurfaceHost.forcePark]
  /// hides the surface. Used so YouTube parks at the last on-screen size.
  final Size? overlayParkSize;
  final double parkWidth;
  final double parkHeight;

  /// Extra off-screen clearance — see [PlayerSurfaceHost._parkClearancePx].
  final double parkClearancePx;

  @override
  State<_EngineSurface> createState() => _EngineSurfaceState();
}

class _EngineSurfaceState extends State<_EngineSurface> {
  /// Last on-screen target, held one frame when [widget.attachment] goes null
  /// so a loading → chrome target swap cannot unmount media_kit [Video].
  PlayerSurfaceAttachment? _heldAttachment;

  @override
  void initState() {
    super.initState();
    _heldAttachment = widget.attachment;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant _EngineSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.attachment != null) {
      _heldAttachment = widget.attachment;
      return;
    }
    if (oldWidget.attachment == null || widget.engine.keepSurfaceWhenParked) {
      return;
    }
    _heldAttachment = oldWidget.attachment;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.attachment != null) return;
      setState(() => _heldAttachment = null);
    });
  }

  Offset _toLocal(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return global;
    return box.globalToLocal(global);
  }

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;
    final attachment =
        widget.attachment ??
        (engine.keepSurfaceWhenParked ? null : _heldAttachment);
    if (attachment == null && !engine.keepSurfaceWhenParked) {
      return const SizedBox.shrink();
    }

    final size =
        attachment?.size ??
        widget.overlayParkSize ??
        _heldAttachment?.size ??
        Size(widget.parkWidth, widget.parkHeight);
    final offset = attachment != null
        ? _toLocal(attachment.offset)
        : Offset(-size.width - widget.parkClearancePx, 0);

    Widget stageFor(double w, double h) {
      if (w <= 0 || h <= 0) return const SizedBox.shrink();
      return widget.stageBuilder(engine, maxWidth: w, maxHeight: h);
    }

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: offset.dx,
          top: offset.dy,
          width: size.width,
          height: size.height,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: IgnorePointer(
              ignoring: attachment == null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  stageFor(size.width, size.height),
                  if (attachment?.overlayBuilder != null)
                    attachment!.overlayBuilder!(context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
