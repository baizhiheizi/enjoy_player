/// Community activity / active learners (signed-in home dashboard).
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/features/community/application/active_users_provider.dart';
import 'package:enjoy_player/features/community/domain/active_user.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Presentation mode for [CommunityActivityCard].
enum CommunityActivityCardVariant {
  /// Full stats + avatars (tablet / desktop).
  card,

  /// Compact headline + few avatars (mobile insight strip).
  summary,
}

const int _kMaxAvatarsCard = 8;
const int _kMaxAvatarsSummary = 4;
const double _kSummaryAvatarSize = 28;
const double _kSummaryAvatarOverlap = 8;

String _initials(String name) {
  if (name.trim().isEmpty) return 'U';
  final parts = name.trim().split(RegExp(r'\s+'));
  final buf = StringBuffer();
  for (final n in parts) {
    if (n.isEmpty) continue;
    final c = n[0];
    final code = c.codeUnitAt(0);
    final isAlnum =
        (code >= 0x30 && code <= 0x39) ||
        (code >= 0x41 && code <= 0x5a) ||
        (code >= 0x61 && code <= 0x7a);
    if (isAlnum) {
      buf.write(c);
    }
    if (buf.length >= 2) break;
  }
  final s = buf.toString();
  return s.isEmpty ? 'U' : s;
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
            ? _SummaryBody(data: data, t: t, cs: cs)
            : _CardBody(data: data, t: t, cs: cs);

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

class _CardBody extends StatelessWidget {
  const _CardBody({required this.data, required this.t, required this.cs});

  final ActiveUsersResponse data;
  final EnjoyThemeTokens t;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasTodayStats =
        data.recordingsCountToday != null ||
        data.recordingsDurationToday != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.group_outlined, size: 20, color: cs.primary),
            SizedBox(width: t.space8),
            Expanded(
              child: Text(
                l10n.communityActivity,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        SizedBox(height: t.space12),
        if (hasTodayStats)
          _TodayStatsBody(data: data, denseAvatars: true, compactValues: true)
        else
          _SimpleCountBody(
            data: data,
            denseAvatars: false,
            compactHeadline: true,
            maxAvatars: _kMaxAvatarsCard,
          ),
      ],
    );
  }
}

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({required this.data, required this.t, required this.cs});

  final ActiveUsersResponse data;
  final EnjoyThemeTokens t;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasToday =
        data.recordingsCountToday != null ||
        data.recordingsDurationToday != null;
    final subStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant);
    final tabular = const [FontFeature.tabularFigures()];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 16, color: cs.primary),
            SizedBox(width: t.space4),
            Expanded(
              child: Text(
                l10n.communityActivity,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (data.users.isNotEmpty)
              _OverlappingAvatarStack(
                users: data.users,
                totalCount: data.count,
                maxShown: _kMaxAvatarsSummary,
                cs: cs,
              ),
          ],
        ),
        SizedBox(height: t.space8),
        if (hasToday) ...[
          Wrap(
            spacing: t.space8,
            runSpacing: t.space4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (data.recordingsCountToday != null)
                _InlineMetric(
                  icon: Icons.mic,
                  value: '${data.recordingsCountToday}',
                  label: l10n.homeRecordingsToday,
                  cs: cs,
                  tabular: tabular,
                ),
              if (data.recordingsCountToday != null &&
                  data.recordingsDurationToday != null)
                Text('·', style: subStyle),
              if (data.recordingsDurationToday != null)
                _InlineMetric(
                  icon: Icons.schedule,
                  value: formatPracticeDurationMs(data.recordingsDurationToday!),
                  label: l10n.homePracticeTime,
                  cs: cs,
                  tabular: tabular,
                ),
            ],
          ),
          if (data.count > 0) ...[
            SizedBox(height: t.space4),
            Text(
              '${data.count} ${l10n.homeActiveLearners}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: subStyle?.copyWith(fontFeatures: tabular),
            ),
          ],
        ] else if (data.users.isEmpty)
          Text(
            l10n.homeNoActiveUsers,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: subStyle,
          )
        else
          Text(
            l10n.homePeopleLearning(data.count),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: subStyle,
          ),
      ],
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.cs,
    required this.tabular,
  });

  final IconData icon;
  final String value;
  final String label;
  final ColorScheme cs;
  final List<FontFeature> tabular;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.primary),
        SizedBox(width: EnjoyThemeTokens.of(context).space4),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: tabular,
          ),
        ),
        SizedBox(width: EnjoyThemeTokens.of(context).space4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _OverlappingAvatarStack extends StatelessWidget {
  const _OverlappingAvatarStack({
    required this.users,
    required this.totalCount,
    required this.maxShown,
    required this.cs,
  });

  final List<ActiveUser> users;
  final int totalCount;
  final int maxShown;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final shown = users.take(maxShown).toList();
    final extra = totalCount > maxShown ? totalCount - maxShown : 0;
    final slots = shown.length + (extra > 0 ? 1 : 0);
    if (slots == 0) return const SizedBox.shrink();

    final step = _kSummaryAvatarSize - _kSummaryAvatarOverlap;
    final width = _kSummaryAvatarSize + (slots - 1) * step;

    return SizedBox(
      width: width,
      height: _kSummaryAvatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * step,
              child: _AvatarBorder(
                cs: cs,
                child: _UserAvatar(
                  user: shown[i],
                  size: _kSummaryAvatarSize,
                  fontSize: 10,
                ),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * step,
              child: _AvatarBorder(
                cs: cs,
                child: Container(
                  width: _kSummaryAvatarSize,
                  height: _kSummaryAvatarSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '+$extra',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarBorder extends StatelessWidget {
  const _AvatarBorder({required this.cs, required this.child});

  final ColorScheme cs;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: cs.surface, width: 2),
      ),
      child: child,
    );
  }
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
                    _kSummaryAvatarSize +
                    2 * (_kSummaryAvatarSize - _kSummaryAvatarOverlap),
                height: _kSummaryAvatarSize,
                child: Stack(
                  children: List.generate(
                    3,
                    (i) => Positioned(
                      left: i * (_kSummaryAvatarSize - _kSummaryAvatarOverlap),
                      child: Container(
                        width: _kSummaryAvatarSize,
                        height: _kSummaryAvatarSize,
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

class _TodayStatsBody extends StatelessWidget {
  const _TodayStatsBody({
    required this.data,
    required this.denseAvatars,
    this.compactValues = false,
  });

  final ActiveUsersResponse data;
  final bool denseAvatars;
  final bool compactValues;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final small = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 16, color: cs.primary),
            SizedBox(width: t.space8),
            Text(l10n.communityToday.toUpperCase(), style: small),
          ],
        ),
        SizedBox(height: t.space8),
        Row(
          children: [
            if (data.recordingsCountToday != null) ...[
              Expanded(
                child: _StatBlock(
                  icon: Icons.mic,
                  valueText: '${data.recordingsCountToday}',
                  label: l10n.homeRecordingsToday,
                  compactValue: compactValues,
                ),
              ),
            ],
            if (data.recordingsDurationToday != null) ...[
              if (data.recordingsCountToday != null) SizedBox(width: t.space12),
              Expanded(
                child: _StatBlock(
                  icon: Icons.schedule,
                  valueText: formatPracticeDurationMs(data.recordingsDurationToday!),
                  label: l10n.homePracticeTime,
                  compactValue: compactValues,
                ),
              ),
            ],
          ],
        ),
        if (data.users.isNotEmpty) ...[
          SizedBox(height: t.space12),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.35)),
          SizedBox(height: t.space8),
          _ActiveLearnersRow(
            data: data,
            dense: denseAvatars,
            maxAvatars: _kMaxAvatarsCard,
          ),
        ],
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.icon,
    required this.valueText,
    required this.label,
    this.compactValue = false,
  });

  final IconData icon;
  final String valueText;
  final String label;
  final bool compactValue;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final valueStyle = compactValue
        ? Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: cs.primary),
            SizedBox(width: t.space8),
            Expanded(
              child: Text(
                valueText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: valueStyle,
              ),
            ),
          ],
        ),
        SizedBox(height: t.space4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SimpleCountBody extends StatelessWidget {
  const _SimpleCountBody({
    required this.data,
    required this.denseAvatars,
    this.compactHeadline = false,
    this.maxAvatars = _kMaxAvatarsCard,
  });

  final ActiveUsersResponse data;
  final bool denseAvatars;
  final bool compactHeadline;
  final int maxAvatars;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    if (data.users.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '0',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: t.space8),
          Text(
            l10n.homeNoActiveUsers,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      );
    }

    final countStyle = compactHeadline
        ? Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${data.count}', style: countStyle),
        SizedBox(height: t.space4),
        Text(
          l10n.homePeopleLearning(data.count),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        SizedBox(height: t.space12),
        _AvatarWrap(
          users: data.users,
          totalCount: data.count,
          dense: denseAvatars,
          maxShown: maxAvatars,
        ),
      ],
    );
  }
}

class _ActiveLearnersRow extends StatelessWidget {
  const _ActiveLearnersRow({
    required this.data,
    required this.dense,
    this.maxAvatars = _kMaxAvatarsCard,
  });

  final ActiveUsersResponse data;
  final bool dense;
  final int maxAvatars;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.homeActiveLearners,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (data.count > 0)
              Text(
                '${data.count}',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
          ],
        ),
        SizedBox(height: t.space8),
        _AvatarWrap(
          users: data.users,
          totalCount: data.count,
          dense: dense,
          maxShown: maxAvatars,
        ),
      ],
    );
  }
}

class _AvatarWrap extends StatelessWidget {
  const _AvatarWrap({
    required this.users,
    required this.totalCount,
    required this.dense,
    required this.maxShown,
  });

  final List<ActiveUser> users;
  final int totalCount;
  final bool dense;
  final int maxShown;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = dense ? 32.0 : 40.0;
    final fontSize = dense ? 10.0 : 12.0;
    final shown = users.take(maxShown).toList();
    final extra = totalCount > maxShown ? totalCount - maxShown : 0;

    return Wrap(
      spacing: dense ? 6 : 8,
      runSpacing: dense ? 6 : 8,
      children: [
        for (final u in shown)
          _UserAvatar(user: u, size: size, fontSize: fontSize),
        if (extra > 0)
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Text(
              '+$extra',
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.user,
    required this.size,
    required this.fontSize,
  });

  final ActiveUser user;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = _initials(user.name);
    final url = user.avatarUrl;

    Widget fallback() {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Text(
          initials,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: cs.onPrimaryContainer,
          ),
        ),
      );
    }

    if (url == null || url.isEmpty) {
      return fallback();
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => fallback(),
      ),
    );
  }
}
