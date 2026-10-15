library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';

import 'package:enjoy_player/features/lookup/presentation/widgets/latched_retry_state.dart';
import 'package:enjoy_player/core/presentation/loading_icon.dart';

import 'package:enjoy_player/l10n/app_localizations.dart';

/// Header-area refresh control for lookup sheet sections (cache bust + refetch).
///
/// Shows a spinner and ignores taps while [isRefreshing] is true or immediately
/// after a tap until the parent reports loading (responsive feedback).
class LookupRefreshIconButton extends StatefulWidget {
  const LookupRefreshIconButton({
    required this.l10n,
    required this.onPressed,
    this.isRefreshing = false,
    super.key,
  });

  final AppLocalizations l10n;
  final VoidCallback onPressed;

  /// When true (e.g. Riverpod [AsyncValue.isRefreshing]), the control stays busy.
  final bool isRefreshing;

  @override
  State<LookupRefreshIconButton> createState() =>
      _LookupRefreshIconButtonState();
}

class _LookupRefreshIconButtonState extends State<LookupRefreshIconButton>
    with LatchedRetryState<LookupRefreshIconButton> {
  @override
  bool get parentRetryBusy => widget.isRefreshing;

  @override
  bool wasParentRetryBusy(covariant LookupRefreshIconButton oldWidget) =>
      oldWidget.isRefreshing;

  void _handlePressed() => retry(widget.onPressed);

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
      onPressed: busy ? null : _handlePressed,
      icon: busy
          ? LoadingIcon(size: 20, color: scheme.primary)
          : const Icon(EnjoyIcons.refresh, size: 20),
    );
  }
}
