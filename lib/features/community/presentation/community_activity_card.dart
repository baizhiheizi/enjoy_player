/// Community activity / active learners (signed-in home dashboard).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/features/community/application/active_users_provider.dart';
import 'package:enjoy_player/features/community/domain/active_user.dart';
import 'package:enjoy_player/features/community/presentation/community_activity_avatars.dart';
import 'package:enjoy_player/features/community/presentation/community_activity_bodies.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Presentation mode for [CommunityActivityCard].
enum CommunityActivityCardVariant {
  /// Full stats + avatars (tablet / desktop).
  card,

  /// Compact headline + few avatars (mobile insight strip).
  summary,
}

class CommunityActivityCard extends ConsumerWidget {
  const CommunityActivityCard({
    super.key,
    this.outerPadding,
    this.variant = CommunityActivityCardVariant.card,
    this.containedInParentCard = false,
  });

  /// When null, applies default bottom spacing. Use [EdgeInsets.zero] when embedded in a grid.
  final EdgeInsetsGeometry? outerPadding;

  final CommunityActivityCardVariant variant;

  /// When true, omits the outer [Card] (parent supplies chrome, e.g. mobile insight strip).
  final bool containedInParentCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeUsersProvider);
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final outer = containedInParentCard
        ? EdgeInsets.zero
        : (outerPadding ?? EdgeInsets.only(bottom: t.space24));

    return async.when(
      skipLoadingOnReload: true,
      data: (data) {
        if (data == null) return const SizedBox.shrink();

        final inner = variant == CommunityActivityCardVariant.summary
            ? SummaryBody(data: data, t: t, cs: cs)
            : CardBody(data: data, t: t, cs: cs);

        return _wrapChrome(
          outer: outer,
          containedInParentCard: containedInParentCard,
          t: t,
          variant: variant,
          semanticsLabel: _semanticsLabel(context, data),
          child: inner,
        );
      },
      loading: () => _wrapChrome(
        outer: outer,
        containedInParentCard: containedInParentCard,
        t: t,
        variant: variant,
        semanticsLabel: AppLocalizations.of(context)!.communityActivity,
        child: _LoadingInner(t: t, cs: cs, variant: variant),
      ),
      error: (e, _) => _wrapChrome(
        outer: outer,
        containedInParentCard: containedInParentCard,
        t: t,
        variant: variant,
        semanticsLabel: AppLocalizations.of(context)!.communityActivity,
        child: _ErrorInner(
          t: t,
          cs: cs,
          variant: variant,
          onRetry: () => ref.invalidate(activeUsersProvider),
        ),
      ),
    );
  }

  String _semanticsLabel(BuildContext context, ActiveUsersResponse data) {
    final l10n = AppLocalizations.of(context)!;
    final hasToday =
        data.recordingsCountToday != null ||
        data.recordingsDurationToday != null;
    if (hasToday) {
      final parts = <String>[l10n.communityActivity];
      if (data.recordingsCountToday != null) {
        parts.add('${data.recordingsCountToday} ${l10n.homeRecordingsToday}');
      }
      if (data.recordingsDurationToday != null) {
        parts.add(
          '${formatPracticeDurationMs(data.recordingsDurationToday!)} ${l10n.homePracticeTime}',
        );
      }
      return parts.join(', ');
    }
    return '${l10n.communityActivity}, ${data.count}';
  }
}

Widget _wrapChrome({
  required EdgeInsetsGeometry outer,
  required bool containedInParentCard,
  required EnjoyThemeTokens t,
  required CommunityActivityCardVariant variant,
  required String semanticsLabel,
  required Widget child,
}) {
  final pad = EdgeInsets.all(t.space16);
  final body = Semantics(
    label: semanticsLabel,
    child: Padding(padding: pad, child: child),
  );

  if (containedInParentCard) {
    return Padding(padding: outer, child: body);
  }
  return Padding(
    padding: outer,
    child: Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: body,
    ),
  );
}

class _LoadingInner extends StatelessWidget {
  const _LoadingInner({
    required this.t,
    required this.cs,
    required this.variant,
  });

  final EnjoyThemeTokens t;
  final ColorScheme cs;
  final CommunityActivityCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final base = cs.surfaceContainerHighest.withValues(alpha: 0.6);
    if (variant == CommunityActivityCardVariant.summary) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.group_outlined, size: 16, color: cs.primary),
              SizedBox(width: t.space4),
              Expanded(
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              SizedBox(
                width:
                    kSummaryAvatarSize +
                    2 * (kSummaryAvatarSize - kSummaryAvatarOverlap),
                height: kSummaryAvatarSize,
                child: Stack(
                  children: List.generate(
                    3,
                    (i) => Positioned(
                      left: i * (kSummaryAvatarSize - kSummaryAvatarOverlap),
                      child: Container(
                        width: kSummaryAvatarSize,
                        height: kSummaryAvatarSize,
                        decoration: BoxDecoration(
                          color: base,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.surface, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: t.space8),
          Row(
            children: [
              Container(
                height: 14,
                width: 72,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(width: t.space8),
              Container(
                height: 14,
                width: 88,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          SizedBox(height: t.space4),
          Container(
            height: 12,
            width: 96,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 3,
          width: double.infinity,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        SizedBox(height: t.space12),
        Container(
          height: 22,
          width: 120,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(height: t.space8),
        Container(
          height: 18,
          width: 160,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(height: t.space12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(
            6,
            (_) => Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: base, shape: BoxShape.circle),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorInner extends StatelessWidget {
  const _ErrorInner({
    required this.t,
    required this.cs,
    required this.variant,
    required this.onRetry,
  });

  final EnjoyThemeTokens t;
  final ColorScheme cs;
  final CommunityActivityCardVariant variant;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (variant == CommunityActivityCardVariant.summary) {
      return Row(
        children: [
          Icon(Icons.error_outline, color: cs.error, size: 20),
          SizedBox(width: t.space8),
          Expanded(
            child: Text(
              l10n.errorNetwork,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: t.space8),
              minimumSize: const Size(48, 40),
            ),
            child: Text(l10n.retry),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(Icons.error_outline, color: cs.error, size: 22),
        SizedBox(width: t.space12),
        Expanded(
          child: Text(
            l10n.errorNetwork,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        TextButton(onPressed: onRetry, child: Text(l10n.retry)),
      ],
    );
  }
}
