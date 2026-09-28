/// Library: unified local + cloud source shell with editorial chrome.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/routing/library_source.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_segmented_control.dart';
import 'package:enjoy_player/features/cloud/presentation/cloud_library_body.dart';
import 'package:enjoy_player/features/library/presentation/library_actions.dart';
import 'package:enjoy_player/features/library/presentation/widgets/compact_library_search_bar.dart';
import 'package:enjoy_player/features/library/presentation/widgets/library_source_toggle.dart';
import 'package:enjoy_player/features/library/presentation/widgets/local_library_tab_view.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with TickerProviderStateMixin {
  late final TabController _localKindController;
  late final TabController _cloudKindController;
  final _cloudBodyKey = GlobalKey<CloudLibraryBodyState>();

  @override
  void initState() {
    super.initState();
    _localKindController = TabController(length: 2, vsync: this);
    _cloudKindController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _localKindController.dispose();
    _cloudKindController.dispose();
    super.dispose();
  }

  TabController _kindControllerFor(LibrarySource source) {
    return source == LibrarySource.local
        ? _localKindController
        : _cloudKindController;
  }

  void _setKindIndex(int index) {
    if (_localKindController.index != index) {
      _localKindController.animateTo(index);
    }
    if (_cloudKindController.index != index) {
      _cloudKindController.animateTo(index);
    }
  }

  void _setSource(BuildContext context, LibrarySource next) {
    final current = librarySourceFromUri(GoRouterState.of(context).uri);
    if (current == next) return;
    context.go(libraryRouteForSource(next));
  }

  void _toggleSource(BuildContext context, LibrarySource current) {
    _setSource(
      context,
      current == LibrarySource.local
          ? LibrarySource.cloud
          : LibrarySource.local,
    );
  }

  Widget _kindSegment(AppLocalizations l10n, LibrarySource source) {
    final controller = _kindControllerFor(source);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Align(
          alignment: Alignment.centerLeft,
          child: EnjoySegmentedControl<int>(
            value: controller.index,
            segments: [
              EnjoySegment(
                value: 0,
                icon: EnjoyIcons.video,
                label: l10n.libraryTabVideo,
              ),
              EnjoySegment(
                value: 1,
                icon: EnjoyIcons.waveform,
                label: l10n.libraryTabAudio,
              ),
            ],
            onChanged: (i) {
              if (controller.index != i) _setKindIndex(i);
            },
          ),
        );
      },
    );
  }

  Widget _sourceBody({
    required LibrarySource source,
    required bool reduceMotion,
  }) {
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);

    final child = switch (source) {
      LibrarySource.local => LocalLibraryTabView(
        key: const ValueKey('library-local-body'),
        tabController: _localKindController,
      ),
      LibrarySource.cloud => CloudLibraryBody(
        key: _cloudBodyKey,
        tabController: _cloudKindController,
      ),
    };

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final source = librarySourceFromUri(GoRouterState.of(context).uri);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isCloud = source == LibrarySource.cloud;

    return EnjoyPage(
      kind: EnjoyPageKind.browse,
      body: (context, metrics) {
        final showCompactSearch =
            !isCloud && metrics.paneWidth < t.breakpointRail;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EditorialHeader(
              title: l10n.libraryTitle,
              titleAccessory: LibrarySourceToggle(
                source: source,
                onToggle: () => _toggleSource(context, source),
              ),
              trailing: isCloud
                  ? EnjoyIconButton(
                      icon: EnjoyIcons.refresh,
                      tooltip: l10n.cloudRefreshTooltip,
                      onPressed: () =>
                          _cloudBodyKey.currentState?.refreshActiveTab(),
                    )
                  : metrics.paneWidth < t.breakpointCompact
                  ? EnjoyIconButton(
                      icon: EnjoyIcons.add,
                      tooltip: l10n.actionImport,
                      variant: EnjoyButtonVariant.primary,
                      onPressed: () => showImportChooser(context, ref),
                    )
                  : EnjoyButton.primary(
                      size: EnjoyButtonSize.small,
                      icon: EnjoyIcons.add,
                      onPressed: () => showImportChooser(context, ref),
                      child: Text(l10n.actionImport),
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                metrics.gutter,
                0,
                metrics.gutter,
                t.space12,
              ),
              child: _kindSegment(l10n, source),
            ),
            if (showCompactSearch) const CompactLibrarySearchBar(),
            Expanded(
              child: _sourceBody(source: source, reduceMotion: reduceMotion),
            ),
          ],
        );
      },
    );
  }
}
