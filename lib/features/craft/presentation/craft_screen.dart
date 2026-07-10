/// Craft screen: full-screen route with Translate + Synthesize tools.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/craft/presentation/synthesize_tool.dart';
import 'package:enjoy_player/features/craft/presentation/translate_tool.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Full-screen Craft route reached from the import chooser.
class CraftScreen extends ConsumerWidget {
  const CraftScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.craftScreenTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).canPop()
              ? Navigator.of(context).pop()
              : Navigator.of(context).pushNamed('/'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: isWide
              ? const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: TranslateTool()),
                    SizedBox(width: 16),
                    Expanded(child: SynthesizeTool()),
                  ],
                )
              : const Column(
                  children: [
                    TranslateTool(),
                    SizedBox(height: 16),
                    SynthesizeTool(),
                  ],
                ),
        ),
      ),
    );
  }
}
