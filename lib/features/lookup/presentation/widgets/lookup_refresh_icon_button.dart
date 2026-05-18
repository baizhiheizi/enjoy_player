library;

import 'package:flutter/material.dart';

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

class _LookupRefreshIconButtonState extends State<LookupRefreshIconButton> {
  /// True until [widget.isRefreshing] observes the in-flight refresh.
  bool _tapLatched = false;

  @override
  void didUpdateWidget(covariant LookupRefreshIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRefreshing) {
      if (_tapLatched) setState(() => _tapLatched = false);
    } else if (oldWidget.isRefreshing && !widget.isRefreshing) {
      if (_tapLatched) setState(() => _tapLatched = false);
    }
  }

  void _handlePressed() {
    setState(() => _tapLatched = true);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.isRefreshing || _tapLatched;
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
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary,
              ),
            )
          : const Icon(Icons.refresh_rounded, size: 20),
    );
  }
}
