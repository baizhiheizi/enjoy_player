/// Community activity / active learners card (signed-in only).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/community/application/active_users_provider.dart';
import 'package:enjoy_player/features/community/domain/active_user.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const int _kMaxAvatars = 12;

String _formatDurationMs(int ms) {
  final seconds = ms ~/ 1000;
  final minutes = seconds ~/ 60;
  final hours = minutes ~/ 60;
  if (hours > 0) {
    return '${hours}h ${minutes % 60}m';
  }
  if (minutes > 0) {
    return '${minutes}m ${seconds % 60}s';
  }
  return '${seconds}s';
}

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
  const CommunityActivityCard({super.key, this.outerPadding});

  /// When null, applies default bottom spacing. Use [EdgeInsets.zero] when embedded in a grid.
  final EdgeInsetsGeometry? outerPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeUsersProvider);
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final outer = outerPadding ?? EdgeInsets.only(bottom: t.space24);

    return async.when(
      skipLoadingOnReload: true,
      data: (data) {
        if (data == null) return const SizedBox.shrink();

        final hasTodayStats =
            data.recordingsCountToday != null ||
            data.recordingsDurationToday != null;

        return Padding(
          padding: outer,
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: EdgeInsets.all(t.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.group_outlined, size: 20, color: cs.primary),
                      SizedBox(width: t.space8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.communityActivity,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: t.space16),
                  if (hasTodayStats)
                    _TodayStatsBody(data: data, denseAvatars: true)
                  else
                    _SimpleCountBody(data: data, denseAvatars: false),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => _LoadingCard(t: t, cs: cs, outerPadding: outer),
      error: (e, _) => _ErrorCard(
        t: t,
        cs: cs,
        outerPadding: outer,
        onRetry: () => ref.invalidate(activeUsersProvider),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({
    required this.t,
    required this.cs,
    required this.outerPadding,
  });

  final EnjoyThemeTokens t;
  final ColorScheme cs;
  final EdgeInsetsGeometry outerPadding;

  @override
  Widget build(BuildContext context) {
    final base = cs.surfaceContainerHighest.withValues(alpha: 0.6);
    return Padding(
      padding: outerPadding,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(t.space16),
          child: Column(
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
              SizedBox(height: t.space16),
              Container(
                height: 24,
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
              SizedBox(height: t.space16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(
                  8,
                  (_) => Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: base,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.t,
    required this.cs,
    required this.outerPadding,
    required this.onRetry,
  });

  final EnjoyThemeTokens t;
  final ColorScheme cs;
  final EdgeInsetsGeometry outerPadding;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: outerPadding,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(t.space16),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: cs.error, size: 22),
              SizedBox(width: t.space12),
              Expanded(
                child: Text(
                  l10n.errorNetwork,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: onRetry,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayStatsBody extends StatelessWidget {
  const _TodayStatsBody({required this.data, required this.denseAvatars});

  final ActiveUsersResponse data;
  final bool denseAvatars;

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
            Text(
              l10n.communityToday.toUpperCase(),
              style: small,
            ),
          ],
        ),
        SizedBox(height: t.space12),
        Row(
          children: [
            if (data.recordingsCountToday != null) ...[
              Expanded(
                child: _StatBlock(
                  icon: Icons.mic,
                  valueText: '${data.recordingsCountToday}',
                  label: l10n.homeRecordingsToday,
                ),
              ),
            ],
            if (data.recordingsDurationToday != null) ...[
              if (data.recordingsCountToday != null) SizedBox(width: t.space12),
              Expanded(
                child: _StatBlock(
                  icon: Icons.schedule,
                  valueText: _formatDurationMs(data.recordingsDurationToday!),
                  label: l10n.homePracticeTime,
                ),
              ),
            ],
          ],
        ),
        if (data.users.isNotEmpty) ...[
          SizedBox(height: t.space16),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.35)),
          SizedBox(height: t.space12),
          _ActiveLearnersRow(data: data, dense: denseAvatars),
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
  });

  final IconData icon;
  final String valueText;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: cs.primary),
            SizedBox(width: t.space8),
            Text(
              valueText,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: t.space4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SimpleCountBody extends StatelessWidget {
  const _SimpleCountBody({required this.data, required this.denseAvatars});

  final ActiveUsersResponse data;
  final bool denseAvatars;

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
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: t.space8),
          Text(
            l10n.homeNoActiveUsers,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${data.count}',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: t.space4),
        Text(
          l10n.homePeopleLearning(data.count),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        SizedBox(height: t.space16),
        _AvatarWrap(
          users: data.users,
          totalCount: data.count,
          dense: denseAvatars,
        ),
      ],
    );
  }
}

class _ActiveLearnersRow extends StatelessWidget {
  const _ActiveLearnersRow({required this.data, required this.dense});

  final ActiveUsersResponse data;
  final bool dense;

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
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        SizedBox(height: t.space8),
        _AvatarWrap(
          users: data.users,
          totalCount: data.count,
          dense: dense,
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
  });

  final List<ActiveUser> users;
  final int totalCount;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = dense ? 32.0 : 40.0;
    final fontSize = dense ? 10.0 : 12.0;
    final shown = users.take(_kMaxAvatars).toList();
    final extra =
        totalCount > _kMaxAvatars ? totalCount - _kMaxAvatars : 0;

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
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
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
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback(),
      ),
    );
  }
}
