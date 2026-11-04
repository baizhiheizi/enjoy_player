library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/latched_retry_state.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_retry_button.dart';

class LookupCreditsNotice extends ParentRetryWidget {
  const LookupCreditsNotice({
    required this.message,
    required super.onRetry,
    super.isRetrying,
    super.key,
  });

  final String message;

  @override
  State<LookupCreditsNotice> createState() => _LookupCreditsNoticeState();
}

class _LookupCreditsNoticeState extends State<LookupCreditsNotice>
    with LatchedRetryState<LookupCreditsNotice> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final t = EnjoyThemeTokens.of(context);

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
        LookupRetryButton(busy: retryBusy, onPressed: retry),
      ],
    );
  }
}
