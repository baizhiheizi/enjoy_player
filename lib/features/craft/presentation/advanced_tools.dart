/// Advanced mode: stacked Translate + Synthesize panels (hub layout).
///
/// Matches AI providers / settings section rhythm — one full-width
/// [EnjoyCard] panel after another, not a cramped dual column.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/craft/presentation/synthesize_tool.dart';
import 'package:enjoy_player/features/craft/presentation/translate_tool.dart';

/// Container widget for Advanced mode (Translate + Synthesize tools).
class AdvancedTools extends ConsumerWidget {
  const AdvancedTools({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TranslateTool(),
        SizedBox(height: t.space16),
        const SynthesizeTool(),
      ],
    );
  }
}
