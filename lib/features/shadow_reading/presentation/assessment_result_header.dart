/// Shared header for the pronunciation-assessment result surfaces.
library;

import 'package:material_ui/material_ui.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Title, description and close affordance shared by the wide
/// [AssessmentResultDialog] and the narrow [AssessmentResultSheet].
///
/// Both adaptive surfaces mount this widget so the header strings, styles and
/// spacing have one owner (ADR-0093). [padding] stays per surface because the
/// sheet reserves room above the header for its drag handle.
class AssessmentResultHeader extends StatelessWidget {
  const AssessmentResultHeader({required this.padding, super.key});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final t = EnjoyThemeTokens.of(context);

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.assessmentTitle, style: tt.titleLarge),
                SizedBox(height: t.space4),
                Text(
                  l10n.assessmentDescription,
                  style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonLabel,
            style: IconButton.styleFrom(
              minimumSize: const Size.square(48),
              fixedSize: const Size.square(48),
            ),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(EnjoyIcons.close),
          ),
        ],
      ),
    );
  }
}
