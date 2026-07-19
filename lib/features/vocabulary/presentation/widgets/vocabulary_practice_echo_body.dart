/// Echo recorder body for the vocabulary practice sheet.
///
/// Recorder-only: no [PlayerController], WebView, or global echo activation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/shadow_reading_panel.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';

@visibleForTesting
ShadowReadingPanel buildVocabularyEchoRecorder({
  required VocabularyContext contextItem,
  required String language,
}) {
  final locator = contextItem.locator!;
  final targetType = switch (contextItem.sourceType) {
    VocabularySourceType.audio => 'Audio',
    VocabularySourceType.video => 'Video',
    VocabularySourceType.ebook => 'Video',
  };
  return ShadowReadingPanel(
    mediaId: contextItem.sourceId,
    targetType: targetType,
    language: language,
    startSec: locator.start / 1000.0,
    endSec: (locator.start + locator.duration) / 1000.0,
    referenceText: contextItem.text,
    // Enables recorder/assessment actions; global player EchoMode remains off.
    echoActive: true,
  );
}

class VocabularyPracticeEchoBody extends ConsumerWidget {
  const VocabularyPracticeEchoBody({
    super.key,
    required this.contextItem,
    required this.language,
  });

  final VocabularyContext contextItem;
  final String language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final locator = contextItem.locator;
    if (locator == null) return const SizedBox.shrink();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.55,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(bottom: t.space8),
          child: buildVocabularyEchoRecorder(
            contextItem: contextItem,
            language: language,
          ),
        ),
      ),
    );
  }
}
