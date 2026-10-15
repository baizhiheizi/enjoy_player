library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/latched_retry_state.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class LookupCreditsNotice extends StatefulWidget {
  const LookupCreditsNotice({
    required this.message,
    required this.onRetry,
    this.isRetrying = false,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;
  final bool isRetrying;

  @override
  State<LookupCreditsNotice> createState() => _LookupCreditsNoticeState();
}

class _LookupCreditsNoticeState extends State<LookupCreditsNotice>
    with LatchedRetryState<LookupCreditsNotice> {
  @override
  bool get parentRetryBusy => widget.isRetrying;

  @override
  bool wasParentRetryBusy(covariant LookupCreditsNotice oldWidget) =>
      oldWidget.isRetrying;

  void _handleRetry() => retry(widget.onRetry);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final t = EnjoyThemeTokens.of(context);
    final busy = retryBusy;

    return Row(
      children: [
        Icon(EnjoyIcons.wallet, size: 16, color: scheme.onSurfaceVariant),
        SizedBox(width: t.space8),
        Expanded(
          child: Text(
            widget.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tt.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ),
        SizedBox(width: t.space4),
        TextButton.icon(
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.symmetric(horizontal: t.space8),
            minimumSize: const Size(0, 36),
          ),
          onPressed: busy ? null : _handleRetry,
          icon: busy
              ? LoadingIcon(size: 14, color: scheme.primary)
              : const Icon(EnjoyIcons.refresh, size: 16),
          label: Text(l10n.lookupErrorRetry),
        ),
      ],
    );
  }
}
