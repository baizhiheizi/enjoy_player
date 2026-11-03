library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';

import 'package:enjoy_player/features/lookup/presentation/widgets/latched_retry_state.dart';
import 'package:enjoy_player/core/presentation/loading_icon.dart';

import 'package:enjoy_player/l10n/app_localizations.dart';

/// Header-area refresh control for lookup sheet sections (cache bust + refetch).
///
/// Shows a spinner and ignores taps while [isRetrying] is true or immediately
/// after a tap until the parent reports loading (responsive feedback).
class LookupRefreshIconButton extends ParentRetryWidget {
  const LookupRefreshIconButton({
    required this.l10n,
    required super.onRetry,
    super.isRetrying,
    super.key,
  });

  final AppLocalizations l10n;

  @override
  State<LookupRefreshIconButton> createState() =>
      _LookupRefreshIconButtonState();
}

class _LookupRefreshIconButtonState extends State<LookupRefreshIconButton>
    with LatchedRetryState<LookupRefreshIconButton> {
  @override
  Widget build(BuildContext context) {
    final busy = retryBusy;
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      style: IconButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        iconSize: 20,
      ),
      tooltip: busy ? null : widget.l10n.lookupRefresh,
      onPressed: busy ? null : retry,
      icon: busy
          ? LoadingIcon(size: 20, color: scheme.primary)
          : const Icon(EnjoyIcons.refresh, size: 20),
    );
  }
}
