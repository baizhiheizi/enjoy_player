import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class CaptureTextFallback extends StatelessWidget {
  const CaptureTextFallback({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.l10n,
    required this.onSubmit,
    required this.onBack,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final AppLocalizations l10n;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: EnjoyButton.ghost(
            onPressed: onBack,
            icon: EnjoyIcons.mic,
            child: Text(l10n.craftCaptureTitle),
          ),
        ),
        SizedBox(height: t.space16),
        TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          maxLines: 5,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          decoration: InputDecoration(
            hintText: l10n.craftTextInputHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(t.radiusLg),
            ),
          ),
        ),
        SizedBox(height: t.space16),
        EnjoyButton.brand(
          onPressed: onSubmit,
          icon: EnjoyIcons.arrowRight,
          expand: true,
          child: Text(l10n.craftRewriteGenerateAudio),
        ),
      ],
    );
  }
}
