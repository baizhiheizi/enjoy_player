import 'package:flutter/material.dart';

import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';

/// Trailing Cancel + Save pair for the profile edit / preferences forms.
/// Cancel pops the route; Save shows a spinner while [saving].
class ProfileFormActions extends StatelessWidget {
  const ProfileFormActions({
    required this.saving,
    required this.saveLabel,
    required this.onSave,
    super.key,
  });

  final bool saving;
  final String saveLabel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final navigator = Navigator.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (navigator.canPop()) ...[
          EnjoyButton.secondary(
            onPressed: saving ? null : () => navigator.maybePop(),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          SizedBox(width: t.space8),
        ],
        EnjoyButton.brand(
          onPressed: saving ? null : onSave,
          child: saving ? const LoadingIcon(size: 18) : Text(saveLabel),
        ),
      ],
    );
  }
}
