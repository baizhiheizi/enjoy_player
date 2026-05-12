/// Editorial empty-state primitive.
///
/// Shows an optional SVG illustration (or monochrome icon), title, subtitle,
/// and an optional primary action — centered with generous padding.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';

import '../enjoy_tokens.dart';

/// Bundled illustration asset paths for [EmptyState.illustrationAsset].
abstract final class EnjoyIllustrations {
  static const emptyLibrary = 'assets/illustrations/empty_library.svg';
  static const emptyCloud = 'assets/illustrations/empty_cloud.svg';
  static const emptyTranscript = 'assets/illustrations/empty_transcript.svg';
  static const emptyRecordings = 'assets/illustrations/empty_recordings.svg';
  static const offline = 'assets/illustrations/offline.svg';
  static const errorGeneric = 'assets/illustrations/error_generic.svg';
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.actionLabel,
    this.illustration,
    this.illustrationAsset,
  });

  /// Used when [illustration] and [illustrationAsset] are null.
  final IconData icon;

  final String title;
  final String subtitle;
  final VoidCallback? action;
  final String? actionLabel;

  /// When non-null, replaces [icon] / asset art.
  final Widget? illustration;

  /// When non-null (and [illustration] is null), shows branded SVG.
  final String? illustrationAsset;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final Widget art;
    if (illustration != null) {
      art = illustration!;
    } else if (illustrationAsset != null && illustrationAsset!.isNotEmpty) {
      art = SvgPicture.asset(
        illustrationAsset!,
        height: 112,
        fit: BoxFit.contain,
      );
    } else {
      art = Icon(
        icon,
        size: 56,
        color: cs.onSurfaceVariant.withValues(alpha: 0.55),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: t.contentMaxWidth),
        child: Padding(
          padding: EdgeInsets.all(t.space40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              art,
              SizedBox(height: t.space24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: t.space8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              if (action != null && actionLabel != null) ...[
                SizedBox(height: t.space24),
                EnjoyButton.primary(
                  onPressed: action,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
