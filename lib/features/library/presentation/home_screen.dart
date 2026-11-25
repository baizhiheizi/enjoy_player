/// Home (the `Home` board): editorial header, the Continue practicing hero
/// beside Today's goal and Community, then the Recent media grid.
library;

import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/format/cached_date_format.dart';
import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/presentation/relative_day_label.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/error_state.dart';
import 'package:enjoy_player/core/utils/sliver_key_index.dart';
import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/core/theme/widgets/media_card.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/community/presentation/community_activity_card.dart';
import 'package:enjoy_player/features/library/application/continue_practice_provider.dart';
import 'package:enjoy_player/features/library/presentation/continue_practice_card.dart';
import 'package:enjoy_player/features/library/presentation/todays_goal_card.dart';
import 'package:enjoy_player/features/onboarding/application/onboarding_controller.dart';
import 'package:enjoy_player/features/onboarding/application/practice_tip_trigger.dart';
import 'package:enjoy_player/features/onboarding/domain/onboarding_tip_id.dart';
import 'package:enjoy_player/features/onboarding/presentation/onboarding_target.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../application/library_media_provider.dart';
import '../domain/media.dart';
import 'library_actions.dart';
import 'widgets/library_media_card.dart';

part 'home_screen_header.dart';
part 'home_screen_loading.dart';
part 'home_screen_overview.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(practiceTipTriggerProvider)
          .startHomeEntries(routePath: GoRouterState.of(context).uri.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaAsync = ref.watch(libraryHomeRecentsProvider);
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    return EnjoyPage(
      kind: EnjoyPageKind.browse,
      body: (context, metrics) {
        final inset = metrics.horizontalInset;
        return mediaAsync.when(
          data: (recent) {
            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _HomeHeader()),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(inset, t.space12, inset, 0),
                  sliver: SliverToBoxAdapter(
                    child: _HomeOverview(
                      hasRecents: recent.isNotEmpty,
                      width: metrics.paneWidth - metrics.horizontalInset * 2,
                    ),
                  ),
                ),
                if (recent.isNotEmpty) ...[
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(inset, 44, inset, 18),
                    sliver: const SliverToBoxAdapter(
                      child: _RecentMediaHeading(),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: inset),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        return SliverGrid(
                          gridDelegate:
                              mediaCardTileGridDelegateForMinTileWidth(
                                crossAxisExtent: constraints.crossAxisExtent,
                                minTileWidth: _kRecentTileMinWidth,
                                mainAxisSpacing: 24,
                                crossAxisSpacing: 20,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final m = recent[index];
                              return Align(
                                key: ValueKey<String>('home-media-${m.id}'),
                                alignment: Alignment.topCenter,
                                child: _HomeMediaTile(media: m),
                              );
                            },
                            childCount: recent.length,
                            findChildIndexCallback: (key) =>
                                findSliverIndexByPrefixedId(
                                  items: recent,
                                  key: key,
                                  prefix: 'home-media-',
                                  idOf: (m) => m.id,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 72)),
              ],
            );
          },
          loading: () => _HomeLoadingScrollView(metrics: metrics),
          error: (e, _) => ErrorState(
            message: '${l10n.error}: $e',
            onRetry: () => ref.invalidate(libraryHomeRecentsProvider),
          ),
        );
      },
    );
  }
}

const double _kRecentTileMinWidth = 210;

class _RecentMediaHeading extends StatelessWidget {
  const _RecentMediaHeading();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            l10n.homeRecentMedia,
            style: enjoyDisplayStyle(context, size: 24, color: t.ink),
          ),
        ),
        EnjoyPressable(
          onTap: () => context.go('/library'),
          showHoverWash: false,
          child: Text(
            l10n.homeOpenLibrary,
            style: tt.labelLarge?.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: t.brandInk,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeMediaTile extends StatelessWidget {
  const _HomeMediaTile({required this.media});

  final Media media;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isVideo = media.kind == MediaKind.video;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final kind = isVideo
        ? l10n.miniPlayerMediaVideo
        : l10n.miniPlayerMediaAudio;

    return LibraryMediaTile(
      media: media,
      subtitle: '$kind · ${relativeDayLabel(l10n, locale, media.updatedAt)}',
      isVideo: isVideo,
      heroArtworkMediaId: media.id,
    );
  }
}
