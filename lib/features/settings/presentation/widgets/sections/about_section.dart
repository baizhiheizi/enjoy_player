/// Thin wrapper around [AboutSectionCard] for registry/layout consistency.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/features/settings/presentation/widgets/about_section_card.dart';

class AboutSectionBody extends StatelessWidget {
  const AboutSectionBody({super.key});

  @override
  Widget build(BuildContext context) => const AboutSectionCard();
}
