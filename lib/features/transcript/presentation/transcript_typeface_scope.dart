/// Applies the Book / Clean transcript typeface preference to [child].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/features/settings/application/transcript_typeface_settings.dart';

class TranscriptTypefaceScope extends ConsumerWidget {
  const TranscriptTypefaceScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeface =
        ref.watch(transcriptTypefaceSettingsProvider).valueOrNull ??
        TranscriptTypeface.book;
    if (typeface == TranscriptTypeface.book) return child;
    final theme = Theme.of(context);
    final clean = TranscriptTypographyTokens.of(context).clean();
    return Theme(
      data: theme.copyWith(
        extensions: [
          ...theme.extensions.values.where(
            (e) => e is! TranscriptTypographyTokens,
          ),
          clean,
        ],
      ),
      child: child,
    );
  }
}
